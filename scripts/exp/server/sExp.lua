class 'sExp'

function sExp:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS exp (steamID VARCHAR(20), level INTEGER, combat_exp INTEGER, explore_exp INTEGER)")

    self.players = {}
    self.recent_killers = {} -- Players who have been killed recently by another player
    self.global_multiplier = 1

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)

    Events:Subscribe("PlayerOpenLootbox", self, self.PlayerOpenLootbox)
    Events:Subscribe("PlayerKilled", self, self.PlayerKilled)
    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)

    Events:Subscribe("items/HackComplete", self, self.HackComplete)
    Events:Subscribe("Stashes/DestroyStash", self, self.DestroyStash)
    Events:Subscribe("drones/DroneDestroyed", self, self.DroneDestroyed)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)

    Events:Subscribe("PlayerChat", self, self.PlayerChat)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)

end

function sExp:PlayerQuit(args)
    
    local steam_id = tostring(args.player:GetSteamId())
    self.players[steam_id] = nil
    local exp_data = args.player:GetValue("Exp")

    if not exp_data then return end

    self:UpdateDB(steam_id, exp_data)

end

function sExp:ModuleUnload()

    for p in Server:GetPlayers() do
        local steam_id = tostring(p:GetSteamId())
        local exp_data = p:GetValue("Exp")

        if exp_data then
            self:UpdateDB(steam_id, exp_data)
        end
    end

end

function sExp:DroneDestroyed(args)

    local exp_earned = Exp.DestroyDrone.Base + Exp.DestroyDrone.Per_Level * args.drone_level
    if not exp_earned then return end

    -- +10% extra total exp for each extra player that helps to kill a drone
    if count_table(args.exp_split) > 1 then
        exp_earned = exp_earned * (1 + Exp.DestroyDrone.AdditionalPercentPerPlayer * (count_table(args.exp_split) - 1))
    end

    for steam_id, split_percent in pairs(args.exp_split) do

        local player = self.players[steam_id]

        if IsValid(player) then

            local exp_data = player:GetValue("Exp")
            if not exp_data then return end

            local player_exp_earned = math.ceil(exp_earned * split_percent)
            self:GivePlayerExp(player_exp_earned, ExpType.Combat, steam_id, exp_data, player)

            Events:Fire("Discord", {
                channel = "Experience",
                content = string.format("%s [%s] destroyed a level %d drone and gained %d exp.", 
                    player:GetName(), steam_id, args.drone_level, player_exp_earned)
            })
        end

    end

end

function sExp:ItemExplode(args)

    if args.no_detonation_source then return end

    if args.detonation_source_id then
        -- Use ID to give exp
        args.player = self.players[args.detonation_source_id]
    end

    -- Check owner id for friend or self
    if not args.owner_id then return end

    if args.exp_enabled ~= nil then
        if not args.exp_enabled then return end
    end

    if not IsValid(args.player) then return end
    if args.owner_id == tostring(args.player:GetSteamId()) then return end

    if IsAFriend(args.player, args.owner_id) then return end

    local exp_earned = Exp.DestroyExplosive[args.type]

    if not exp_earned then return end

    local exp_data = args.player:GetValue("Exp")

    if not exp_data then return end

    self:GivePlayerExp(exp_earned, ExpType.Combat, tostring(args.player:GetSteamId()), exp_data, args.player)

    Events:Fire("Discord", {
        channel = "Experience",
        content = string.format("%s [%s] destroyed an explosive [Type: %s] and gained %d exp.", 
            args.player:GetName(), tostring(args.player:GetSteamId()), DamageEntityNames[args.type], exp_earned)
    })

end

function sExp:DestroyStash(args)

    local exp_earned = Exp.DestroyStash[args.tier]

    if not exp_earned then return end

    local exp_data = args.player:GetValue("Exp")

    if not exp_data then return end

    self:GivePlayerExp(exp_earned, ExpType.Combat, tostring(args.player:GetSteamId()), exp_data, args.player)

    Events:Fire("Discord", {
        channel = "Experience",
        content = string.format("%s [%s] destroyed a stash [Tier: %d] and gained %d exp.", 
            args.player:GetName(), tostring(args.player:GetSteamId()), args.tier, exp_earned)
    })
    
end

