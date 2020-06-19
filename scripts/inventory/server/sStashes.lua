class 'sStashes'

function sStashes:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS stashes (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, name VARCHAR, type INTEGER, position VARCHAR, angle VARCHAR, access_mode INTEGER, health REAL, contents BLOB)")

    self.stashes = {} -- Stashes indexed by stash id
    self.stashes_by_uid = {} -- Stashes by lootbox uid

    Network:Subscribe("Stashes/DeleteStash", self, self.DeleteStash)
    Network:Subscribe("Stashes/RenameStash", self, self.RenameStash)
    Network:Subscribe("Stashes/Dismount", self, self.DismountStash)
    Network:Subscribe("Stashes/UpdateStashAccessMode", self, self.UpdateStashAccessMode)

    Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated)
    Events:Subscribe("Items/PlaceProximityAlarm", self, self.PlaceProximityAlarm)
    Events:Subscribe("Inventory/ModifyStashStackRemote", self, self.ModifyStashStackRemote)
    Events:Subscribe("items/DestroyProximityAlarm", self, self.DestroyProximityAlarm)
    Events:Subscribe("items/C4DetonateOnStash", self, self.C4DetonateOnStash)

    Events:Subscribe("items/HackComplete", self, self.HackComplete)
end

-- When a C4 attached to a stash detonates
function sStashes:C4DetonateOnStash(args)

    local stash = self.stashes_by_uid[args.lootbox_uid]

    if not stash then return end

    stash.health = stash.health - C4StashDamage

    Events:Fire("Discord", {
        channel = "Stashes",
        content = string.format("**RAID** %s [%s] used C4 on stash %d [%s]", 
            args.player:GetName(), tostring(args.player:GetSteamId()), stash.id, stash.owner_id)
    })

    if stash.health <= 0 then
        -- Remove stash

        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = stash.owner_id,
            message = string.format("%s destroyed your stash [%s] %s", args.player:GetName(), stash.name, WorldToMapString(stash.lootbox.position)),
            color = Color(200, 0, 0)
        })

        local owner = nil

        for p in Server:GetPlayers() do
            if tostring(p:GetSteamId()) == stash.owner_id then
                owner = p
            end
        end

        if count_table(stash.lootbox.contents) > 0 and stash.owner_id ~= tostring(args.player:GetSteamId()) then
            Events:Fire("Stashes/DestroyStash", {
                tier = stash.lootbox.tier,
                player = args.player
            })
        end

        self:DeleteStash({id = stash.id}, owner or args.player)

        Events:Fire("Discord", {
            channel = "Stashes",
            content = string.format("**RAID** %s [%s] destroyed stash %d [%s]", 
                args.player:GetName(), tostring(args.player:GetSteamId()), stash.id, stash.owner_id)
        })

    else
        stash:UpdateToDB()
    end

end

function sStashes:UpdateStashAccessMode(args, player)

    if not args.mode then return end

    local current_box = player:GetValue("CurrentLootbox")

    if not current_box or not current_box.stash then return end

    local stash = self.stashes[current_box.stash.id]

    if not stash then return end

    stash:ChangeAccessMode(args.mode, player)

end

function sStashes:HackComplete(args)

    local stash = self.stashes[args.stash_id]

    if not stash then return end

    if stash.owner_id == "SERVER" then return end


    if stash.owner_id == tostring(args.player:GetSteamId()) then return end

    if stash.lootbox.tier == Lootbox.Types.ProximityAlarm then

        -- Hacked proximity alarm
        local old_owner_id = stash.owner_id

        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = old_owner_id,
            message = string.format("%s hacked your proximity alarm %s", args.player:GetName(), WorldToMapString(stash.lootbox.position)),
            color = Color(200, 0, 0)
        })

        -- Transfer ownership
        stash.owner_id = tostring(args.player:GetSteamId())
        stash.access_mode = StashAccessMode.Everyone

        -- Lock Prox Alarm
        stash:UpdateToDB()

        Events:Fire("Items/ChangeAlarmOwnership", {
            uid = stash.lootbox.uid,
            owner_id = stash.owner_id
        })

        stash.lootbox:ForceClose()
        stash.lootbox:Sync()

        Events:Fire("Discord", {
            channel = "Stashes",
            content = string.format("**RAID** %s [%s] hacked proximity alarm %d [%s]", 
                args.player:GetName(), tostring(args.player:GetSteamId()), stash.id, stash.owner_id)
        })

    else

        -- They can open it, so do not complete the hack
        if stash.CanPlayerOpen(args.player) then return end

        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = stash.owner_id,
            message = string.format("%s hacked your stash [%s] %s", args.player:GetName(), stash.name, WorldToMapString(stash.lootbox.position)),
            color = Color(200, 0, 0)
        })

        stash.access_mode = StashAccessMode.Everyone
        stash:UpdateToDB()
        stash.lootbox:Sync()

        stash.lootbox:ForceClose()

        Events:Fire("Discord", {
            channel = "Stashes",
            content = string.format("**RAID** %s [%s] hacked stash %d [%s]", 
                args.player:GetName(), tostring(args.player:GetSteamId()), stash.id, stash.owner_id)
        })

    end
        
end

function sStashes:DestroyProximityAlarm(args)
    
    if not args.id then return end
    args.id = tonumber(args.id)

    local stash_instance = self.stashes[args.id]

    if not stash_instance then return end

    if stash_instance.owner_id ~= tostring(args.player:GetSteamId())
    and args.give_exp then
        Events:Fire("Stashes/DestroyStash", {
            tier = stash_instance.lootbox.tier,
            player = args.player
        })
    end

    self:DeleteStash(args)
end

