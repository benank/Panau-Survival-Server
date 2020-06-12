SQL:Execute("CREATE TABLE IF NOT EXISTS positions (steamID VARCHAR UNIQUE, x REAL, y REAL, z REAL, homeX REAL, homeY REAL, homeZ REAL)")


class 'sSpawnManager'

function sSpawnManager:__init()

	Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
	Events:Subscribe("PlayerDeath", self, self.PlayerDeath)
	Events:Subscribe("PlayerSpawn", self, self.PlayerSpawn)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("SetHomePosition", self, self.SetHomePosition)
    Events:Subscribe("PlayerChat", self, self.PlayerChat)

	Network:Subscribe("EnterExitSafezone", self, self.EnterExitSafezone)

    for p in Server:GetPlayers() do
        if not p:GetValue("Loading") then
            p:SetValue("FirstSpawn", true)
        end
    end

	Timer.SetInterval(1000 * 30, function()
		
		local seconds = Server:GetElapsedSeconds()

        for player in Server:GetPlayers() do
			if IsValid(player) then
				
				local last_update = player:GetValue("SpawnLastUpdate")

				if last_update and seconds - last_update >= 60 then
					self:UpdatePlayerPositionMinuteTick(player)
					player:SetValue("SpawnLastUpdate", seconds)
				end

            end
        end
    end)

end

function sSpawnManager:PlayerChat(args)

    if args.text == "/unsethome" then
        self:SetHomePosition({
            player = args.player,
            pos = self:GetPositionInSafezone()
        })
        Chat:Send(args.player, "Set spawn point to the safezone.", Color.Yellow)
    end

end

function sSpawnManager:SetHomePosition(args)

    local steamid = tostring(args.player:GetSteamId().id)

	local command = SQL:Command("UPDATE positions SET homeX = ?, homeY = ?, homeZ = ? WHERE steamID = (?)")
	command:Bind(1, args.pos.x)
	command:Bind(2, args.pos.y)
	command:Bind(3, args.pos.z)
	command:Bind(4, steamid)
    command:Execute()
    
    args.player:SetNetworkValue("HomePosition", args.pos)

end

function sSpawnManager:ModuleUnload()
    for p in Server:GetPlayers() do
        self:UpdatePlayer(p)
    end
end

function sSpawnManager:EnterExitSafezone(args, player)
	local in_sz = args.in_sz and player:GetPosition():Distance(config.safezone.position) < config.safezone.radius * 1.25
    player:SetNetworkValue("InSafezone", in_sz)

	Events:Fire("EnterExitSafezone", {player = player, in_sz = in_sz})

	-- Disable vehicle and player collisions while in safezone
	if in_sz then
		player:DisableCollision(CollisionGroup.Player, CollisionGroup.Vehicle)
		player:DisableCollision(CollisionGroup.Vehicle, CollisionGroup.Player)
		player:DisableCollision(CollisionGroup.Player, CollisionGroup.Player)
        player:DisableCollision(CollisionGroup.Vehicle, CollisionGroup.Vehicle)
        
	else
		player:EnableCollision(CollisionGroup.Player, CollisionGroup.Vehicle)
		player:EnableCollision(CollisionGroup.Vehicle, CollisionGroup.Player)
		player:EnableCollision(CollisionGroup.Vehicle, CollisionGroup.Vehicle)
		player:EnableCollision(CollisionGroup.Player, CollisionGroup.Player)
    end

end

function sSpawnManager:UpdatePlayerPositionMinuteTick(player)

	self:UpdatePlayer(player)

end

function sSpawnManager:PlayerQuit(args)

    Events:Fire("Discord", {
        channel = "Chat",
        content = string.format("*%s [%s] left the server.*", args.player:GetName(), args.player:GetSteamId())
    })

    self:UpdatePlayer(args.player)

end

function sSpawnManager:UpdatePlayer(player)

    if not IsValid(player) then return end
	if player:GetValue("IsOkToSavePosition") ~= 0 then return end
	if player:GetValue("Loading") and not player:GetValue("dead") then return end

	local pos = player:GetPosition()
	local steamid = tostring(player:GetSteamId().id)

	if player:GetHealth() <= 0 or player:GetValue("Spawn/KilledRecently") or not player:GetEnabled() 
		or (player:GetValue("dead")) then
		pos = self:GetRespawnPosition(player)
	end

	local command = SQL:Command("UPDATE positions SET x = ?, y = ?, z = ? WHERE steamID = (?)")
	command:Bind(1, pos.x)
	command:Bind(2, pos.y)
	command:Bind(3, pos.z)
	command:Bind(4, steamid)
	command:Execute()

