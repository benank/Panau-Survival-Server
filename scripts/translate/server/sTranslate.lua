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
    if not args.text or not args.id then return end
    local data = encode{'message', {id = args.id, text = tostring(args.text)}}
    send(data)
end)

Events:Subscribe("PlayerJoin", function(args)
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