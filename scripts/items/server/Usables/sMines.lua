class 'sMines'

local MINE_ID = 0

function sMines:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS mines (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, position VARCHAR)")

    self.mines = {} -- Active mines, indexed by mine id
    self.mine_cells = {} -- Active mines, organized by cell x, y, then mine id

    self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()

    Network:Subscribe("items/CompleteItemUsage", self, self.CompleteItemUsage)
    Network:Subscribe("items/StepOnMine", self, self.StepOnMine)
    Network:Subscribe("items/DestroyMine", self, self.DestroyMine)
    Network:Subscribe("items/PickupMine", self, self.PickupMine)

    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring( ItemsConfig.usables.Mine.cell_size), self, self.PlayerCellUpdate)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
end

function sMines:DestroyMine(args, player)
    if not args.id or not self.mines[args.id] then return end

    local mine = self.mines[args.id]

    Network:Send(player, "items/MineDestroy", {pos = mine.position})
    Network:SendNearby(player, "items/MineDestroy", {pos = mine.position})

    local cmd = SQL:Command("DELETE FROM mines where id = ?")
    cmd:Bind(1, args.id)
    cmd:Execute()

    -- Remove mine
    local cell = mine:GetCell()
    self.mine_cells[cell.x][cell.y] = nil
    self.mines[args.id] = nil
    mine:Remove(player)

end

function sMines:PickupMine(args, player)
    if not args.id or not self.mines[args.id] then return end

    local mine = self.mines[args.id]

    if mine.owner_id ~= tostring(player:GetSteamId()) then return end -- They do not own this mine

    local num_mines = Inventory.GetNumOfItem({player = player, item_name = "Mine"})

    local item = deepcopy(Items_indexed["Mine"])
    item.amount = 1

    Inventory.AddItem({
        item = item,
        player = player
    })

    -- If the number of mines in their inventory did not go up, they did not have room for it
    if num_mines == Inventory.GetNumOfItem({player = player, item_name = "Mine"}) then
        Chat:Send(player, "Failed to remove mine because you do not have space for it!", Color.Red)
        return
    end

    local cmd = SQL:Command("DELETE FROM mines where id = ?")
    cmd:Bind(1, args.id)
    cmd:Execute()

    -- Remove mine
    local cell = mine:GetCell()
    self.mine_cells[cell.x][cell.y] = nil
    self.mines[args.id] = nil
    mine:Remove(player)

end

function sMines:ClientModuleLoad(args)
    Events:Fire("ForcePlayerUpdateCell", {player = args.player, cell_size = ItemsConfig.usables.Mine.cell_size})
end

function sMines:PlayerCellUpdate(args)
    
    local mine_data = {}

    for _, update_cell in pairs(args.updated) do

        -- If these cells don't exist, create them
        VerifyCellExists(self.mine_cells, update_cell)

        for _, mine in pairs(self.mine_cells[update_cell.x][update_cell.y]) do
            if not mine.exploded then -- Only get active mines
                table.insert(mine_data, mine:GetSyncObject())
            end
        end
    end
    
	-- send the existing mines in the newly streamed cells
    Network:Send(args.player, "items/MinesCellsSync", {mine_data = mine_data})
end

function sMines:StepOnMine(args, player)

    if not args.id then return end
    local id = tonumber(args.id)

    local mine = self.mines[id]
    if not mine then return end

    if mine:Trigger(player) then

        -- Successfully exploded, remove mine
        local cmd = SQL:Command("DELETE FROM mines where id = ?")
        cmd:Bind(1, id)
        cmd:Execute()

        -- Remove mine
        local cell = mine:GetCell()
        self.mine_cells[cell.x][cell.y] = nil
        self.mines[id] = nil

    end

end

function sMines:AddMine(args)

    args.id = tonumber(args.id)

    local mine = sMine({
        id = args.id,
        owner_id = args.owner_id,
        position = args.position
    })
    
    self.mines[args.id] = mine
    local cell = mine:GetCell()

    -- Add to mines in the cell
    VerifyCellExists(self.mine_cells, cell)
    self.mine_cells[cell.x][cell.y][mine.id] = mine

    return mine

end

-- Load all mines from DB
function sMines:LoadAllMines()

    local result = SQL:Query("SELECT * FROM mines"):Execute()
    
    if #result > 0 then

        for _, mine_data in pairs(result) do
            local split = mine_data.position:split(",")
            local pos = Vector3(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))

            self:AddMine({
                id = mine_data.id,
                owner_id = mine_data.steamID,
                position = pos
            })
        end

    end

end

function sMines:PlaceMine(position, player)

    local steamID = tostring(player:GetSteamId())
    local cmd = SQL:Command("INSERT INTO mines (steamID, position) VALUES (?, ?)")
    cmd:Bind(1, steamID)
    cmd:Bind(2, tostring(position))
    cmd:Execute()

	cmd = SQL:Query("SELECT last_insert_rowid() as id FROM mines")
    local result = cmd:Execute()
    
    if not result or not result[1] or not result[1].id then
        error("Failed to place mine")
        return
    end
    
    self:AddMine({
        id = result[1].id,
        owner_id = steamID, -- TODO: add friends to it as well
        position = position
    }):SyncNearby(player)

    Network:Send(player, "items/MinePlaceSound", {position = position})
    Network:SendNearby(player, "items/MinePlaceSound", {position = position})

end

-- args.ray = raycast down
function sMines:TryPlaceMine(args, player)

    -- If they are within sz radius * 2, we don't let them place that close
    if player:GetPosition():Distance(self.sz_config.safezone.position) < self.sz_config.safezone.radius * 2 then
        Chat:Send(player, "Cannot place mines while near the safezone!", Color.Red)
        return
    end

    args.ray.position = Vector3(args.ray.position.x, math.max(args.ray.position.y, player:GetPosition().y), args.ray.position.z)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "Mine" then

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        -- Now actually place the mine
        self:PlaceMine(args.ray.position, player)

    end


end

function sMines:CompleteItemUsage(args, player)

    if player:InVehicle() then
        Chat:Send(player, "Cannot place mines while in a vehicle!", Color.Red)
        return
    end

    if not args.ray or args.ray.distance >= 5 then
        Chat:Send(player, "Placing mine failed!", Color.Red)
        return
    end

    if args.ray.position:Distance(player:GetPosition()) > 5 then
        Chat:Send(player, "Placing mine failed!", Color.Red)
        return
    end

    if args.ray.entity and (args.ray.entity.__type == "Vehicle" or args.ray.entity.__type == "Player") then
        Chat:Send(player, "Placing mine failed!", Color.Red)
        return
    end


    self:TryPlaceMine(args, player)

end

sMines = sMines()
sMines:LoadAllMines()