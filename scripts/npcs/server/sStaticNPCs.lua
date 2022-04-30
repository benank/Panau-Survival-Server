class 'sStaticNPCs'

function sStaticNPCs:__init()
    
    self.spawn_origin = Vector3(-10294, 206.164, -3019)
    self.spawn_radius = 70
    self.num_npcs = 5
    
    -- Table of static NPCs queried from DB
    self.static_npcs = {}
    
    self.npc_change_interval = 1000 * 60 * 60 * 24 -- Change NPCs every 24 hours
    Timer.SetInterval(self.npc_change_interval, function()
        self:RefreshNPCs()
    end)
    
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
end

function sStaticNPCs:ClientModuleLoad(args)
    Network:Send(args.player, "NPC/static/sync", self.static_npcs)
end

function sStaticNPCs:ModuleLoad()
    self:RefreshNPCs()
end

function sStaticNPCs:RefreshNPCs()
    self.num_npcs = math.random(10, 15)
    self.static_npcs = self:GetRandomPlayersFromDB(self.num_npcs) or {}
    Network:Broadcast("NPC/static/sync", self.static_npcs)
end

function sStaticNPCs:GetRandomNPCPosition()
    local direction = Vector3(math.random() - 0.5, 0, math.random() - 0.5)
    return self.spawn_origin + direction * self.spawn_radius
end

function sStaticNPCs:GetRandomPlayersFromDB(num_players)
    local cmd = "SELECT * FROM player_data "..
        "LEFT OUTER JOIN player_names on player_names.steam_id=player_data.steamID "..
        "LEFT OUTER JOIN models on models.steamID=player_data.steamID "..
        "LEFT OUTER JOIN exp on exp.steamID=player_data.steamID "..
        "WHERE time_online > 60 "..
        "ORDER BY random() LIMIT ?"
    
	local query = SQL:Query(cmd)
    query:Bind(1, num_players or 10)
    local result = query:Execute()

    local return_data = {}
    
    for _, player_data in pairs(result) do
        return_data[_] = {
            -- nametag = {name = "NPC", color = Color(239, 123, 40)},
            name = "[NPC] " .. player_data.name,
            model_id = tonumber(player_data.model),
            level = tonumber(player_data.level),
            position = self:GetRandomNPCPosition(),
            health = 1,
            max_health = 1
        }
    end
    
    table.insert(return_data, {
        name = "[NPC] Bolo",
        model_id = 90,
        level = 500,
        position = self:GetRandomNPCPosition(),
        health = 1,
        max_health = 1
    })
    
    table.insert(return_data, {
        name = "[NPC] Rico",
        model_id = 51,
        level = 500,
        position = self:GetRandomNPCPosition(),
        health = 1,
        max_health = 1
    })
    
    return return_data
end

sStaticNPCs()