function sStashes:ModifyStashStackRemote(args)

    local stash = self.stashes_by_uid[args.stash_id]
    if not stash then return end

    local contents = {}

    for index, item in pairs(args.stack.contents) do
        contents[index] = shItem(item)
    end

    if count_table(contents) > 0 then
        stash.lootbox.contents[args.stack_index] = shStack({contents = contents, uid = args.stack.uid})
    else
        stash.lootbox.contents[args.stack_index] = nil
    end
    
    stash.lootbox:UpdateToPlayers()
    stash:UpdateToDB()

end

function sStashes:PlaceProximityAlarm(args)
    self:PlaceStash(args.position, args.angle, Lootbox.Types.ProximityAlarm, args.player)
end

function sStashes:PlayerPerksUpdated(args)
    local perks = args.player:GetValue("Perks")
    local old_max_stashes = args.player:GetValue("MaxStashes")
    
    local new_max_stashes = self:GetPlayerMaxStashes(args.player)

    if old_max_stashes ~= new_max_stashes and old_max_stashes then
        Chat:Send(args.player, string.format("You can place up to %d stashes!", new_max_stashes), Color(0, 255, 255))
    end

    args.player:SetNetworkValue("MaxStashes", new_max_stashes)
end

function sStashes:GetPlayerMaxStashes(player)

    local perks = player:GetValue("Perks")

    if not perks then return 0 end

    local new_max_stashes = Initial_Stash_Amount

    for perk_id, bonus in pairs(Stashes_Per_Perk) do
        if perks.unlocked_perks[perk_id] then
            new_max_stashes = new_max_stashes + bonus
        end
    end

    return new_max_stashes

end

function sStashes:DismountStash(args, player)

    if not args.id then return end
    args.id = tonumber(args.id)

    local stash_instance = self.stashes[args.id]

    if not stash_instance then return end
    if stash_instance.owner_id ~= tostring(player:GetSteamId()) then return end

    local stash_item_name = Lootbox.Stashes[stash_instance.lootbox.tier].name
    local contents = stash_instance.lootbox.contents

    local item_data = deepcopy(Items_indexed[stash_item_name])
    item_data.amount = 1

    local item = CreateItem(item_data)
    local stack = shStack({contents = {item}})

    table.insert(contents, stack)

    self:DiscordMessageWithContents(
        string.format("%s [%s] dismounted stash %d [%s] [Tier: %d]", 
            player:GetName(), tostring(player:GetSteamId()), stash_instance.id, stash_instance.owner_id, stash_instance.lootbox.tier),
        stash_instance.lootbox.contents)

    local type = stash_instance.lootbox.tier

    local angle = type == Lootbox.Types.ProximityAlarm and Angle() or stash_instance.lootbox.angle

    local dropbox = CreateLootbox({
        position = stash_instance.lootbox.position,
        angle = angle,
        tier = Lootbox.Types.Dropbox,
        active = true,
        contents = contents
    })
    dropbox:Sync()

    -- Create dropbox with contents
    self.stashes[args.id] = nil
    self.stashes_by_uid[stash_instance.lootbox.uid] = nil
    stash_instance:Remove()

    if type ~= Lootbox.Types.ProximityAlarm then
        local player_stashes = player:GetValue("Stashes")
        player_stashes[args.id] = nil

        player:SetValue("Stashes", player_stashes)
        self:SyncStashesToPlayer(player)
    end
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

function sStashes:DiscordMessageWithContents(message, contents)

    local msg = message .. "\nContents:\n"

    for _, stack in pairs(contents) do
        msg = msg .. stack:ToString() .. "\n"
    end

    Events:Fire("Discord", {
        channel = "Stashes",
        content = msg
    })

end

function sStashes:ClientModuleLoad(args)

    args.player:SetNetworkValue("MaxStashes", self:GetPlayerMaxStashes(args.player))
    
    local player_stashes = {}
    local steam_id = tostring(args.player:GetSteamId())

    for id, stash in pairs(self.stashes) do

        if stash.owner_id == steam_id and stash.lootbox.tier ~= Lootbox.Types.ProximityAlarm then
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

-- Player deleted stash so contents are not dropped on ground
function sStashes:DeleteStash(args, player)
    
    if not args.id then return end
    args.id = tonumber(args.id)

    local stash_instance = self.stashes[args.id]

    if not stash_instance then return end

    local owner_id = stash_instance.owner_id

    self:DiscordMessageWithContents(
        string.format("%s [%s] deleted stash %d [%s] [Tier: %d]", 
            IsValid(player) and player:GetName() or "NONE", IsValid(player) and tostring(player:GetSteamId()) or "NONE", 
            stash_instance.id, stash_instance.owner_id, stash_instance.lootbox.tier),
        stash_instance.lootbox.contents)

    -- Create dropbox with contents
    self.stashes_by_uid[stash_instance.lootbox.uid] = nil
    self.stashes[args.id] = nil
    stash_instance:Remove()

    local owner = nil

    for p in Server:GetPlayers() do
        if tostring(p:GetSteamId()) == owner_id then
            owner = p
            break
        end
    end

    if IsValid(owner) then
        local player_stashes = owner:GetValue("Stashes")

        player_stashes[args.id] = nil

        owner:SetValue("Stashes", player_stashes)
        self:SyncStashesToPlayer(owner)
    end

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
    self.stashes_by_uid[lootbox.uid] = stash

    Events:Fire("Inventory/CreateLootbox", lootbox:GetFullData())

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
        error(debug.traceback("Failed to place stash"))
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

    if type ~= Lootbox.Types.ProximityAlarm then

        local player_stashes = player:GetValue("Stashes")
        player_stashes[lootbox.stash.id] = lootbox.stash:GetSyncData()

        player:SetValue("Stashes", player_stashes)
        self:SyncStashesToPlayer(player)

    end
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
sWorkBenchManager:CreateWorkbenches()