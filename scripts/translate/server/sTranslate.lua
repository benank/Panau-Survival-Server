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

-- Thanks Sister_Rectus for the utf8char code
-----
local str_char = string.char
local band, bor, rshift = bit32.band, bit32.bor, bit32.rshift

local function bin(str)
  return tonumber(str, 2)
end

local codec = {
  {0x00000000, 0x0000007F, bin('00000000'), bin('01111111')},
  {0x00000080, 0x000007FF, bin('11000000'), bin('00011111')},
  {0x00000800, 0x0000FFFF, bin('11100000'), bin('00001111')},
  {0x00010000, 0x0010FFFF, bin('11110000'), bin('00000111')},
}

local mask = {bin('10000000'), bin('00111111')}

local function range(n)
  for i, v in ipairs(codec) do
    if v[1] <= n and n <= v[2] then
      return i
    end
  end
  error('value out of range: ' .. n)
end

local function utf8char(n)
  local i = range(n)
  if i == 1 then
    return str_char(n)
  else
    local buf = {}
    for b = i, 2, -1 do
      local byte = band(n, mask[2])
      byte = bor(mask[1], byte)
      buf[b] = str_char(byte)
      n = rshift(n, 6)
    end
    n = bor(codec[i][3], n)
    buf[1] = str_char(n)
    return table.concat(buf)
  end
end
-------

local function unescape(s)
  s = string.gsub(s, "+", " ")
  s = string.gsub(s, "%%(%x%x)", function (h)
    return utf8char(tonumber(h, 16))
  end)
  s = string.gsub(s, "%%u(%x%x%x%x)", function (h)
    return utf8char(tonumber(h, 16))
  end)
  return s
end

-- ip, port, bytes, text
function receive(text)

    if not text then return end
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


SQL:Execute("CREATE TABLE IF NOT EXISTS language (steamID VARCHAR UNIQUE, locale VARCHAR(8))")
local DEFAULT_LOCALE = "en"

Events:Subscribe("ClientModuleLoad", function(args)
    
    local steamID = tostring(args.player:GetSteamId())
	local query = SQL:Query("SELECT * FROM language WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        args.player:SetNetworkValue("Locale", result[1].locale)
        Chat:Send(args.player, " ", Color.White)
        Chat:Send(args.player, "Language: ", Color.White, tostring(Languages[result[1].locale]), Color(45, 252, 214))
        Chat:Send(args.player, "Type ", Color.White, "/language", Color(45, 252, 214), " to change your language.", Color.White)
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
    Chat:Send(player, "Set chat language to: ", Color.White, tostring(Languages[args.locale]), Color(45, 252, 214))
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