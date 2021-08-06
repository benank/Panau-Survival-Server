class 'cBeringBombsight'

function cBeringBombsight:__init()
    
    self.bering_id = 85
	self.min_height_diff = 100
	self.max_height_diff = 1500
	self.radius = 150
	self.can_fire = false
	self.on_cooldown = false
	self.center = Vector3(0,0,0)
    
    Events:Subscribe("LocalPlayerEnterVehicle", self, self.LocalPlayerEnterVehicle)
    Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)
    Events:Subscribe("LocalPlayerDeath", self, self.LocalPlayerDeath)
	
	Events:Subscribe("HitDetection/FireBeringBombsight", self, self.FireBeringBombsight)
end

function cBeringBombsight:FireBeringBombsight(args)
	self.on_cooldown = true
	Timer.SetTimeout(args.cooldown * 1000, function()
		self.on_cooldown = false
	end)
	
	Network:Send(var("Vehicles/FireBeringBombsight"):get(), {
		center = self.center
	})
end

function cBeringBombsight:Activate()
	self.can_fire = false
	Events:Fire("Vehicles/CanFireBeringBombsight", {
		can_fire = self.can_fire
	})
    self.render = Events:Subscribe("GameRender", self, self.GameRender)
end

function cBeringBombsight:Deactivate()
    if self.render then
        self.render = Events:Unsubscribe(self.render)
    end 
end

function cBeringBombsight:LocalPlayerEnterVehicle(args)
    if args.vehicle:GetModelId() ~= self.bering_id then return end
    
    self:Activate()
end

function cBeringBombsight:LocalPlayerExitVehicle(args)
    self:Deactivate()
end

function cBeringBombsight:LocalPlayerDeath(args)
    self:Deactivate() 
end

function cBeringBombsight:GameRender(args)
    if not LocalPlayer:InVehicle() then return end
	
	if self.on_cooldown then return end
    
	local vehicle = LocalPlayer:GetVehicle()
    local model, model_fill = self:CreateModels(vehicle, self.radius)
	
	local old_can_fire = self.can_fire
	
	self.can_fire = IsValid(model) 
				and IsValid(model_fill)
	
	if self.can_fire then
		model:Draw()
		model_fill:Draw()
	end
	
	if old_can_fire ~= self.can_fire then
		Events:Fire("Vehicles/CanFireBeringBombsight", {
			can_fire = self.can_fire
		})
	end
end

function cBeringBombsight:CreateModels(entity, radius)
	
	if not IsValid(entity) then return end
	
	local vertices = {}
	local fill_vertices = {}
	local ground_height_offset = 2
	
	local center = entity:GetPosition()
	local height_speed = (center.y - 200) * 0.65 + entity:GetLinearVelocity():Length() * 0.55
	center = center + entity:GetAngle() * Vector3.Forward * height_speed
	
	local height = Physics:GetTerrainHeight( center )
	
	if center.y - height < self.min_height_diff then return end
	if center.y - height > self.max_height_diff then return end
	
	center.y = height
	local ray = Physics:Raycast( center + Vector3(0, 50, 0), Vector3.Down, 0, 150 )
	center.y = ray.position.y + ground_height_offset
	
	center.y = math.max(200 + ground_height_offset, center.y)
	
	self.center = center
	
	-- circle params
	local quality = 10 -- inteval size
	local fill_alpha = 40

	local angle = Angle()
	-- generate ring positions
	local last_offset = nil
	local rad = math.rad
	for i=0, 360, quality do
		angle.yaw = rad(i)
		local offset = center + angle * (Vector3.Forward * radius)

		local height = Physics:GetTerrainHeight( offset )
		offset.y = height
			
		-- raycast
		local ray = Physics:Raycast( offset + Vector3(0, 50, 0), Vector3.Down, 0, 150 )
		offset.y = ray.position.y 
		if offset.y < 200 then
			offset.y = 200
		end

		-- raise slightly above ground / model
		offset.y = offset.y + ground_height_offset
		table.insert( vertices, Vertex( offset , Color.Red ) )
		if last_offset then
			table.insert( fill_vertices, Vertex( center, Color(255,0,0,0) ) )
			table.insert( fill_vertices, Vertex( last_offset, Color(255,0,0,fill_alpha) ) )
			table.insert( fill_vertices, Vertex( offset, Color(255,0,0,fill_alpha) ) )
		end
		last_offset = offset
	end

	local model = Model.Create( vertices )
	model:Set2D(false)
	model:SetTopology( Topology.LineStrip )
	--
	local model_fill = Model.Create( fill_vertices )
	model_fill:Set2D(false)
	model_fill:SetTopology( Topology.TriangleList )

	
	return model, model_fill
end

cBeringBombsight = cBeringBombsight()
