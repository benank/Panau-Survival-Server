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

-- https://www.lua.org/pil/20.3.html
function unescape(s)
    s = string.gsub(s, "+", " ")
    s = string.gsub(s, "%%(%x%x)", function (h)
          return string.char(tonumber(h, 16))
        end)
    s = string.gsub(s, "%%u(%x%x%x)", function (h)
            return string.char(tonumber(h, 16))
        end)
    s = string.gsub(s, "%%u(%x%x%x%x)", function (h)
            return string.char(tonumber(h, 16))
        end)
    return s
end

-- ip, port, bytes, text
function receive(text)

    if not text then return end
    print("receive: ")
    print(text)
    data = decode(text)
    
    local message_type = tostring(data.type)
    
    if message_type == "translation" then
        for locale, message in pairs(data.data.translations) do
            data.data.translations[locale] = unescape(message)
        end
        
        Events:Fire("Translation", data.data)
    end
end

Events:Subscribe("TranslateText", function(args)
    if not args.text or not args.id then return end
    
    local locale = args.player:GetValue("Locale") or 'en'
    local data = encode{'message', {id = args.id, origin_locale = locale, text = tostring(args.text)}}
    send(data)
end)


SQL:Execute("CREATE TABLE IF NOT EXISTS language (steamID VARCHAR UNIQUE, locale VARCHAR(5))")
local DEFAULT_LOCALE = "en"

Events:Subscribe("ClientModuleLoad", function(args)
    
    local steamID = tostring(args.player:GetSteamId())
	local query = SQL:Query("SELECT * FROM language WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        args.player:SetNetworkValue("Locale", result[1].locale)
        Chat:Send(args.player, " ", Color.White)
        Chat:Send(args.player, "Language: ", Color.White, tostring(Languages[result[1].locale]), Color(45, 193, 252))
        Chat:Send(args.player, "Type ", Color.White, "/language", Color(45, 252, 214), " to change your language.", Color.White)
        Chat:Send(args.player, " ", Color.White)
    else
        
		local command = SQL:Command("INSERT INTO language (steamID, locale) VALUES (?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, DEFAULT_LOCALE)
        command:Execute()

        args.player:SetNetworkValue("Locale", DEFAULT_LOCALE)
        Network:Send(args.player, "OpenTranslateWindow")
        
    end
    
    PlayerLocaleUpdated(nil, args.player:GetValue("Locale"))
end)

Network:Subscribe("SetLanguage", function(args, player)
    if not args.locale then return end
    if args.locale == player:GetValue("Locale") then return end
    if not Languages[args.locale] then return end
    
    PlayerLocaleUpdated(player:GetValue("Locale"), args.locale)
    
    local steamID = tostring(player:GetSteamId())
	local command = SQL:Command("UPDATE language SET locale = ? WHERE steamID = (?)")
	command:Bind(1, args.locale)
	command:Bind(2, steamID)
	command:Execute()

    player:SetNetworkValue("Locale", args.locale)
    Chat:Send(player, "Set chat language to: ", Color.White, tostring(Languages[args.locale]), Color(45, 193, 252))
end)

function PlayerLocaleUpdated(old_locale, new_locale)
    if old_locale and old_locale ~= 'en' then
        local data = encode{'locale_remove', tostring(old_locale)}
        send(data)
    end
    
    if new_locale and new_locale ~= 'en' then
        local data = encode{'locale_add', tostring(new_locale)}
        send(data)
    end
end

Events:Subscribe("PlayerQuit", function(args)
    PlayerLocaleUpdated(args.player:GetValue("Locale"))
end)

Events:Subscribe("ModuleLoad", function(args)
    local data = encode{'locale_reset', " "}
    send(data)
end)