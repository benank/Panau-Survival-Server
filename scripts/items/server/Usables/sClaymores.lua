class 'sClaymores'

function sClaymores:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS claymores (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, position VARCHAR, angle VARCHAR)")

    self.claymores = {} -- Active claymores, indexed by claymore id
    self.claymore_cells = {} -- Active claymores, organized by cell x, y, then claymore id

    self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()

    Network:Subscribe("items/CancelClaymorePlacement", self, self.CancelClaymorePlacement)
    Network:Subscribe("items/PlaceClaymore", self, self.FinishClaymorePlacement)
    Network:Subscribe("items/StepOnClaymore", self, self.StepOnClaymore)
    Network:Subscribe("items/DestroyClaymore", self, self.DestroyClaymore)
    Network:Subscribe("items/PickupClaymore", self, self.PickupClaymore)

    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(ItemsConfig.usables.Claymore.cell_size), self, self.PlayerCellUpdate)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
end

function sClaymores:ItemExplode(args)

    local cell = GetCell(args.position, ItemsConfig.usables.Claymore.cell_size)
    local adjacent_cells = GetAdjacentCells(cell)

    for _, cell in pairs(adjacent_cells) do

        VerifyCellExists(self.claymore_cells, cell)
        for _, claymore in pairs(self.claymore_cells[cell.x][cell.y]) do
            if claymore.position:Distance(args.position) < args.radius then
                self:DestroyClaymore({id = claymore.id}, args.player)
            end
        end

    end

end


function sClaymores:DestroyClaymore(args, player)
    if not args.id or not self.claymores[args.id] then return end

    local claymore = self.claymores[args.id]

    if claymore.exploded then return end

    Network:Send(player, "items/ClaymoreExplode", {position = claymore.position, id = claymore.id, owner_id = claymore.owner_id})
    Network:SendNearby(player, "items/ClaymoreExplode", {position = claymore.position, id = claymore.id, owner_id = claymore.owner_id})

    local cmd = SQL:Command("DELETE FROM claymores where id = ?")
    cmd:Bind(1, args.id)
    cmd:Execute()

    -- Remove claymore
    local cell = claymore:GetCell()
    self.claymore_cells[cell.x][cell.y][args.id] = nil
    self.claymores[args.id] = nil
    claymore:Remove(player)

    Events:Fire("items/ItemExplode", {
        position = claymore.position,
        radius = 10,
        player = player
    })

end

function sClaymores:PickupClaymore(args, player)
    if not args.id or not self.claymores[args.id] then return end

    local claymore = self.claymores[args.id]

    if claymore.owner_id ~= tostring(player:GetSteamId()) then return end -- They do not own this claymore

    if claymore.exploded then return end

    local num_claymores = Inventory.GetNumOfItem({player = player, item_name = "Claymore"})

    local item = deepcopy(Items_indexed["Claymore"])
    item.amount = 1

    Inventory.AddItem({
        item = item,
        player = player
    })

    -- If the number of claymores in their inventory did not go up, they did not have room for it
    if num_claymores == Inventory.GetNumOfItem({player = player, item_name = "Claymore"}) then
        Chat:Send(player, "Failed to pick up claymore because you do not have space for it!", Color.Red)
        return
    end

    local cmd = SQL:Command("DELETE FROM claymores where id = ?")
    cmd:Bind(1, args.id)
    cmd:Execute()

    -- Remove claymore
    local cell = claymore:GetCell()
    self.claymore_cells[cell.x][cell.y][args.id] = nil
    self.claymores[args.id] = nil
    claymore:Remove(player)

end

function sClaymores:ClientModuleLoad(args)
    Events:Fire("ForcePlayerUpdateCell", {player = args.player, cell_size = ItemsConfig.usables.Claymore.cell_size})
end

function sClaymores:PlayerCellUpdate(args)
    
    local claymore_data = {}

    for _, update_cell in pairs(args.updated) do

        -- If these cells don't exist, create them
        VerifyCellExists(self.claymore_cells, update_cell)

        for _, claymore in pairs(self.claymore_cells[update_cell.x][update_cell.y]) do
            if not claymore.exploded then -- Only get active claymore
                table.insert(claymore_data, claymore:GetSyncObject())
            end
        end
    end
    
	-- send the existing claymore in the newly streamed cells
    Network:Send(args.player, "items/ClaymoresCellsSync", {claymore_data = claymore_data})
