class 'sSettings'

function sSettings:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS settings (steamID VARCHAR UNIQUE, data BLOB)")

    Network:Subscribe("RequestUpdate", self, self.RequestUpdate)
    Network:Subscribe("ModifySetting", self, self.ModifySetting)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)

end

-- Player reloads a module, so send them data
function sSettings:RequestUpdate(args, player)
    self:SyncToPlayer(player) 
end

function sSettings:ModifySetting(args, player)

end

function sSettings:ClientModuleLoad(args)

    local steamID = tostring(args.player:GetSteamId().id)
    
	local query = SQL:Query("SELECT * FROM settings WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        player:SetValue("SettingsData", self:Deserialize(result[1].data))
    else
        
        local default_data = self:GenerateDefaultData()
		local command = SQL:Command("INSERT INTO settings (steamID, data) VALUES (?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, self:Serialize(default_data))
        command:Execute()

        player:SetValue("SettingsData", default_data)
        
    end
    
    self:SyncToPlayer(player)

end

function sSettings:SyncToPlayer(player)
    Network:Send(player, "SettingsUpdate", player:GetValue("SettingsData"))
end

function sSettings:GenerateDefaultData()
    local data = {}

    for k, setting_data in pairs(config.settings) do
        data[setting_data.name] = setting_data.default
    end

    return data
end

function sSettings:Serialize(data)

    local d = ""

    for k,v in pairs(data) do
        d = d .. "," .. tostring(k) .. ">" .. tostring(v)
    end

    return d

end

function sSettings:Deserialize(data)

    local data = {}
    local split1 = data:split(",")

    for _, entry_data in pairs(split1) do
        local entry = entry_data:split(">")
        data[entry[1]] = entry[2]
    end

    return data

end

--sSettings()