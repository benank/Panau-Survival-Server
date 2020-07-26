class 'sDelayedMessages'

-- Class for handling when a we want to send a message to a player but they are not online
function sDelayedMessages:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS player_names (steam_id VARCHAR(20), name VARCHAR(100))")
    SQL:Execute("CREATE TABLE IF NOT EXISTS delayed_messages (steam_id VARCHAR(20), message VARCHAR(100), color VARCHAR(20))")

    self.players = {}

    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("PlayerJoin", self, self.PlayerJoin)

    -- Send a player with a steam_id a message even if they are not online
    Events:Subscribe("SendPlayerPersistentMessage", self, self.TryToSendToPlayer)
end

function sDelayedMessages:PlayerJoin(args)
    self.players[tostring(args.player:GetSteamId())] = args.player
    self:EnsurePlayerExistsInDB(args.player)
    self:SendPlayerStoredMessages(args.player)
end

function sDelayedMessages:ModuleLoad()

    for p in Server:GetPlayers() do
        self.players[tostring(p:GetSteamId())] = p
        self:EnsurePlayerExistsInDB(p)
    end

end

function sDelayedMessages:EnsurePlayerExistsInDB(player)

    local steam_id = tostring(player:GetSteamId())

    -- Delete old entry
    local cmd = SQL:Command("DELETE FROM player_names WHERE steam_id = (?)")
    cmd:Bind(1, steam_id)
    cmd:Execute()

    -- Add new one
    cmd = SQL:Command("INSERT INTO player_names (steam_id, name) VALUES (?, ?)")
    cmd:Bind(1, steam_id)
    cmd:Bind(2, player:GetName())
    cmd:Execute()
        
    -- TODO: add persistent names
end

function sDelayedMessages:PlayerQuit(args)
    self.players[tostring(args.player:GetSteamId())] = nil
end

function sDelayedMessages:TryToSendToPlayer(args)

    assert(args.steam_id ~= nil, "args.steam_id was invalid")
    assert(args.message ~= nil, "args.message was invalid")
    assert(args.message:len() < 200, "args.message was too long")
    
    args.color = args.color or Color.White

    local player = self.players[args.steam_id]

    if IsValid(player) then
        -- They are online, so send them the chat message
        Chat:Send(player, args.message, args.color)
    else
        -- Not online, so add it to the database
        self:Add(args)
    end

end

function sDelayedMessages:Add(args)

    local cmd = SQL:Command("INSERT INTO delayed_messages (steam_id, message, color) VALUES (?, ?, ?)")
    cmd:Bind(1, args.steam_id)
    cmd:Bind(2, tostring(args.message))
    cmd:Bind(3, tostring(args.color))
    cmd:Execute()

end

function sDelayedMessages:SendPlayerStoredMessages(player)
    
    local steam_id = tostring(player:GetSteamId())

    local result = SQL:Query("SELECT * FROM delayed_messages WHERE steam_id = (?)")
    result:Bind(1, steam_id)
    result = result:Execute()
    
    if count_table(result) > 0 then

        for _, message_data in pairs(result) do
            local color_split = message_data.color:split(",")
            message_data.color = Color(tonumber(color_split[1]), tonumber(color_split[2]), tonumber(color_split[3]), tonumber(color_split[4]))
            self:TryToSendToPlayer(message_data)
        end

    end

    -- Clear all messages from DB
    local cmd = SQL:Command("DELETE FROM delayed_messages WHERE steam_id = (?)")
    cmd:Bind(1, steam_id)
    cmd:Execute()
    
end

sDelayedMessages = sDelayedMessages()