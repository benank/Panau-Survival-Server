class 'sMines'

function sMines:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS mines (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, position VARCHAR, angle VARCHAR)")

    self.mines = {} -- Active mines, indexed by mine id
    self.mine_cells = {} -- Active mines, organized by cell x, y, then mine id

    Console:Subscribe("clearbadmines", self, self.ClearBadMines)

    Network:Subscribe("items/CompleteItemUsage", self, self.CompleteItemUsage)
    Network:Subscribe("items/StepOnMine", self, self.StepOnMine)
    Network:Subscribe("items/DestroyMine", self, self.DestroyMine)
    Network:Subscribe("items/PickupMine", self, self.PickupMine)

    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(ItemsConfig.usables.Mine.cell_size), self, self.PlayerCellUpdate)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
end

function sMines:ClearBadMines()

    Thread(function()
        print("Clearing bad mines...")
        for id, mine in pairs(self.mines) do

            local waiting = true

            local sub = nil
            sub = Events:Subscribe("IsTooCloseToLootCheck"..tostring(id), function(args)
            
                Events:Unsubscribe(sub)
                sub = nil

                if args.too_close then

                    local cmd = SQL:Command("DELETE FROM mines where id = ?")
                    cmd:Bind(1, id)
                    cmd:Execute()

                    -- Remove mine
                    local cell = mine:GetCell()
                    self.mine_cells[cell.x][cell.y][args.id] = nil
                    self.mines[args.id] = nil
                    mine:Remove()
                    
                end

                waiting = false

            end)

            args = {}

            args.position = mine.position
            args.id = tostring(id)
            Events:Fire("CheckIsTooCloseToLoot", args)

            while waiting do
                Timer.Sleep(10)
            end

        end

        print("All bad mines cleared.")
    end)

end

function sMines:ItemExplode(args)

    local cell = GetCell(args.position, ItemsConfig.usables.Mine.cell_size)
    local adjacent_cells = GetAdjacentCells(cell)

    for _, cell in pairs(adjacent_cells) do

        VerifyCellExists(self.mine_cells, cell)
        for _, mine in pairs(self.mine_cells[cell.x][cell.y]) do
            if mine.position:Distance(args.position) < args.radius + ItemsConfig.usables.Mine.trigger_radius then
                self:DestroyMine({id = mine.id}, args.player)
            end
        end

    end

end

function sMines:DestroyMine(args, player)
    if not args.id or not self.mines[args.id] then return end

    sItemExplodeManager:Add(function()
    
    local mine = self.mines[args.id]

    if not mine or mine.exploded then return end

    if IsValid(player) then
        Network:Send(player, "items/MineDestroy", {position = mine.position, id = mine.id, owner_id = mine.owner_id})
        Network:SendNearby(player, "items/MineDestroy", {position = mine.position, id = mine.id, owner_id = mine.owner_id})
    end

    local cmd = SQL:Command("DELETE FROM mines where id = ?")
    cmd:Bind(1, args.id)
    cmd:Execute()

    -- Remove mine
    local cell = mine:GetCell()
    self.mine_cells[cell.x][cell.y][args.id] = nil
    self.mines[args.id] = nil
    mine:Remove(player)

    local exp_enabled = true

    if mine.place_time and Server:GetElapsedSeconds() - mine.place_time < 60 * 60 then
        exp_enabled = false
    end

    Events:Fire("items/ItemExplode", {
        position = mine.position,
        radius = 10,
        player = player,
        owner_id = mine.owner_id,
        type = DamageEntity.Mine,
        no_detonation_source = args.no_detonation_source,
        exp_enabled = exp_enabled
    })

    end)

end

function sMines:PickupMine(args, player)
    if not args.id or not self.mines[args.id] then return end

    local mine = self.mines[args.id]

    if mine.exploded then return end

    if mine.position:Distance(player:GetPosition()) > 5 then return end

    local num_mines = Inventory.GetNumOfItem({player = player, item_name = "Mine"})

    local item = deepcopy(Items_indexed["Mine"])
    item.amount = 1

    Inventory.AddItem({
        item = item,
        player = player
    })

    -- If the number of mines in their inventory did not go up, they did not have room for it
    if num_mines == Inventory.GetNumOfItem({player = player, item_name = "Mine"}) then
        Chat:Send(player, "Failed to pick up mine because you do not have space for it!", Color.Red)
        return
    end

    local cmd = SQL:Command("DELETE FROM mines where id = ?")
    cmd:Bind(1, args.id)
    cmd:Execute()

    -- Remove mine
    local cell = mine:GetCell()
    self.mine_cells[cell.x][cell.y][args.id] = nil
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

        local cell = mine:GetCell()

        Timer.SetTimeout(1000 * ItemsConfig.usables.Mine.trigger_time, function()
            
            -- IF mine has not been picked up yet
            if self.mine_cells[cell.x][cell.y][id] then

                -- Successfully exploded, remove mine
                local cmd = SQL:Command("DELETE FROM mines where id = ?")
                cmd:Bind(1, id)
                cmd:Execute()

                -- Remove mine
                self.mine_cells[cell.x][cell.y][id] = nil
                self.mines[id] = nil
                
                Events:Fire("items/ItemExplode", {
                    position = mine.position,
                    radius = 10,
                    player = player,
                    owner_id = mine.owner_id,
                    type = DamageEntity.Mine,
                    no_detonation_source = true
                })
            end

        end)

    end

