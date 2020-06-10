class 'sStats'

function sStats:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS player_data (steamID VARCHAR UNIQUE, kills INTEGER, deaths INTEGER, time_online INTEGER, ip VARCHAR, "..
    "first_login VARCHAR, last_login VARCHAR, tier1_looted INTEGER, tier2_looted INTEGER, tier3_looted INTEGER, tier4_looted INTEGER, tier5_looted INTEGER, stashes_hacked INTEGER)")

    Events:Subscribe("PlayerKilled", self, self.PlayerKilled)
    Events:Subscribe("PlayerDeath", self, self.PlayerDeath)
    Events:Subscribe("PlayerOpenLootbox", self, self.PlayerOpenLootbox)
    Events:Subscribe("Stats/Update", self, self.UpdateStat)
    Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("MinuteTick", self, self.MinuteTick)
    Events:Subscribe("items/HackComplete", self, self.HackComplete)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

    -- Every 5 minutes, save stats
    Timer.SetInterval(1000 * 60 * 5, function()
    end)

end

function sStats:ModuleUnload()
    for p in Server:GetPlayers() do
        self:UpdateAllStats(p)
    end
end

function sStats:PlayerQuit(args)
    self:UpdateAllStats(args.player)
end

function sStats:HackComplete(args)

    local stashes_hacked = args.player:GetValue("PlayerData")["stashes_hacked"] + 1

    self:UpdateStat({
        player = args.player,
        key = "stashes_hacked",
        value = stashes_hacked
    })

end

function sStats:PlayerKilled(args)
    if not args.killer then return end
    
	local query = SQL:Query("SELECT kills FROM player_data WHERE steamID = (?) LIMIT 1")
    query:Bind(1, args.killer)
    
    local result = query:Execute()

    if #result == 0 then return end

    local kills = result[1].kills + 1

    self:UpdateStat({
        steam_id = args.killer,
        key = "kills",
        value = kills
    })

end

function sStats:PlayerDeath(args)
    self:UpdateStat({
        player = args.player,
        key = "deaths",
        value = args.player:GetValue("PlayerData").deaths + 1
    })
end

function sStats:PlayerOpenLootbox(args)
    if args.has_been_opened then return end

    local tier_name

    if args.tier == 1 then
        tier_name = "tier1_looted"
    elseif args.tier == 2 then
        tier_name = "tier2_looted"
    elseif args.tier == 3 then
        tier_name = "tier3_looted"
    elseif args.tier == 4 then
        tier_name = "tier4_looted"
    elseif args.tier == 5 then
        tier_name = "tier5_looted"
    end

    if tier_name then

        local boxes_looted = args.player:GetValue("PlayerData")[tier_name] + 1

        self:UpdateStat({
            player = args.player,
            key = tier_name,
            value = boxes_looted
        })

    end

end

function sStats:UpdateAllStats(player)

    if not IsValid(player) then return end

    local player_stats = player:GetValue("PlayerData")

    if not player_stats then return end

    local command = SQL:Command("UPDATE player_data SET kills = ?, deaths = ?, time_online = ?, ip = ?, first_login = ?, last_login = ?, tier1_looted = ?, tier2_looted = ?, tier3_looted = ?, tier4_looted = ?, tier5_looted = ?, stashes_hacked = ? WHERE steamID = (?)")
    command:Bind(1, player_stats.kills)
    command:Bind(2, player_stats.deaths)
    command:Bind(3, player_stats.time_online)
    command:Bind(4, tostring(player:GetIP()))
    command:Bind(5, player_stats.first_login)
    command:Bind(6, self:GetDateNow())
    command:Bind(7, player_stats.tier1_looted)
    command:Bind(8, player_stats.tier2_looted)
    command:Bind(9, player_stats.tier3_looted)
    command:Bind(10, player_stats.tier4_looted)
    command:Bind(11, player_stats.tier5_looted)
    command:Bind(12, player_stats.stashes_hacked)
    command:Bind(13, tostring(player:GetSteamId()))
    command:Execute()

end

function sStats:MinuteTick()

    for p in Server:GetPlayers() do
        if IsValid(p) then
            local player_data = p:GetValue("PlayerData")

            if player_data then
                player_data.time_online = player_data.time_online + 1
                self:UpdateStat({
                    player = p,
                    key = "time_online",
                    value = player_data.time_online
                })
            end
        end
    end

end

function sStats:UpdateStat(args)
    if not IsValid(args.player) and not args.steam_id then return end
    if not args.key then return end
    if not args.value then return end

    -- Update SQL if player is not online, otherwise update it when they leave to save sql executions
    if not IsValid(args.player) then

        local steam_id = args.steam_id or tostring(args.player:GetSteamId())

        local update = SQL:Command(string.format("UPDATE player_data SET %s = ? WHERE steamID = (?)", args.key))
        update:Bind(1, args.value)
        update:Bind(2, steam_id)
        update:Execute()

    end
        
    if IsValid(args.player) then
        local player_data = args.player:GetValue("PlayerData")
        player_data[args.key] = args.value
        args.player:SetValue("PlayerData", player_data)
    end

end

function sStats:GetDateNow()
    return os.date("%Y-%m-%d-%H-%M-%S")
end

function sStats:PlayerJoin(args)

    local steamID = tostring(args.player:GetSteamId())
    
	local query = SQL:Query("SELECT * FROM player_data WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        
        -- Do something with the data
        -- future TODO
        
    else
        
		local command = SQL:Command("INSERT INTO player_data (steamID, kills, deaths, time_online, ip, first_login, last_login, tier1_looted, tier2_looted, tier3_looted, tier4_looted, tier5_looted, stashes_hacked) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, 0)
		command:Bind(3, 0)
		command:Bind(4, 0)
		command:Bind(5, tostring(args.player:GetIP()))
		command:Bind(6, self:GetDateNow())
		command:Bind(7, self:GetDateNow())
		command:Bind(8, 0)
		command:Bind(9, 0)
		command:Bind(10, 0)
		command:Bind(11, 0)
		command:Bind(12, 0)
		command:Bind(13, 0)
        command:Execute()
        
	end

	local query = SQL:Query("SELECT * FROM player_data WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    args.player:SetValue("PlayerData", result[1])

    self:UpdateStat({
        player = args.player,
        key = "last_login",
        value = self:GetDateNow()
    })

end


sStats = sStats()