end

function sSpawnManager:PlayerJoin(args)

    local steamid = tostring(args.player:GetSteamId().id)
    args.player:SetValue("FirstSpawn", false)

	local qry = SQL:Query("SELECT steamID FROM positions WHERE steamID = (?) LIMIT 1")
	qry:Bind(1, steamid)
	local result = qry:Execute()

	if #result > 0 then
		local qry = SQL:Query("SELECT x, y, z, homeX, homeY, homeZ FROM positions WHERE steamID = (?) LIMIT 1")
		qry:Bind(1, steamid)
		local postable = qry:Execute()
		local plypos = Vector3(tonumber(postable[1].x), tonumber(postable[1].y), tonumber(postable[1].z))

		local home = Vector3(tonumber(postable[1].homeX),tonumber(postable[1].homeY),tonumber(postable[1].homeZ))

		if home.x ~= 0 and home.y ~= 0 and home.z ~= 0 then
			args.player:SetNetworkValue("HomePosition", home)
		end
			
		args.player:SetValue("IsOkToSavePosition", 1)

		self:DelayedSpawn({position = plypos, player = args.player, timeout = 5})
		args.player:SetValue("SpawnPosition", plypos)
		args.player:SetValue("RespawnPosition", self:GetRespawnPosition(args.player))

	else -- if first join
		
		local spawn_pos = self:GetRespawnPosition(args.player)

		args.player:SetValue("IsOkToSavePosition", 1)
		args.player:SetValue("RespawnPosition", spawn_pos)
		args.player:SetValue("SpawnPosition", spawn_pos)
		self:DelayedSpawn({position = spawn_pos, player = args.player, timeout = 5})

		local command = SQL:Command("INSERT INTO positions (steamID, x, y, z, homeX, homeY, homeZ) VALUES (?, ?, ?, ?, ?, ?, ?)")
		command:Bind(1, steamid)
		command:Bind(2, spawn_pos.x)
		command:Bind(3, spawn_pos.y)
		command:Bind(4, spawn_pos.z)
		command:Bind(5, 0)
		command:Bind(6, 0)
		command:Bind(7, 0)
		command:Execute()
    end
    
    Events:Fire("Discord", {
        channel = "Chat",
        content = string.format("*%s [%s] joined the server.*", args.player:GetName(), args.player:GetSteamId())
	})
	
	args.player:SetValue("SpawnLastUpdate", Server:GetElapsedSeconds())

end

-- Gets the position where a player should respawn when they die. Returns safezone if they do not have a bed set.
function sSpawnManager:GetRespawnPosition(player)
	return player:GetValue("HomePosition") and player:GetValue("HomePosition") or self:GetPositionInSafezone()
end

function sSpawnManager:GetPositionInSafezone()

	return config.safezone.position + 
		Vector3(
			randy(-15, 15, os.time() + math.random()), 
			0, 
			randy(-15, 15, os.time() + math.random()))

end

function sSpawnManager:DelayedSpawn(args)

	Timer.SetTimeout(args.timeout, function()
		if IsValid(args.player) and args.position then
			args.player:SetPosition(args.position)
			args.player:SetValue("IsOkToSavePosition", args.player:GetValue("IsOkToSavePosition") - 1)
		end
	end)

end

function sSpawnManager:PlayerSpawn(args)
    args.player:SetValue("Spawn/KilledRecently", false)
    
    if args.player:GetValue("SecondLifeActive") then return end

    if args.player:GetValue("FirstSpawn") then
        args.player:SetPosition(self:GetRespawnPosition(args.player))
    else
        args.player:SetPosition(args.player:GetValue("SpawnPosition"))
    end

    args.player:SetValue("FirstSpawn", true)
    args.player:SetHealth(1)

	return false
end

function sSpawnManager:PlayerDeath(args)
	args.player:SetValue("Spawn/KilledRecently", true)
end

sSpawnManager = sSpawnManager()
