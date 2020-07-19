-- Hacken together from my trusty old OrbitCamera class.

class("OrbitCamera" , MapEditor)

function MapEditor.OrbitCamera:__init(position , angle) ; EGUSM.SubscribeUtility.__init(self)
	self.Destroy = MapEditor.OrbitCamera.Destroy
	
	-- Public properties
	self.targetPosition = position or Vector3(0 , 0 , 0)
	self.minPitch = math.rad(-89)
	self.maxPitch = math.rad(89)
	self.minDistance = 0.5
	self.maxDistance = 32768
	self.collision = false
	self.isEnabled = true
	self.isInputEnabled = true
	-- Private properties
	self.position = position or Vector3(0 , 10000 , 0)
	self.angle = angle or Angle()
	self.distance = 50
	self.angleBuffer = self.angle
	self.distanceDeltaBuffer = 0
	self.panBuffer = Vector3(0 , 0 , 0)
	self.deltaTimer = Timer()
	
	local controlDisplayer = MapEditor.ControlDisplayer{
		name = "Camera" ,
		linesFromBottom = 2 ,
	}
	controlDisplayer:AddControl("Orbit camera: Rotate/pan" , "Rotate/pan")
	controlDisplayer:AddControl("Orbit camera: Pan modifier" , "Pan modifier")
	controlDisplayer:AddControl("Mouse wheel up" , "Zoom in")
	controlDisplayer:AddControl("Mouse wheel down" , "Zoom out")
	MapEditor.map.controlDisplayers.camera = controlDisplayer
	
	self:EventSubscribe("CalcView")
	self:EventSubscribe("ControlDown")
	self:EventSubscribe("ControlUp")
	self:EventSubscribe("PostTick")
end

function MapEditor.OrbitCamera:Destroy()
	MapEditor.map.controlDisplayers.camera:Destroy()
	
	self:UnsubscribeAll()
end

function MapEditor.OrbitCamera:GetPosition()
	return self.targetPosition
end

function MapEditor.OrbitCamera:SetPosition(position)
	self.targetPosition = position
	self.angleBuffer.pitch = math.clamp(self.angleBuffer.pitch , -70 , 5)
	self.distance = 50
end

function MapEditor.OrbitCamera:UpdateDistance()
	local distanceDelta = self.distanceDeltaBuffer
	self.distanceDeltaBuffer = 0
	
	local mult = math.pow(10 , 1 + -distanceDelta * MapEditor.Preferences.camSensitivityZoom)
	self.distance = self.distance * mult * 0.1
	self.distance = math.clamp(self.distance , self.minDistance , self.maxDistance)
end

function MapEditor.OrbitCamera:UpdatePosition()
	local cameraDirection = (self.angle * Vector3.Backward)
	if self.collision then
		-- Raycast test so the camera doesn't go into geometry.
		local result = Physics:Raycast(self.targetPosition , cameraDirection , 0 , self.distance)
		self.position = self.targetPosition + cameraDirection * result.distance
		-- If the raycast hit.
		if result.distance ~= self.distance then
			self.position = self.position + result.normal * 0.25
		end
	else
		self.position = self.targetPosition + cameraDirection * self.distance
	end
	
	local terrainHeight = Physics:GetTerrainHeight(self.position)
	if self.position.y < terrainHeight then
		self.position.y = terrainHeight + 0.25 + self.distance * 0.0025
	end
	
	-- If angle isn't set here, it acts strangely, as if something is delayed by a frame. I have no
	-- idea why this works.
	self.angle = Angle.FromVectors(Vector3.Backward , cameraDirection)
	self.angle.roll = 0
end

function MapEditor.OrbitCamera:UpdateAngle()
	self.angle = self.angleBuffer
end

function MapEditor.OrbitCamera:UpdateMovement()
	local velocity = self.panBuffer * self.distance
	local y = velocity.y
	velocity = Angle(self.angle.yaw , 0 , 0) * velocity
	velocity.y = y
	
	self.targetPosition = self.targetPosition + velocity
	
	local terrainHeight = Physics:GetTerrainHeight(self.targetPosition)
	if self.targetPosition.y < terrainHeight then
		self.targetPosition.y = terrainHeight
	end
	
	self.panBuffer = Vector3(0 , 0 , 0)
end

-- Events

function MapEditor.OrbitCamera:CalcView()
	if self.isEnabled == false then
		return true
	end
	
	Camera:SetPosition(self.position)
	Camera:SetAngle(self.angle)
	
	-- Disable our player.
	return false
end

function MapEditor.OrbitCamera:ControlDown(args)
	local delta
	
	if args.name == "Orbit camera: Rotate/pan" then
		self.isInputEnabled = true
	elseif args.name == "Mouse wheel up" then
		delta = args.state
	elseif args.name == "Mouse wheel down" then
		delta = -args.state
	end
	
	if delta then
		if Controls.GetIsHeld("Orbit camera: Pan modifier") then
			self.panBuffer.y = delta * MapEditor.Preferences.camSensitivityMove * 0.15
		else
			self.distanceDeltaBuffer = delta
		end
	end
end

function MapEditor.OrbitCamera:ControlUp(args)
	if args.name == "Orbit camera: Rotate/pan" then
		self.isInputEnabled = false
	end
end

function MapEditor.OrbitCamera:PostTick()
	local deltaTime = self.deltaTimer:GetSeconds()
	self.deltaTimer:Restart()
	
	if self.isEnabled == false then
		return
	end
	
	-- Handle inputs.
	if self.isInputEnabled then
		local RotateYaw = function(value)
			self.angleBuffer.yaw = self.angleBuffer.yaw + value
		end
		local RotatePitch = function(value)
			self.angleBuffer.pitch = math.clamp(
				self.angleBuffer.pitch + value ,
				self.minPitch ,
				self.maxPitch
			)
		end
		
		if Controls.GetIsHeld("Orbit camera: Rotate/pan") then
			if Controls.GetIsHeld("Orbit camera: Pan modifier") then
				local mult = MapEditor.Preferences.camSensitivityMove * deltaTime
				if Controls.GetIsHeld("Look right") then
					self.panBuffer.x = -Controls.Get("Look right").state * mult
				else
					self.panBuffer.x = Controls.Get("Look left").state * mult
				end
				if Controls.GetIsHeld("Look up") then
					self.panBuffer.z = Controls.Get("Look up").state * mult
				else
					self.panBuffer.z = -Controls.Get("Look down").state * mult
				end
			else
				local mult = MapEditor.Preferences.camSensitivityRot
				if Controls.GetIsHeld("Look right") then
					RotateYaw(-Controls.Get("Look right").state * mult)
				else
					RotateYaw(Controls.Get("Look left").state * mult)
				end
				if Controls.GetIsHeld("Look up") then
					RotatePitch(Controls.Get("Look up").state * mult)
				else
					RotatePitch(-Controls.Get("Look down").state * mult)
				end
			end
		end
	end
	
	Mouse:SetVisible(true)
	
	-- What are these even
	self:UpdateAngle()
	self:UpdateMovement()
	self:UpdateDistance()
	self:UpdatePosition()
end
