class 'sModelChanger'

function sModelChanger:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS models (steamID VARCHAR UNIQUE, model INTEGER)")

    self.default_model = 24

    Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
    Network:Subscribe("ChangeModel", self, self.ChangeModel)

end

function sModelChanger:PlayerJoin(args)

    local steamID = tostring(args.player:GetSteamId())
	local query = SQL:Query("SELECT model FROM models WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        
        args.player:SetModelId(tonumber(result[1].model))
        
    else
        
		local command = SQL:Command("INSERT INTO models (steamID, model) VALUES (?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, self.default_model)
        command:Execute()
        
        args.player:SetModelId(self.default_model)
	end



end

function sModelChanger:ChangeModel(args, player)

    if not args.name or not args.index then return end
    if not ModelLocations[args.name] or not ModelLocations[args.name].models[args.index] then return end

    if player:GetPosition():Distance(ModelLocations[args.name].pos) > 5 then return end

    local model = ModelLocations[args.name].models[args.index].id
    player:SetModelId(model)
    
    local steamID = tostring(player:GetSteamId())
    local update = SQL:Command("UPDATE models SET model = ? WHERE steamID = (?)")
	update:Bind(1, player:GetModelId())
	update:Bind(2, steamID)
	update:Execute()

end

sModelChanger = sModelChanger()