end

function sMines:AddMine(args)

    args.id = tonumber(args.id)

    local mine = sMine({
        id = args.id,
        owner_id = args.owner_id,
        position = args.position,
        angle = args.angle
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

            local angle = self:DeserializeAngle(mine_data.angle)

            self:AddMine({
                id = mine_data.id,
                owner_id = mine_data.steamID,
                position = pos,
                angle = angle
            })
        end

    end

end

function sMines:PlaceMine(position, angle, player)

    local steamID = tostring(player:GetSteamId())
    local cmd = SQL:Command("INSERT INTO mines (steamID, position, angle) VALUES (?, ?, ?)")
    cmd:Bind(1, steamID)
    cmd:Bind(2, tostring(position))
    cmd:Bind(3, self:SerializeAngle(angle))
    cmd:Execute()

	cmd = SQL:Query("SELECT last_insert_rowid() as id FROM mines")
    local result = cmd:Execute()
    
    if not result or not result[1] or not result[1].id then
        error("Failed to place mine")
        return
    end
    
    local mine = self:AddMine({
        id = result[1].id,
        owner_id = steamID,
        position = position,
        angle = angle
    })
    mine:SyncNearby(player)
    mine.place_time = Server:GetElapsedSeconds()

    Network:Send(player, "items/MinePlaceSound", {position = position})
    Network:SendNearby(player, "items/MinePlaceSound", {position = position})

end

function sMines:SerializeAngle(ang)
    return math.round(ang.x, 5) .. "," .. math.round(ang.y, 5) .. "," .. math.round(ang.z, 5) .. "," .. math.round(ang.w, 5)
end

function sMines:DeserializeAngle(ang)
    local split = ang:split(",")
    return Angle(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), tonumber(split[4]) or 0)
end

-- args.ray = raycast down
function sMines:TryPlaceMine(args, player)

    args.ray.position = Vector3(args.ray.position.x, math.max(args.ray.position.y, player:GetPosition().y), args.ray.position.z)
    local angle = Angle.FromVectors(Vector3.Down, args.ray.normal) * Angle(0, math.pi / 2, 0)

    local player_iu = args.player_iu

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "Mine" then

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        -- Now actually place the mine
        self:PlaceMine(args.ray.position, angle, player)

    end


end

function sMines:CompleteItemUsage(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "Mine" then

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

        if not self.sz_config then
            self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()
        end

        if args.ray.collision and DisabledPlacementCollisions[args.ray.collision] then
            Chat:Send(player, "Placing mine failed!", Color.Red)
            return
        end
    
        -- If they are within sz radius * 2, we don't let them place that close
        if player:GetPosition():Distance(self.sz_config.safezone.position) < self.sz_config.safezone.radius * 2 then
            Chat:Send(player, "Cannot place mines while near the safezone!", Color.Red)
            return
        end

        local BlacklistedAreas = SharedObject.GetByName("BlacklistedAreas"):GetValues().blacklist

        for _, area in pairs(BlacklistedAreas) do
            if player:GetPosition():Distance(area.pos) < area.size then
                Chat:Send(player, "You cannot place mines here!", Color.Red)
                return
            end
        end

        local ModelChangeAreas = SharedObject.GetByName("ModelLocations"):GetValues()

        for _, area in pairs(ModelChangeAreas) do
            if player:GetPosition():Distance(area.pos) < 10 then
                Chat:Send(player, "You cannot place mines here!", Color.Red)
                return
            end
        end

        local sub = nil
        sub = Events:Subscribe("IsTooCloseToLootCheck"..tostring(player:GetSteamId()), function(args)
        
            Events:Unsubscribe(sub)
            sub = nil
    
            if args.too_close then
    
                Chat:Send(player, "Cannot place mines too close to loot!", Color.Red)
                return
    
            end
    
            self:TryPlaceMine(args, args.player)

        end)
    
        args.position = args.ray.position
        args.player = player
        args.player_iu = deepcopy(player_iu)
        Events:Fire("CheckIsTooCloseToLoot", args)
    
    end

end

sMines = sMines()
sMines:LoadAllMines()