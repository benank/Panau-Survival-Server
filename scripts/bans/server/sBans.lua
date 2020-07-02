class 'sBans'

function sBans:__init()

    Events:Subscribe("DiscordBan", self, self.DiscordBan)
    Events:Subscribe("DiscordUnBan", self, self.DiscordUnBan)
    Events:Subscribe("KickPlayer", self, self.KickPlayer)
    Events:Subscribe("BanPlayer", self, self.BanPlayer)
end

function sBans:DiscordUnBan(args)

    args.steam_id = tostring(args.steam_id)
    assert(type(args.steam_id) == "string" and args.steam_id:len() > 0, "Invalid ban steam id specified")
    
    Server:RemoveBan(SteamId(args.steam_id))

    local msg = string.format("%s unbanned.", args.steam_id)

    print(msg)
    Events:Fire("Discord", {
        channel = "Bans",
        content = msg
    })

end

function sBans:DiscordBan(args)
    args.steam_id = tostring(args.steam_id)
    assert(type(args.steam_id) == "string" and args.steam_id:len() > 0, "Invalid ban steam id specified")
    assert(type(args.reason) == "string" and args.reason:len() > 0, "Invalid player ban reason specified")
    
    local msg = string.format("%s %s banned for \"%s\"", self:GetTimeAndDate(), args.steam_id, args.reason)

    print(msg)
    Events:Fire("Discord", {
        channel = "Bans",
        content = msg
    })

    for p in Server:GetPlayers() do
        if tostring(p:GetSteamId()) == args.steam_id then
            p:Ban("Banned")
            return
        end
    end

    Server:AddBan(SteamId(args.steam_id))

end

function sBans:KickPlayer(args)

    assert(type(args.reason) == "string" and args.reason:len() > 0, "Invalid kick reason specified")
    assert(type(args.p_reason) == "string" and args.p_reason:len() > 0, "Invalid player kick reason specified")
    assert(IsValid(args.player), "Invalid player specified")

    local msg = string.format("%s %s kicked for %s\n", self:GetTimeAndDate(), self:GetPlayerInfo(args.player), args.reason)

    print(args.player:GetName() .. " kicked for: " .. args.reason)
    args.player:Kick(args.p_reason)

    print(msg)
    Events:Fire("Discord", {
        channel = "Bans",
        content = msg
    })
end

function sBans:BanPlayer(args)

    assert(type(args.reason) == "string" and args.reason:len() > 0, "Invalid ban reason specified")
    assert(type(args.p_reason) == "string" and args.p_reason:len() > 0, "Invalid player ban reason specified")
    assert(IsValid(args.player), "Invalid player specified")

    local msg = string.format("%s %s banned for %s", self:GetTimeAndDate(), self:GetPlayerInfo(args.player), args.reason)

    print(args.player:GetName() .. " banned for: " .. args.reason)
    args.player:Ban(args.p_reason)

    print(msg)
    Events:Fire("Discord", {
        channel = "Bans",
        content = msg
    })
end

function sBans:GetPlayerInfo(player)
    if IsValid(player) then
        return string.format("[%s %s %s]", 
            tostring(player:GetSteamId()), tostring(player:GetIP()), tostring(player:GetName()))
    end
end

function sBans:GetTimeAndDate()
    
	local timeTable = os.date("*t", os.time())
    
	return string.format("[%s-%s-%s %s:%s:%s] ",
        timeTable.year, timeTable.month, timeTable.day, timeTable.hour, timeTable.min, timeTable.sec)
                                
end

sBans = sBans()