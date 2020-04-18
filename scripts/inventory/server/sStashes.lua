class 'sStashes'

function sStashes:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS stashes (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, name VARCHAR, type INTEGER, position VARCHAR, angle VARCHAR, access_mode INTEGER, health REAL, contents BLOB)")

    self.stashes = {}

    Network:Subscribe("items/DeleteStash", self, self.DeleteClaymore)

    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
end

function sStashes:ItemExplode(args)

    --[[local cell = GetCell(args.position, ItemsConfig.usables.Claymore.cell_size)
    local adjacent_cells = GetAdjacentCells(cell)

    for _, cell in pairs(adjacent_cells) do

        VerifyCellExists(self.claymore_cells, cell)
        for _, claymore in pairs(self.claymore_cells[cell.x][cell.y]) do
            if claymore.position:Distance(args.position) < args.radius then
                self:DestroyClaymore({id = claymore.id}, args.player)
            end
        end

    end]]

end

function sStashes:PickupClaymore(args, player)
    --[[if not args.id or not self.claymores[args.id] then return end

    local claymore = self.claymores[args.id]

    --if claymore.owner_id ~= tostring(player:GetSteamId()) then return end -- They do not own this claymore

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
    claymore:Remove(player)]]

end

function sStashes:AddStash(args)

    -- TODO

    args.id = tonumber(args.id)

    local stash = sStash({
        id = args.id,
        owner_id = args.owner_id,
        position = args.position,
        angle = args.angle
    })
    
    self.stashes[args.id] = stash

    return stash

end

-- Load all stashes from DB
function sStashes:LoadAllStashes()

    -- TODO

    local result = SQL:Query("SELECT * FROM stashes"):Execute()
    
    if #result > 0 then

        for _, stash_data in pairs(result) do
            local split = stash_data.position:split(",")
            local pos = Vector3(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))

            local split2 = stash_data.angle:split(",")
            local angle = Angle(tonumber(split2[1]), tonumber(split2[2]), tonumber(split2[3]))

            self:AddStash({
                id = stash_data.id,
                owner_id = stash_data.steamID,
                position = pos,
                angle = angle
            })
        end

    end

end

function sStashes:PlaceStash(position, angle, player)
    
    -- TODO

    local steamID = tostring(player:GetSteamId())
    local cmd = SQL:Command("INSERT INTO stashes (steamID, position, angle) VALUES (?, ?, ?)")
    cmd:Bind(1, steamID)
    cmd:Bind(2, tostring(position))
    cmd:Bind(3, tostring(angle))
    cmd:Execute()

	cmd = SQL:Query("SELECT last_insert_rowid() as id FROM stashes")
    local result = cmd:Execute()
    
    if not result or not result[1] or not result[1].id then
        error("Failed to place stash")
        return
    end
    
    self:AddClaymore({
        id = result[1].id,
        owner_id = steamID, -- TODO: add friends to it as well
        position = position,
        angle = angle
    }):SyncNearby(player)

end

sStashes = sStashes()
sStashes:LoadAllStashes()