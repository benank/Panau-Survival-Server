local json = require('json')

local encode, decode = json.encode, json.decode


-- change here to the host an port you want to contact
local host, port = "localhost", 1780

-- load namespace
local socket = require("socket")

-- convert host name to ip address
local ip = assert(socket.dns.toip(host))

-- create a new UDP object
local udp = assert(socket.udp())

-- contact daytime host
-- assert(udp:sendto("handshake", ip, port))
assert(udp:settimeout(0))

-- Loop to get data
Events:Subscribe("PreTick", function(args)
    local result, timeout = udp:receive()
    if result then
        receive(result)
    end
end)

function send(content)
    assert(udp:sendto(tostring(content), ip, port))
end

-- ip, port, bytes, text
function receive(text)

    if not text then return end
    data = decode(text)
    
    local message_type = tostring(data[1])
    
    if message_type == "translation" then
        print("got translation")
        print(encode(data[2]))
        Events:Fire("Translation", data[2])
    end
end

Events:Subscribe("TranslateText", function(args)
    print("TranslateText 1")
    if not args.text or not args.id then return end
    print("TranslateText 2")
    local data = encode{'message', {id = args.id, text = tostring(args.text)}}
    send(data)
    print("TranslateText sent data")
end)


SQL:Execute("CREATE TABLE IF NOT EXISTS language (steamID VARCHAR UNIQUE, locale VARCHAR(2))")
local DEFAULT_LOCALE = "en"

Events:Subscribe("ClientModuleLoad", function(args)
    
    local steamID = tostring(args.player:GetSteamId())
	local query = SQL:Query("SELECT * FROM language WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        args.player:SetNetworkValue("Locale", result[1].locale)
    else
        
		local command = SQL:Command("INSERT INTO language (steamID, locale) VALUES (?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, DEFAULT_LOCALE)
        command:Execute()

        args.player:SetNetworkValue("Locale", DEFAULT_LOCALE)
        
    end
    
    local locale = args.player:GetValue("Locale")
    if locale and locale ~= 'en' then
        local data = encode{'locale_add', tostring(args.player:GetValue("Locale"))}
        send(data)
    end
end)

Events:Subscribe("PlayerQuit", function(args)
    local locale = args.player:GetValue("Locale")
    if locale and locale ~= 'en' then
        local data = encode{'locale_remove', tostring(args.player:GetValue("Locale"))}
        send(data)
    end
end)