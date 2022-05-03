class 'SAMManager'

function SAMManager:__init()
	
	SQL:Execute("CREATE TABLE IF NOT EXISTS hacked_sams (steamID VARCHAR, sam_id INTEGER)")
	
	self.sams = {}
	self.cell_size = 512
	self.players = {}
	
	self.scan_timer = Timer()
	
    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(self.cell_size), self, self.PlayerCellUpdate)
	Network:Subscribe("sams/MissileStrikeDamagePlayer", self, self.MissileStrikeDamagePlayer)
	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
	Events:Subscribe("PostTick", self, self.PostTick)
	
	Network:Subscribe("sams/SplashHitSAM", self, self.SplashHitSAM)
	Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
	Events:Subscribe("sams/GetSAMInfo", self, self.GetSAMInfo)
	Events:Subscribe("sams/GetAllSAMs", self, self.GetAllSAMs)
	Events:Subscribe("items/SAMHackComplete", self, self.SAMHackComplete)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function SAMManager:GetAllSAMs()
	local sams = {}
	for id, sam in ipairs(self.sams) do
		sams[id] = sam:GetSyncData()
	end
	Events:Fire("sams/AllSAMs", sams)
end

function SAMManager:ModuleUnload()
    Events:Fire("Drones/RemoveDronesInGroup", {group = "sam"})
end

function SAMManager:SAMHackComplete(args)
	local sam = self.sams[args.sam_id]
	if not sam then return end
	sam:Hacked(args.player)
end

function SAMManager:GetSAMInfo(args)
	local data = {}
	
	if self.sams[args.id] then
		data = self.sams[args.id]:GetSyncData()
	end
	
	Events:Fire("sams/GetSAMInfo_" .. tostring(args.id), data)
end

function SAMManager:ClientModuleLoad(args)
    self.players[tostring(args.player:GetSteamId())] = args.player
end

function SAMManager:PlayerQuit(args)
    self.players[tostring(args.player:GetSteamId())] = nil
end

function SAMManager:ItemExplode(args)
	local damage = SAMDamageSources[args.type]
	if not damage then return end
	
	Thread(function()
		local count = 0
		for id, sam in ipairs(self.sams) do
			local hit_distance = sam.position:Distance(args.position)
			local hit_damage = damage * (1 - hit_distance / args.radius)

			if hit_distance < args.radius and hit_damage > 0 then
				local player = args.detonation_source_id and self.players[args.detonation_source_id] or args.player
				sam:Damage(hit_damage, player)
				
				if IsValid(player) then
					Events:Fire("HitDetection/DealDamageIndicator", {player = player, red = sam.health <= 0})
				end
			end
			
			count = count + 1
			
			if count % 20 == 0 then
				Timer.Sleep(1)
			end
		end
	end)
end

function SAMManager:SplashHitSAM(args, player)
	if not args.sam_id then return end
	
	local sam = self.sams[args.sam_id]
	if not sam then return end
	if sam.destroyed then return end
	
	local modifier = math.clamp(1 - args.hit_position:Distance(sam.position) / args.radius, 0, 1)
	if modifier == 0 then return end
	
	local WeaponDamageSources = 
	{
		[5] = 30, -- Grenade Launcher
		[7] = 120, -- Rocket Launcher
		[13] = 100, -- Vehicle rockets
		[14] = 120, -- Vehicle cannon
		[17] = 120, -- Vehicle cannon
	}
	
	if not WeaponDamageSources[args.weapon_enum] then return end
	
	local damage = WeaponDamageSources[args.weapon_enum] * modifier
	
	sam:Damage(damage, player)
	Events:Fire("HitDetection/DealDamageIndicator", {player = player, red = sam.health <= 0})
end

function SAMManager:ModuleLoad()
	self:CreateAllSAMs()
end

function SAMManager:PostTick()
	if self.scan_timer:GetSeconds() > 1.5 then
		for id, sam in ipairs(self.sams) do
			if sam:CanFire() then
				local close_valid_players = {}
				for player in Server:GetPlayers() do
					
					if IsValid(player) then
						local player_pos = player:GetPosition()
						local player_exp = player:GetValue("Exp")
						
						if player:InVehicle() and 
						player:GetPosition().y > 220 and 
						not player:GetValue("InSafezone") and
						player_exp and player_exp.level > 10 and
						not player:GetValue("Invisible") then
							local player_vehicle = player:GetVehicle()
							local speed = math.abs(math.floor(player_vehicle:GetLinearVelocity():Length()))
							local model_id = player_vehicle:GetModelId()
							local sam_key_level = player:GetValue("SAM Key") or 0
							
							-- Get highest level SAM key in vehicle
							local occupants = player_vehicle:GetOccupants()
							for index, v_player in pairs(occupants) do
								sam_key_level = math.max(sam_key_level, v_player:GetValue("SAM Key") or 0)
							end
							
							if 
							IsValidVehicle(model_id, SAMMissileVehicles) and 
							player_vehicle:GetHealth() > 0 and 
							speed > 15 and
							not sam:IsFriendlyTowardsPlayer(player) and
							not sam:IsSAMKeyEffective(sam_key_level) and
							sam.position:Distance(player_pos) < 1024 then
								table.insert(close_valid_players, player)
							end
							
						end
						
						-- Timer.Sleep(1)
					end
				end
				
				if count_table(close_valid_players) > 0 then
					local target = random_table_value(close_valid_players)
					if IsValid(target) then
						sam:Fire(target, target:GetVehicle())
						-- Timer.Sleep(1)
					end
				end
			end
			-- Timer.Sleep(1000)
		end
		self.scan_timer:Restart()
	end
end

function SAMManager:CreateAllSAMs()
	local all_hacked_sams = self:GetAllHackedSAMsFromDB()
	
	for sam_id, sam_data in ipairs(SAMAnchorLocationsTable) do
		local sam = SAM({
			id = sam_id,
			position = sam_data.pos,
			base_level = sam_data.level,
			cell = GetCell(sam_data.pos, self.cell_size),
			hacked_owner = all_hacked_sams[sam_id]
		})
		self.sams[sam.id] = sam
	end
	print(string.format("Created %d SAMs.", count_table(self.sams)))
end

function SAMManager:GetAllHackedSAMsFromDB()
	local all_hacked_sams = {}
	local result = SQL:Query("SELECT * FROM hacked_sams"):Execute()
	
    if result and count_table(result) > 0 then
        for _, sam_data in pairs(result) do
			all_hacked_sams[tonumber(sam_data.sam_id)] = sam_data.steamID
		end
    end
	
	return all_hacked_sams
end

function SAMManager:PlayerCellUpdate(args)
	for _, adj_cell in pairs(args.adjacent) do
		for id, sam in pairs(self.sams) do
			if sam.cell.x == adj_cell.x and sam.cell.y == adj_cell.y then
				sam:Sync(args.player)
			end
		end
	end
end

function SAMManager:MissileStrikeDamagePlayer(strikeTable)
	Events:Fire("HitDetection/SAMHitPlayerVehicle", {
		player = strikeTable.player,
		vehicle = strikeTable.player:GetVehicle(),
		hit_position = strikeTable.epicenter,
		radius = strikeTable.Stats.Radius
	})
end

SAMManager = SAMManager()