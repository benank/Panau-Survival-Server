
class("FreeCam")

function FreeCam:__init()
	self.speed = 1 -- Default speed
	self.speedSetting = Config.speedSetting
	self.speedUp = Config.speedUp
	self.speedDown = Config.speedDown
	self.teleport = Config.teleport -- Teleport player too cam location when quitting freecam mode
	self.activateKey = Config.activateKey
	self.mouseSensitivity = 0.15
	self.gamepadSensitivity = 0.08
	self.permitted = not Config.useWhiteList -- Default

	self.active = false
	self.translation = Vector3(0,0,0)
	self.position = Vector3(0,500,0)
	self.angle = Angle(0,0,0)

	self.followingTrajectory = false

	self.gamepadPressed = {false, false, false}

	Events:Subscribe("CalcView", self, self.CalcView)
	Events:Subscribe("PostTick", self, self.UpdateCamera)
	Events:Subscribe("KeyUp", self, self.KeyUp)
	Events:Subscribe("MouseDown", self, self.MouseDown)
	Events:Subscribe("LocalPlayerChat", self, self.TrajectorySaver)	
	Events:Subscribe("LocalPlayerInput", self, self.PlayerInput)
	Events:Subscribe("InputPoll", self, self.ResetPressed)

	Events:Subscribe("ModuleLoad", self, self.ModulesLoad)
	Events:Subscribe("ModulesLoad", self, self.ModulesLoad)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

	-- Load trajectory
	Network:Subscribe("FreeCamStore", function(args)
			if args.trajectory == nil then return end
			self.trajectory = args.trajectory
			Chat:Print(string.format("%s Loaded trajectory '%s' with %d waypoints",
				Config.name, args.name, #self.trajectory), Config.color)
		end)

	-- Change permission/force activate
	Network:Subscribe("FreeCam", function(args)
			if args.perm ~= nil then
				-- Change permission
				self.permitted = args.perm
			end
			if args.active ~= nil then
				-- Set active
				if args.active then
					self:Activate()
				else
					self:Deactivate()
				end
				Network:Send("FreeCamChange", {["active"] = self.active}) -- Notice for server
				Events:Fire("FreeCamChange", {["active"] = self.active}) -- Notice for client
			end
		end)
end

function FreeCam:UpdateCamera()
	if Game:GetState() ~= GUIState.Game or not self.active then return end
	-- Set speed
	local speed = self.speed
	if self.speedSetting == 1 then
		if Input:GetValue(Action.PlaneIncTrust) > 0 then
			self.speed = math.min(1000, self.speed * 1.01)
		elseif Input:GetValue(Action.PlaneDecTrust) > 0 then
			self.speed = math.max(0.1, self.speed * 0.99)
		end
		speed = self.speed
	else
		if Input:GetValue(Action.PlaneIncTrust) > 0 then
			speed = speed * self.speedUp
		elseif Input:GetValue(Action.PlaneDecTrust) > 0 then
			speed = speed / self.speedDown
		end
	end

	if self.followingTrajectory then
		-- AUTO FOLLOW TRAJECTORY MODE
		if self.pause then return end -- Pause
		-- Check if next waypoint is reached
		-- Use a destination error to avoid problems with rounding errors
		if self.waypoint == nil or Vector3.Distance(self.position, self.waypoint.pos) < 1 then
			-- Set next waypoint
			if self.trajectoryIndex > #self.trajectory then
				-- Finished
				self:StopFollow()
				return
			else
				-- Get next waypoint
				self.waypoint = self.trajectory[self.trajectoryIndex]
				self.trajectoryDirection = (self.waypoint.pos - self.position)
				if self.trajectoryDirection:Length() > 0 then
					self.trajectoryDirection = self.trajectoryDirection/norm(self.trajectoryDirection)
				end
				local dist = Vector3.Distance(self.waypoint.pos, self.position)
				local angleDiff = AngleDiff(self.waypoint.angle, self.angle)
				self.angleDirection = angleDiff/norm(angleDiff)
				self.angleSpeed = Vector3(0,0,0)

				self.trajectoryIndex = self.trajectoryIndex + 1
			end
		end
		-- Set movement
		self.position = self.position + speed * self.trajectoryDirection
		-- Set angle
		local angleDiff = AngleDiff(self.waypoint.angle, self.angle)
		if math.abs(angleDiff.x) > 0.1 then
			self.angle.yaw = self.angle.yaw + (speed * 0.002) * self.angleDirection.x
		end
		if math.abs(angleDiff.y) > 0.1 then
			self.angle.pitch = self.angle.pitch + (speed * 0.002) * self.angleDirection.y
		end
		if math.abs(angleDiff.z) > 0.1 then
			self.angle.roll = self.angle.roll + (speed * 0.002) * self.angleDirection.z
		end
	else
		-- DEFAULT MODE
		-- Set translation
		self.translation = Vector3(0,0,0)
		if Input:GetValue(Action.MoveForward) >= 65535 then -- up    	
			self.translation = self.translation + Vector3(0, 0, -1)
		end
		if Input:GetValue(Action.MoveBackward) >= 65535 then -- down
			self.translation = self.translation + Vector3(0, 0, 1)
		end
		if Input:GetValue(Action.MoveLeft) >= 65535 then -- left
			self.translation = self.translation + Vector3(-1, 0, 0)
		end
		if Input:GetValue(Action.MoveRight) >= 65535 then -- right
			self.translation = self.translation + Vector3(1, 0, 0)
		end
		-- Normalize translation
		if self.translation:Length() > 0 then
			self.translation = speed * (self.translation/norm(self.translation))
		end
		-- Set position
		self.position = self.position + self.angle * self.translation
	end
end

function FreeCam:CalcView()
	if Game:GetState() ~= GUIState.Game or not self.active then return end
	Camera:SetAngle(self.angle)
	Camera:SetPosition(self.position)
	return false
end

function FreeCam:Activate()
	self.active = true 
	self.position = LocalPlayer:GetBonePosition("ragdoll_Head")
	self.angle = LocalPlayer:GetAngle()
	self.angle.roll = 0
end

function FreeCam:Deactivate()
	self.active = false
	self:StopFollow()
	if self.teleport then
		Network:Send("FreeCamTP", {["pos"] = self.position, ["angle"] = self.angle})
	end
end

---------- INPUT ----------
function FreeCam:KeyUp(args)	
	if args.key == string.byte(self.activateKey) and self.permitted then
		if not self.active then
			self:Activate()
		else
			self:Deactivate()
		end
		Network:Send("FreeCamChange", {["active"] = self.active}) -- Notice for server
		Events:Fire("FreeCamChange", {["active"] = self.active}) -- Notice for client
	end
	if self.active then
		-- Trajectory
		if args.key == 97 then -- numpad1
			self:ResetTrajectory()
		elseif args.key == 98 then -- numpad2
			self:AddWayPoint()
		elseif args.key == 99 then -- numpad3
			self:FollowTrajectory(false)
		elseif args.key == 100 then -- numpad4
			self:FollowTrajectory(true)
		end
		if args.key == string.byte('P') then
			if self.pause == nil then selfpause = false end
			self.pause = not self.pause
		end
	end
end

function FreeCam:MouseDown(args)
	if self.active and args.button == 1 then
		self:AddWayPoint()
	end
end


function FreeCam:PlayerInput(args)
	if Game:GetState() ~= GUIState.Game or not self.active then return end
	local sensitivity = self.mouseSensitivity
	-- GamePad input
	if Game:GetSetting(GameSetting.GamepadInUse) == 1 then
		sensitivity = self.gamepadSensitivity
		if args.input == Action.SequenceButton1 then
			if not self.gamepadPressed[1] then
				self:ResetTrajectory()
				self.gamepadPressed[1] = true
			end
		elseif args.input == Action.SequenceButton4 then
			if not self.gamepadPressed[2] then
				self:AddWayPoint()
				self.gamepadPressed[2] = true
			end
		elseif args.input == Action.SequenceButton3 then
			if not self.gamepadPressed[3] then
				self:FollowTrajectory()
				self.gamepadPressed[3] = true
			end
		end
	end
	-- Change camera angle
	if self.followingTrajectory then return end
	if args.input == Action.LookUp then
		self.angle.pitch = math.clamp(self.angle.pitch - args.state * sensitivity, -math.pi/2, math.pi/2)
	elseif args.input == Action.LookDown then
		self.angle.pitch = math.clamp(self.angle.pitch + args.state * sensitivity, -math.pi/2, math.pi/2)
	elseif args.input == Action.LookLeft then
		self.angle.yaw = SetAngleRange(self.angle.yaw + args.state * sensitivity)
	elseif args.input == Action.LookRight then
		self.angle.yaw = SetAngleRange(self.angle.yaw - args.state * sensitivity)
	end
end

function FreeCam:ResetPressed(args)
	if Game:GetState() ~= GUIState.Game or not self.active then return end
	if Input:GetValue(Action.SequenceButton1) == 0 then
		self.gamepadPressed[1] = false
	end
	if Input:GetValue(Action.SequenceButton4) == 0 then
		self.gamepadPressed[2] = false
	end
	if Input:GetValue(Action.SequenceButton3) == 0 then
		self.gamepadPressed[3] = false
	end
end

---------- TRAJECTORY ----------

function FreeCam:TrajectorySaver(args)
	if args.text:sub(1, 1) ~= "/" then return true end
	local msg = args.text:sub(2):split(" ")
	if msg[1] == "freecam" then
		if #msg < 4 then
			Chat:Print(string.format("%s Usage: /freecam <save/load/delete> <trajectory|position> <name>", Config.name), Config.color)
		else
			table.remove(msg, 1)
			local command = table.remove(msg, 1)
			local command2 = table.remove(msg, 1)
			local name = table.concat(msg):gsub("[^%a%d]", "")
			if command == "save" then
				if command2 == "trajectory" then
					Network:Send("FreeCamStore", {["type"] = "save",
													["name"] = name,
													["trajectory"] = self.trajectory})
				elseif command2 == "position" then
					if not self.active then
						self.position = LocalPlayer:GetBonePosition("ragdoll_Head")
					end
					Network:Send("FreeCamStore", {["type"] = "save",
													  ["name"] = name,
													  ["position"] = self.position})
				end
			elseif command == "load" then
				if command2 == "trajectory" then
					Network:Send("FreeCamStore", {["type"] = "load",
												  ["name"] = name})
				end
			elseif command == "delete" then
				if command2 == "trajectory" then
					Network:Send("FreeCamStore", {["type"] = "delete",
												  ["name"] = name})
				end
			end
		end
		return false
	end
	return true
end

function FreeCam:ResetTrajectory()
	if self.followingTrajectory then
		self:StopFollow()
	end
	self.trajectory = nil
	Chat:Print(string.format("%s Trajectory resetted", Config.name), Config.color)
end

function FreeCam:AddWayPoint()
	if self.trajectory == nil then
		self.trajectory = {}
	end
	table.insert(self.trajectory, {["pos"] = Copy(self.position),
								   ["angle"] = Copy(self.angle)})
	Chat:Print(string.format("%s Added waypoint #%d", Config.name, #self.trajectory), Config.color)
end

function FreeCam:FollowTrajectory(startHere)
	if self.trajectory == nil or #self.trajectory < 1 then return end
	if self.followingTrajectory then
		-- Stop
		self:StopFollow()
		--print("stopped")
	else
		-- Start
		self.followingTrajectory = true
		self.camBackup = {["pos"] = self.position, ["angle"] = self.angle}
		if startHere then
			-- Start from current position
			self.trajectoryIndex = 1
		else
			-- Start from first waypoint
			self.position = Copy(self.trajectory[1].pos)
			self.angle = Copy(self.trajectory[1].angle)
			self.trajectoryIndex = 2
		end
		--print("started")
	end
	self.distError = 1
end

function FreeCam:StopFollow()
	self.followingTrajectory = false
	self.waypoint = nil
	-- Reset camera
	if self.camBackup then
		self.position = self.camBackup.pos
		self.angle = self.camBackup.angle
		self.camBackup = nil
	end
end
---------- INFO ----------

function FreeCam:ModulesLoad()
    Events:Fire("HelpAddItem",
        {
            name = "FreeCam",
            text = 
            	"FreeCam v0.3.1\n\n"..
                "A free/spectator cam.\n\n"..
                "-> Press V to activate/deactive\n"..
                "-> Use SHIFT to speed up, CTRL to slow down or Increase/Decrease trust on gamepad\n\n"..
                "Making trajectories (while in FreeCam mode):\n"..
                "- numpad1/gamepad X: reset trajectory\n"..
                "- numpad2/left mouse click/gamepad A: add waypoint to current trajectory\n"..
                "- numpad3/gamepad B: start/stop auto follow trajectory mode (starting from the first waypoint)\n"..
                "- numpad4: start/stop auto follow trajectory mode (starting from current camera position)\n"..
                "- P: pause the auto follow trajectory mode\n\n"..
                "Commands for saving trajectories and spawnpoints (white listed players only):\n"..
				"-> Type /freecam <save/load/delete> trajectory <trajectory_name> to manage trajectories\n"..
				"-> Type /freecam save position <position_name> to save positions"
        })
end

function FreeCam:ModuleUnload()
    Events:Fire("HelpRemoveItem",
        {
            name = "FreeCam"
        })
end

freeCam = FreeCam()

---------- SOME TOOLS ----------
function norm(v1, v2)
	v2 = v2 or v1
	return math.sqrt(Vector3.Dot(v1, v2))
end

function SetAngleRange(angle)
	if angle > math.pi then
		angle = angle - 2*math.pi
	elseif angle < -math.pi then
		angle = angle + 2*math.pi
	end
	return angle
end

-- Get angle difference using the closest distance
function AngleDiff(a1, a2)
	local diff = Vector3()
	diff.x = AngleDiff2(a1, a2, "yaw")
	diff.y = AngleDiff2(a1, a2, "pitch")
	diff.z = AngleDiff2(a1, a2, "roll")
	return diff
end

function AngleDiff2(a1, a2, axis)	
	local diff = a1[axis] - a2[axis]
	if math.abs(diff) > math.pi then
		if a1[axis] > a2[axis] then
			diff = -(math.pi - math.abs(a1[axis]) + math.pi - math.abs(a2[axis]))
		else
			diff = math.pi - math.abs(a2[axis]) + math.pi - math.abs(a1[axis])
		end
	end
	return diff
end