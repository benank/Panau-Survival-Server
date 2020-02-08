class 'sOutpost'

function sOutpost:__init(name, basepos, radius, ai_spawnmaneuvers)
	self.name = name -- must be unique
	self.basepos = basepos
	self.radius = radius
	self.ai_spawnmaneuvers = ai_spawnmaneuvers
	
	self.players_inside = {}
	self.players_inside_count = 0
	
	self.action_timer = Timer()
	self.action_delay = 0 -- immediately do action .. in seconds
end

function sOutpost:Update()
	
	if self.players_inside_count > 0 then
		if self.action_timer:GetSeconds() > self.action_delay then
			--self.action_delay = math.random(60, 120) -- new wave every 1-2 mins
			self.action_timer:Restart()
			self.action_delay = 30
			self:SpawnWave()
		end
	end
	
	--print("outpost updating")
end

function sOutpost:SpawnWave() -- {helis = {}, boats = {}, planes = {}, actors = {}}
	local maneuver_to_execute = self.ai_spawnmaneuvers.helis[1]
	
	print("maneuver to execute: ")
	print(maneuver_to_execute)
end

function sOutpost:PlayerEnter(player)
	local steamid = tostring(player:GetSteamId().id)
	self.players_inside[steamid] = player
	self.players_inside_count = self.players_inside_count + 1
end

function sOutpost:PlayerExit(player) -- also gets called from PlayerQuit
	local steamid = tostring(player:GetSteamId().id)
	self.players_inside[steamid] = nil
	self.players_inside_count = self.players_inside_count - 1
end

function sOutpost:Despawn()
	
end

function sOutpost:Remove()
	
end