class 'sPerks'

function sPerks:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS perks (steamID VARCHAR(20), points INTEGER, unlocked_perks BLOB)")

    Events:Subscribe("PlayerLevelUpdated", self, self.PlayerLevelUpdated)
    Network:Subscribe("Perks/Unlock", self, self.Unlock)

    Events:Subscribe("PlayerChat", self, self.PlayerChat)

    Events:Subscribe("GetPlayerPerksById", self, self.GetPlayerPerks)

end

function sPerks:PlayerChat(args)

    if not IsAdmin(args.player) then return end

    local words = args.text:split(" ")

    if words[1] == "/givepoints" and words[2] and words[3] then
        local target_player = Player.GetById(tonumber(words[2]))

        if not IsValid(target_player) then
            Chat:Send(args.player, "Invalid player. Use ID.", Color.Red)
            return
        end

        local perks = target_player:GetValue("Perks")
        perks.points = perks.points + tonumber(words[3])
        target_player:SetNetworkValue("Perks", perks)

        self:SavePlayer(target_player)

        Chat:Send(args.player, string.format("Gave %d points to %s.", tonumber(words[3]), target_player:GetName()), Color.Yellow)
        Chat:Send(target_player, string.format("You have been awarded %d perk points!", tonumber(words[3])), Color.Yellow)

        Events:Fire("Discord", {
            channel = "Experience",
            content = string.format("%s [%s] gave %s [%s] %d perk points.", 
                args.player:GetName(), tostring(args.player:GetSteamId()), target_player:GetName(), tostring(target_player:GetSteamId()), 
                tonumber(words[3]))
        })

    end

end

function sPerks:Unlock(args, player)

    if not args.id or not args.choice then return end

    local perk_data = ExpPerksById[args.id]

    if not perk_data then return end

    local perks = player:GetValue("Perks")

    if perks.unlocked_perks[args.id] then return end

    local level = player:GetValue("Exp").level

    if level < perk_data.level_req then
        Chat:Send(player, string.format("You must be at least level %d to unlock this!", perk_data.level_req), Color.Red)
        return
    end

    if perk_data.perk_req > 0 and not perks.unlocked_perks[perk_data.perk_req] then
        Chat:Send(player, string.format("You must unlock perk %d before unlocking this!", perk_data.perk_req), Color.Red)
        return
    end

    if perks.points < perk_data.cost then
        Chat:Send(player, "You do not have enough points to unlock this!", Color.Red)
        return
    end

    -- All good, unlock now
    perks.points = perks.points - perk_data.cost
    perks.unlocked_perks[args.id] = args.choice

    player:SetNetworkValue("Perks", perks)
    self:SavePlayer(player)

    Events:Fire("PlayerPerksUpdated", {player = player})

    Events:Fire("Discord", {
        channel = "Experience",
        content = string.format("%s [%s] unlocked perk ID %d with choice %d.", 
        player:GetName(), tostring(player:GetSteamId()), args.id, args.choice)
    })

end