end

function sClaymores:StepOnClaymore(args, player)

    if not args.id then return end
    local id = tonumber(args.id)

    local claymore = self.claymores[id]
    if not claymore then return end

    if claymore:Trigger(player) then

        local cell = claymore:GetCell()

        -- Successfully exploded, remove claymore
        local cmd = SQL:Command("DELETE FROM claymores where id = ?")
        cmd:Bind(1, id)
        cmd:Execute()

        -- Remove claymore
        self.claymore_cells[cell.x][cell.y][id] = nil
        self.claymores[id] = nil
        
        Events:Fire("items/ItemExplode", {
            position = claymore.position,
            radius = 10,
            player = player
        })
    end

end

function sClaymores:AddClaymore(args)

    args.id = tonumber(args.id)

    local claymore = sClaymore({
        id = args.id,
        owner_id = args.owner_id,
        position = args.position,
        angle = args.angle
    })
    
    self.claymores[args.id] = claymore
    local cell = claymore:GetCell()

    -- Add to claymores in the cell
    VerifyCellExists(self.claymore_cells, cell)
    self.claymore_cells[cell.x][cell.y][claymore.id] = claymore

    return claymore

end

-- Load all claymores from DB
function sClaymores:LoadAllClaymores()

    local result = SQL:Query("SELECT * FROM claymores"):Execute()
    
    if #result > 0 then

        for _, claymore_data in pairs(result) do
            local split = claymore_data.position:split(",")
            local pos = Vector3(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))

            local split2 = claymore_data.angle:split(",")
            local angle = Angle(tonumber(split2[1]), tonumber(split2[2]), tonumber(split2[3]))

            self:AddClaymore({
                id = claymore_data.id,
                owner_id = claymore_data.steamID,
                position = pos,
                angle = angle
            })
        end

    end

end

function sClaymores:PlaceClaymore(position, angle, player)

    local steamID = tostring(player:GetSteamId())
    local cmd = SQL:Command("INSERT INTO claymores (steamID, position, angle) VALUES (?, ?, ?)")
    cmd:Bind(1, steamID)
    cmd:Bind(2, tostring(position))
    cmd:Bind(3, tostring(angle))
    cmd:Execute()

	cmd = SQL:Query("SELECT last_insert_rowid() as id FROM claymores")
    local result = cmd:Execute()
    
    if not result or not result[1] or not result[1].id then
        error("Failed to place claymore")
        return
    end
    
    self:AddClaymore({
        id = result[1].id,
        owner_id = steamID, -- TODO: add friends to it as well
        position = position,
        angle = angle
    }):SyncNearby(player)

    Network:Send(player, "items/ClaymorePlaceSound", {position = position})
    Network:SendNearby(player, "items/ClaymorePlaceSound", {position = position})

end

function sClaymores:TryPlaceClaymore(args, player)

    local player_iu = player:GetValue("ClaymoreUsingItem")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name]
        and player_iu.item.name == "Claymore" then

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        -- Now actually place the claymore
        self:PlaceClaymore(args.position, args.angle, player)

    end


end

function sClaymores:UseItem(args)

    if args.item.name ~= "Claymore" then return end

    if args.player:GetValue("StuntingVehicle") then
        Chat:Send(args.player, "You cannot use this item while stunting on a vehicle!", Color.Red)
        return
    end

    Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
    args.player:SetValue("ClaymoreUsingItem", args)

    Network:Send(args.player, "items/StartClaymorePlacement")

end

function sClaymores:CancelClaymorePlacement(args, player)
    Inventory.OperationBlock({player = player, change = -1})
end

function sClaymores:FinishClaymorePlacement(args, player)
    Inventory.OperationBlock({player = player, change = -1})

    if player:InVehicle() then
        Chat:Send(player, "Cannot place claymores while in a vehicle!", Color.Red)
        return
    end

    if args.position:Distance(player:GetPosition()) > 7 then
        Chat:Send(player, "Placing claymore failed!", Color.Red)
        return
    end

    -- If they are within sz radius * 2, we don't let them place that close
    if player:GetPosition():Distance(self.sz_config.safezone.position) < self.sz_config.safezone.radius * 2 then
        Chat:Send(player, "Cannot place claymores while near the safezone!", Color.Red)
        return
    end


    self:TryPlaceClaymore(args, player)

end

sClaymores = sClaymores()
sClaymores:LoadAllClaymores()