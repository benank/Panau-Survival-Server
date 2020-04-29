class 'sBans'

function sBans:__init()

    Events:Subscribe("KickPlayer", self, self.KickPlayer)
    Events:Subscribe("BanPlayer", self, self.BanPlayer)
end

function sBans:KickPlayer(args)

    assert(type(args.reason) == "string" and args.reason:len() > 0, "Invalid kick reason specified")
    assert(type(args.p_reason) == "string" and args.p_reason:len() > 0, "Invalid player kick reason specified")
    assert(IsValid(args.player), "Invalid player specified")

    local file = assert(io.open("kicks.txt", "a+"), "Failed to open file")
    local msg = string.format("%s %s kicked for %s\n", self:GetTimeAndDate(), self:GetPlayerInfo(args.player), args.reason)
    file:write(msg)
    file:close()

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

    local file = assert(io.open("bans.txt", "a+"), "Failed to open file")
    local msg = string.format("%s %s banned for %s", self:GetTimeAndDate(), self:GetPlayerInfo(args.player), args.reason)
    file:write(msg)
    file:close()

    print(args.player:GetName() .. " banned for: " .. args.reason)
    args.player:Ban(args.p_reason)

    print(msg)
    Events:Fire("Discord", {
        channel = "Bans",
        content = msg
    })
end

function sBans:GetPlayerInfo(player)
    return string.format("[%s %s %s]", 
        tostring(player:GetSteamId()), tostring(player:GetIP()), tostring(player:GetName()))
end

function sBans:GetTimeAndDate()
    
	local timeTable = os.date("*t", os.time())
    
	return string.format("[%s-%s-%s %s:%s:%s] ",
        timeTable.year, timeTable.month, timeTable.day, timeTable.hour, timeTable.min, timeTable.sec)
                                
end

sBans = sBans()