-- Called when a player hacks something
function sExp:HackComplete(args)

    local exp_earned = Exp.Hack[args.tier]

    if not exp_earned then return end

    local exp_data = args.player:GetValue("Exp")

    if not exp_data then return end

    self:GivePlayerExp(exp_earned, ExpType.Combat, tostring(args.player:GetSteamId()), exp_data, args.player)

    Events:Fire("Discord", {
        channel = "Experience",
        content = string.format("%s [%s] hacked a stash [Tier: %d] and gained %d exp.", 
            args.player:GetName(), tostring(args.player:GetSteamId()), args.tier, exp_earned)
    })
    
end

function sExp:ModulesLoad()
    for p in Server:GetPlayers() do
        if p:GetValue("Exp") then
            Events:Fire("PlayerExpLoaded", {player = p})
        end
    end
end

function sExp:PlayerKilled(args)

    local sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()

    if args.player:GetPosition():Distance(sz_config.neutralzone.position) < sz_config.neutralzone.radius
    and args.player:GetValue("Exp").level > 3 then return end

    -- Give killer exp
    if args.killer then
        self:AwardExpToKillerOnKill(args)
    end
    
    -- No exp lost if using Second Life
    if args.player:GetValue("SecondLifeEquipped") then return end

    -- Subtract exp from player who died
    local exp_data = args.player:GetValue("Exp")
    if not exp_data then return end
    
    local exp_lost = GetExpLostOnDeath(exp_data.level)
    exp_data.combat_exp = math.max(0, exp_data.combat_exp - exp_lost)
    exp_data.explore_exp = math.max(0, exp_data.explore_exp - exp_lost)

    args.player:SetNetworkValue("Exp", exp_data)
    self:UpdateDB(tostring(args.player:GetSteamId()), exp_data)

    Events:Fire("Discord", {
        channel = "Experience",
        content = string.format("%s [%s] was killed and lost %d exp.", args.player:GetName(), tostring(args.player:GetSteamId()), exp_lost)
    })
    
end

function sExp:AwardExpToKillerOnKill(args)

    if AreFriends(args.player, args.killer) then return end

    local player_id = tostring(args.player:GetSteamId())
    local killer_id = args.killer

    if player_id == killer_id then return end

    local exp_earned = Exp.Kill[args.reason]

    if not exp_earned or exp_earned == 0 then return end

    if args.player:GetValue("RespawnerLastSet") and 
    Server:GetElapsedSeconds() - args.player:GetValue("RespawnerLastSet") < 60 * 60 then return end

    local recent_unfriends = args.player:GetValue("RecentUnfriends")

    if recent_unfriends[args.killer] then 
        if Server:GetElapsedSeconds() - recent_unfriends[args.killer] < Exp.UnfriendTime then return end
        recent_unfriends[args.killer] = nil
        args.player:SetValue("RecentUnfriends", recent_unfriends)
    end


    local killed_exp = args.player:GetValue("Exp")
    
    local expire_time = self.recent_killers[player_id]

    if expire_time then
        -- If they have been killed recently, check the time
        local diff = Server:GetElapsedSeconds() - expire_time

        if diff > Exp.KillExpireTime then
            self.recent_killers[player_id] = nil
        else
            exp_earned = 0
        end
    end

    if not self.recent_killers[player_id] then
        self.recent_killers[player_id] = Server:GetElapsedSeconds()
    end

    if exp_earned == 0 then return end

    local killer = self.players[killer_id]

    if IsValid(killer) then

        if killer:GetValue("RespawnerLastSet") and 
        Server:GetElapsedSeconds() - killer:GetValue("RespawnerLastSet") < 60 * 60 then return end

    end


    local killer_exp = {}

    if IsValid(killer) then
        -- Killer is online; add exp and set net val
        killer_exp = killer:GetValue("Exp")
    else
        -- Killer is offline; lookup in db to get level difference and update db
        
        local query = SQL:Query("SELECT * FROM exp WHERE steamID = (?) LIMIT 1")
        query:Bind(1, killer_id)
        
        local result = query:Execute()

        if #result > 0 then -- if already in DB
            
            killer_exp.level = tonumber(result[1].level)
            killer_exp.combat_exp = tonumber(result[1].combat_exp)
            killer_exp.explore_exp = tonumber(result[1].explore_exp)
            killer_exp.explore_max_exp = GetMaximumExp(killer_exp.level)
            killer_exp.combat_max_exp = GetMaximumExp(killer_exp.level)

        end

    end

    if killer_exp and count_table(killer_exp) > 0 and killed_exp then

        local exp_earned = math.ceil(exp_earned * GetKillLevelModifier(killer_exp.level, killed_exp.level))
        self:GivePlayerExp(exp_earned, ExpType.Combat, killer_id, killer_exp, killer)

        Events:Fire("Discord", {
            channel = "Experience",
            content = string.format("[%s] [Level %d] killed %s [%s] [Level %d] and gained %d exp.", 
                killer_id, killer_exp.level, args.player:GetName(), player_id, killed_exp.level, exp_earned * self.global_multiplier)
        })
        
    end

