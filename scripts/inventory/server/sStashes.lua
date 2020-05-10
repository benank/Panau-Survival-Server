class 'sStashes'

function sStashes:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS stashes (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, name VARCHAR, type INTEGER, position VARCHAR, angle VARCHAR, access_mode INTEGER, health REAL, contents BLOB)")

    self.stashes = {}

    Network:Subscribe("Stashes/DeleteStash", self, self.DeleteStash)
    Network:Subscribe("Stashes/RenameStash", self, self.RenameStash)
    Network:Subscribe("Stashes/Dismount", self, self.DismountStash)

    Events:Subscribe("PlayerLevelUpdated", self, self.PlayerLevelUpdated)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
end

function sStashes:PlayerLevelUpdated(args)
    local old_max_stashes = args.player:GetValue("MaxStashes")
    local new_max_stashes = GetMaxFromLevel(args.player:GetValue("Exp").level, Stashes_Per_Level)

    if old_max_stashes ~= new_max_stashes then
        Chat:Send(args.player, string.format("You can place up to %d stashes!", new_max_stashes), Color(0, 255, 255))
    end

    args.player:SetNetworkValue("MaxStashes", new_max_stashes)
end

function sStashes:DismountStash(args, player)

    if not args.id then return end
    args.id = tonumber(args.id)

    local player_stashes = player:GetValue("Stashes")
    local stash = player_stashes[args.id]

    if not stash then return end

    local stash_instance = self.stashes[args.id]

    if not stash_instance then return end

    local stash_item_name = Lootbox.Stashes[stash_instance.lootbox.tier].name
    local contents = stash_instance.lootbox.contents

    local item_data = deepcopy(Items_indexed[stash_item_name])
    item_data.amount = 1

    local item = CreateItem(item_data)
    local stack = shStack({contents = {item}})

    table.insert(contents, stack)

    local dropbox = CreateLootbox({
        position = stash_instance.lootbox.position,
        angle = stash_instance.lootbox.angle,
        tier = Lootbox.Types.Dropbox,
        active = true,
        contents = contents
    })
    dropbox:Sync()

    -- Create dropbox with contents
    stash_instance:Remove()
    self.stashes[args.id] = nil

    player_stashes[args.id] = nil

    player:SetValue("Stashes", player_stashes)
    self:SyncStashesToPlayer(player)
end

function sStashes:RenameStash(args, player)
    
    if not args.id or not args.name then return end

    local player_stashes = player:GetValue("Stashes")
    local stash = player_stashes[args.id]

    if not stash then return end

    local stash_instance = self.stashes[args.id]

    if not stash_instance then return end

    stash_instance:ChangeName(args.name, player)
end

function sStashes:ClientModuleLoad(args)

    args.player:SetNetworkValue("MaxStashes", GetMaxFromLevel(args.player:GetValue("Exp").level, Stashes_Per_Level))
    
    local player_stashes = {}
    local steam_id = tostring(args.player:GetSteamId())

    for id, stash in pairs(self.stashes) do

        if stash.owner_id == steam_id then
            -- Player owns this stash
            player_stashes[id] = stash:GetSyncData()
        end

    end

    args.player:SetValue("Stashes", player_stashes)
    self:SyncStashesToPlayer(args.player)
end

function sStashes:SyncStashesToPlayer(player)
    Network:Send(player, "Stashes/SyncMyStashes", player:GetValue("Stashes"))
end

function sStashes:ItemExplode(args)

    -- TODO: damage nearby stashes

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

function sStashes:DeleteStash(args, player)
    --[[if not args.id or not self.stashes[args.id] then return end

    local claymore = self.stashes[args.id]

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

    args.id = tonumber(args.id)

    local lootbox = CreateLootbox({
        position = args.position,
        angle = args.angle,
        tier = args.tier,
        active = true,
        contents = args.contents
    })

    local stash = sStash({
        id = args.id,
        owner_id = args.owner_id,
        contents = args.contents,
        lootbox = lootbox,
        access_mode = tonumber(args.access_mode),
        health = args.health,
        name = args.name
    })

    lootbox.stash = stash
    
    self.stashes[args.id] = stash

    return lootbox

end

-- Load all stashes from DB
function sStashes:LoadAllStashes()

    local result = SQL:Query("SELECT * FROM stashes"):Execute()
    
    if #result > 0 then
        
        for _, stash_data in pairs(result) do
            local split = stash_data.position:split(",")
            local pos = Vector3(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))

            local angle = self:DeserializeAngle(stash_data.angle)

            self:AddStash({
                id = tonumber(stash_data.id),
                owner_id = stash_data.steamID,
                position = pos,
                angle = angle,
                tier = tonumber(stash_data.type),
                access_mode = tonumber(stash_data.access_mode),
                contents = Deserialize(stash_data.contents),
                name = stash_data.name,
                health = tonumber(stash_data.health)
            }):Sync()
        end

    end

end

function sStashes:PlaceStash(position, angle, type, player)
    
    local steamID = tostring(player:GetSteamId())

    local lootbox_data = Lootbox.Stashes[type]
    if not lootbox_data then return end

    local cmd = SQL:Command("INSERT INTO stashes (steamID, name, type, position, angle, access_mode, health, contents) VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
    cmd:Bind(1, steamID)
    cmd:Bind(2, lootbox_data.name)
    cmd:Bind(3, type)
    cmd:Bind(4, tostring(position))
    cmd:Bind(5, self:SerializeAngle(angle))
    cmd:Bind(6, lootbox_data.default_access)
    cmd:Bind(7, lootbox_data.health)
    cmd:Bind(8, "")
    cmd:Execute()

	cmd = SQL:Query("SELECT last_insert_rowid() as id FROM stashes")
    local result = cmd:Execute()
    
    if not result or not result[1] or not result[1].id then
        error("Failed to place stash")
        return
    end

    local lootbox = self:AddStash({
        id = result[1].id,
        owner_id = steamID,
        position = position,
        angle = angle,
        contents = {},
        health = lootbox_data.health,
        tier = type,
        name = lootbox_data.name,
        access_mode = lootbox_data.default_access
    })

    lootbox:Sync()

    local player_stashes = player:GetValue("Stashes")
    player_stashes[lootbox.stash.id] = lootbox.stash:GetSyncData()

    player:SetValue("Stashes", player_stashes)
    self:SyncStashesToPlayer(player)
end

function sStashes:SerializeAngle(ang)
    return math.round(ang.x, 5) .. "," .. math.round(ang.y, 5) .. "," .. math.round(ang.z, 5) .. "," .. math.round(ang.w, 5)
end

function sStashes:DeserializeAngle(ang)
    local split = ang:split(",")
    return Angle(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), tonumber(split[4]) or 0)
end

sStashes = sStashes()
sStashes:LoadAllStashes()