function sPerks:OfflinePlayerGainedLevel(steam_id, level)
    -- Player was offline when they gained a level - give perk points
    
	local query = SQL:Query("SELECT * FROM perks WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steam_id)
    
    local result = query:Execute()

    local perk_data = {points = 0, unlocked_perks = {}}
    
    if #result > 0 then -- if already in DB
        
        perk_data.points = tonumber(result[1].points)
        perk_data.unlocked_perks = self:DeserializePerks(result[1].unlocked_perks)

    end

    perk_data.points = perk_data.points + PerkPointsPerLevel

    if PerkPointBonusesPerLevel[level] then
        perk_data.points = perk_data.points + PerkPointBonusesPerLevel[level]
    end

    local update = SQL:Command("UPDATE perks SET points = ?, unlocked_perks = ? WHERE steamID = (?)")
	update:Bind(1, perk_data.points)
	update:Bind(2, self:SerializePerks(perk_data.unlocked_perks))
	update:Bind(3, steam_id)
    update:Execute()

end

function sPerks:PlayerLevelUpdated(args)

    local perks = args.player:GetValue("Perks")
    perks.points = perks.points + PerkPointsPerLevel

    local level = args.player:GetValue("Exp").level

    if PerkPointBonusesPerLevel[level] then
        perks.points = perks.points + PerkPointBonusesPerLevel[level]
    end

    args.player:SetNetworkValue("Perks", perks)

    self:SavePlayer(args.player)

    Chat:Send(args.player, 
        string.format("You have %d perk points - open the perk menu with F2 to spend them!", perks.points), Color.Yellow)

end

function sPerks:SavePlayer(player)

    if not IsValid(player) then return end

    local perks = player:GetValue("Perks")

    local update = SQL:Command("UPDATE perks SET points = ?, unlocked_perks = ? WHERE steamID = (?)")
	update:Bind(1, perks.points)
	update:Bind(2, self:SerializePerks(perks.unlocked_perks))
	update:Bind(3, tostring(player:GetSteamId()))
    update:Execute()

end

function sPerks:SerializePerks(unlocked_perks)

    local serialized = ""

    for id, choice in pairs(unlocked_perks) do
        serialized = serialized .. tostring(id) .. "_" .. tostring(choice) .. " "
    end

    return serialized

end

function sPerks:DeserializePerks(unlocked_perks)

    local parsed = {}

    local split = unlocked_perks:trim():split(" ")

    -- Parse perks into a table
    for _, perk_id in pairs(split) do
        if perk_id:find("_") then

            -- Choice perk
            local split2 = perk_id:split("_")
            local id = tonumber(split2[1])
            local choice = tonumber(split2[2])
            if id ~= nil and choice ~= nil then
                parsed[id] = choice
            end

        else

            -- Single unlock perk
            local id = tonumber(perk_id)
            parsed[perk_id] = 1

        end
    end

    return parsed

end

function sPerks:GetPlayerPerks(args)

    if not args.steam_id then return end

	local query = SQL:Query("SELECT * FROM perks WHERE steamID = (?) LIMIT 1")
    query:Bind(1, args.steam_id)
    
    local result = query:Execute()

    local perk_data = {points = 0, unlocked_perks = {}}
    
    if #result > 0 then -- if already in DB
        
        perk_data.points = tonumber(result[1].points)
        perk_data.unlocked_perks = self:DeserializePerks(result[1].unlocked_perks)

    end

    Events:Fire("GetPlayerPerksById" .. args.steam_id, perk_data)
end

function sPerks:ClientModuleLoad(args)
    -- Called by sExp to ensure levels are loaded first
    
    local steamID = tostring(args.player:GetSteamId())

    local exp_data = args.player:GetValue("Exp")
    
	local query = SQL:Query("SELECT * FROM perks WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()

    local perk_data = {}
    
    if #result > 0 then -- if already in DB
        
        perk_data.points = tonumber(result[1].points)
        perk_data.unlocked_perks = self:DeserializePerks(result[1].unlocked_perks)

    else

        local perk_points = exp_data.level * PerkPointsPerLevel

        -- Add special level up point bonuses
        for i = 0, exp_data.level do
            if PerkPointBonusesPerLevel[i] then
                perk_points = perk_points + PerkPointBonusesPerLevel[i]
            end
        end
        
        -- Retroactively add perk points
		local command = SQL:Command("INSERT INTO perks (steamID, points, unlocked_perks) VALUES (?, ?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, perk_points)
		command:Bind(3, "")
        command:Execute()

        perk_data.points = perk_points
        perk_data.unlocked_perks = {}

    end
    
    args.player:SetNetworkValue("Perks", perk_data)

    Events:Fire("PlayerPerksUpdated", {player = args.player})

end

sPerks = sPerks()