end

function sExp:PlayerChat(args)

    if not IsAdmin(args.player) then return end

    local words = args.text:split(" ")
    
    if words[1] ~= "/expe" and words[1] ~= "/expc" and words[1] ~= "/expmod" then return end

    if not words[2] or (not words[3] and words[1] ~= "/expmod") then
        Chat:Send(args.player, "Invalid arguments specified!", Color.Red)
        return
    end

    if words[1] == "/expe" then
        local target_id = tonumber(words[2])
        local target_amount = math.max(0, tonumber(words[3] or "0"))

        local target_player = Player.GetById(target_id)
        if not IsValid(target_player) then
            Chat:Send(args.player, "Player not found!", Color.Red)
            return
        end

        self:GivePlayerExp(target_amount, ExpType.Exploration, tostring(target_player:GetSteamId()), target_player:GetValue("Exp"), target_player)
        Chat:Send(args.player, string.format("Gave %s %d exploration exp.", target_player:GetName(), target_amount), Color.Yellow)
        Chat:Send(target_player, string.format("Received %d exploration exp!", target_amount), Color.Yellow)
        
        Events:Fire("Discord", {
            channel = "Experience",
            content = string.format("%s [%s] gave %d exploration exp to %s [%s].", 
                args.player:GetName(), tostring(args.player:GetSteamId()), target_amount, target_player:GetName(), tostring(target_player:GetSteamId()))
        })
    
    elseif words[1] == "/expc" then
        local target_id = tonumber(words[2])
        local target_amount = math.max(0, tonumber(words[3] or "0"))

        local target_player = Player.GetById(target_id)
        if not IsValid(target_player) then
            Chat:Send(args.player, "Player not found!", Color.Red)
            return
        end

        self:GivePlayerExp(target_amount, ExpType.Combat, tostring(target_player:GetSteamId()), target_player:GetValue("Exp"), target_player)
        Chat:Send(args.player, string.format("Gave %s %d combat exp.", target_player:GetName(), target_amount), Color.Yellow)
        Chat:Send(target_player, string.format("Received %d combat exp!", target_amount), Color.Yellow)
        
        Events:Fire("Discord", {
            channel = "Experience",
            content = string.format("%s [%s] gave %d combat exp to %s [%s].", 
                args.player:GetName(), tostring(args.player:GetSteamId()), target_amount, target_player:GetName(), tostring(target_player:GetSteamId()))
        })
    
    elseif words[1] == "/expmod" and words[2] then
        self.global_multiplier = tonumber(words[2])
        Chat:Broadcast(string.format("Global EXP multiplier set to %.2f!", self.global_multiplier), Color(0, 255, 0))
        
        Events:Fire("Discord", {
            channel = "Experience",
            content = string.format("%s [%s] activated a global exp multiplier of %.2f.", 
                args.player:GetName(), tostring(args.player:GetSteamId()), self.global_multiplier)
        })
    
    end

end

function sExp:PlayerOpenLootbox(args)

    if args.has_been_opened then return end

    local exp_earned = Exp.Lootbox[args.tier]
    if not exp_earned then return end

    self:GivePlayerExp(exp_earned, ExpType.Exploration, tostring(args.player:GetSteamId()), args.player:GetValue("Exp"), args.player)

    Events:Fire("Discord", {
        channel = "Experience",
        content = string.format("%s [%s] opened a tier %d lootbox and gained %d exp.", 
            args.player:GetName(), tostring(args.player:GetSteamId()), args.tier, exp_earned * self.global_multiplier)
    })
    
end

