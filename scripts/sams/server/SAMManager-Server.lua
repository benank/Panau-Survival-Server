class 'SAMManager'

class 'IdPool'

function IdPool:__init()
    self.current_id = 0
end

function IdPool:GetNextId()
    self.current_id = self.current_id + 1
    return self.current_id
end

function SAMManager:__init()
	
	self.id_pool = IdPool()
	self.sams = {}
	self.cell_size = 512
	self.players = {}
	
    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(self.cell_size), self, self.PlayerCellUpdate)
	Network:Subscribe("sams/MissileStrikeDamagePlayer", self, self.MissileStrikeDamagePlayer)
	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
	
	Network:Subscribe("sams/SplashHitSAM", self, self.SplashHitSAM)
	Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
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
		for id, sam in pairs(self.sams) do
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
	self:StartSAMMonitoring()
end

function SAMManager:StartSAMMonitoring()
	Thread(function()
		while true do
			for player in Server:GetPlayers() do
				
				local player_pos = player:GetPosition()
				
				if player:InVehicle() and player:GetPosition().y > 210 then
					local player_vehicle = player:GetVehicle()
					local speed = math.abs(math.floor(player_vehicle:GetLinearVelocity():Length()))
					
					if player_vehicle:GetHealth() > 0 and speed > 15 then
						for id, sam in pairs(self.sams) do
							if sam:CanFire() and sam.position:Distance(player_pos) < 1024 then
								sam:Fire(player, player_vehicle)
								Timer.Sleep(1)
							end
						end
					end
				end
				
				Timer.Sleep(1)
			end
			
			Timer.Sleep(1000)
		end
	end)
end

function SAMManager:CreateAllSAMs()
	for _, sam_data in pairs(SAMAnchorLocationsTable) do
		local sam = SAM({
			id = self.id_pool:GetNextId(),
			position = sam_data.pos,
			base_level = sam_data.level,
			cell = GetCell(sam_data.pos, self.cell_size)
		})
		self.sams[sam.id] = sam
	end
	print(string.format("Created %d SAMs.", count_table(self.sams)))
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