function sExp:GivePlayerExp(exp, type, steamID, exp_data, player)

    if not exp_data then return end
    if exp <= 0 then return end

    exp = math.ceil(exp * self.global_multiplier)

    if type == ExpType.Combat then

        exp_data.combat_exp = math.min(exp_data.combat_exp + exp, exp_data.combat_max_exp)

    elseif type == ExpType.Exploration then

        exp_data.explore_exp = math.min(exp_data.explore_exp + exp, exp_data.explore_max_exp)

    end

    local gained_level = false

    if exp_data.combat_exp == exp_data.combat_max_exp
    and exp_data.explore_exp == exp_data.explore_max_exp
    and exp_data.level < Exp.Max_Level then
        exp_data = self:PlayerGainLevel(exp_data)

        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = steamID,
            message = string.format("Level up! You are now level %d!", exp_data.level),
            color = Color.Yellow
        })

        Events:Fire("Discord", {
            channel = "Experience",
            content = string.format("[%s] gained a new level! They are now level %d.", steamID, exp_data.level)
        })

        if IsValid(player) then
            Chat:Broadcast("[BROADCAST] ", Color.Red, string.format("%s is now level %d!", player:GetName(), exp_data.level), Color.Yellow)
        end
        
        gained_level = true

        self:UpdateDB(steamID, exp_data)

        if not IsValid(player) then
            sPerks:OfflinePlayerGainedLevel(steamID, exp_data.level)
        end
    end

    if IsValid(player) then
        player:SetNetworkValue("Exp", exp_data)
        Events:Fire("PlayerExpUpdated", {player = player})

        if gained_level then
            Events:Fire("PlayerLevelUpdated", {player = player})
        end

        local last_update = player:GetValue("ExpLastUpdate")

        if Server:GetElapsedSeconds() - last_update > 60 then
            self:UpdateDB(steamID, exp_data)
            player:SetValue("ExpLastUpdate", Server:GetElapsedSeconds())
        end
    else
        self:UpdateDB(steamID, exp_data)
    end

end

function sExp:PlayerGainLevel(exp_data)

    exp_data.level = math.min(exp_data.level + 1, Exp.Max_Level)
    exp_data.combat_exp = 0
    exp_data.explore_exp = 0
    exp_data.combat_max_exp = GetMaximumExp(exp_data.level)
    exp_data.explore_max_exp = GetMaximumExp(exp_data.level)

    return exp_data

end

function sExp:UpdateDB(steamID, exp_data)
    
    local update = SQL:Command("UPDATE exp SET level = ?, combat_exp = ?, explore_exp = ? WHERE steamID = (?)")
	update:Bind(1, exp_data.level)
	update:Bind(2, exp_data.combat_exp)
	update:Bind(3, exp_data.explore_exp)
	update:Bind(4, steamID)
    update:Execute()
    
end

function sExp:ClientModuleLoad(args)

    local steamID = tostring(args.player:GetSteamId())
    self.players[steamID] = args.player
    
	local query = SQL:Query("SELECT * FROM exp WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()

    local exp_data = {}
    
    if #result > 0 then -- if already in DB
        
        exp_data.level = tonumber(result[1].level)
        exp_data.combat_exp = tonumber(result[1].combat_exp)
        exp_data.explore_exp = tonumber(result[1].explore_exp)

    else
        
		local command = SQL:Command("INSERT INTO exp (steamID, level, combat_exp, explore_exp) VALUES (?, ?, ?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, Exp.Starting_Level)
		command:Bind(3, 0)
		command:Bind(4, 0)
        command:Execute()

        exp_data.level = Exp.Starting_Level
        exp_data.combat_exp = 0
        exp_data.explore_exp = 0

    end
    
    exp_data.combat_max_exp = GetMaximumExp(exp_data.level) -- TODO: divide by two
    exp_data.explore_max_exp = GetMaximumExp(exp_data.level)

    args.player:SetNetworkValue("Exp", exp_data)
    Events:Fire("PlayerExpLoaded", {player = args.player})

    args.source = "exp"
    Events:Fire("LoadFlowAdd", args)

    if self.global_multiplier > 1 then
        Chat:Send(args.player, string.format("Global EXP multiplier is currently set to %.2f!", self.global_multiplier), Color(0, 255, 0))
    end

    args.player:SetValue("ExpLastUpdate", Server:GetElapsedSeconds())

    -- Call sPerks after loading exp
    sPerks:ClientModuleLoad(args)

end

sExp = sExp()