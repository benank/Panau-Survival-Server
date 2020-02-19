class 'GrapplehookManager'

function GrapplehookManager:__init()
	
	self.upgrades = { -- How many of each are equipped
		["Recharge"] = 0,
		["Speed"] = 0,
		["Range"] = 0,
		["Underwater"] = 0,
		["Gun"] = 0,
		["Impulse"] = 0,
		["Smart"] = 0
    }
    
    self.dura_change = 0
    self.sync_timer = Timer()

	self.smart = {d = 0, position = Vector3(0,-5000,0), radius = Render.Size.x * 0.125, ready = false, color = Color(0,0,200,150), indicator_size = Render.Size.x * 0.01, raycast_timer = Timer(), change = false}
	self.speed = {base = 40, upgrades = {[1] = 1.5, [2] = 2, [3] = 2.5, [4] = 3}, dist = 10, sync_timer = Timer(), change = 0}
	self.range = {base = 80, upgrades = {[1] = 300, [2] = 500, [3] = 750, [4] = 1000}, end_pos = Vector3(), timer = Timer(), change = 0, sync_timer = Timer()}

	self.current_grapple_max_distance = self.range.base -- Modify this value as upgrades are applied

	LocalPlayer:SetValue("GrappleUpgrades", self.upgrades)
	Events:Subscribe("FireGrapplehook", self, self.FireGrapplehook)
	Events:Subscribe("FireGrapplehookHit", self, self.FireGrapplehookHit)
	Events:Subscribe("FireGrapplehookPre", self, self.FireGrapplehookPre)
	Events:Subscribe("Render", self, self.Render)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

	Network:Subscribe("items/ToggleEquippedGrappleUpgrade", self, self.ToggleEquippedGrappleUpgrade)
end

function GrapplehookManager:ModuleUnload()
	if IsValid(self.range.object) then self.range.object:Remove() end
end

function GrapplehookManager:FireGrapplehook()

end

function GrapplehookManager:FireGrapplehookHit()

	if self.upgrades["Recharge"] > 0 then
		Network:Send("items/DecreaseRechargeGrappleDura")
	end

	if self.smart.ready and self.smart.calcview then
		self.smart.position = Vector3(0,-5000,0) -- Reset smart position after grappling
	end

	if self.smart.change then
		Network:Send("items/DecreaseSmartGrappleDura")
		self.smart.change = false
	end

end

-- Called right before the grapplehook is fired. May not be 100% accurate
function GrapplehookManager:FireGrapplehookPre()

	if self.upgrades["Smart"] > 0 
	and LocalPlayer:GetBonePosition("ragdoll_AttachHandLeft"):Distance(self.smart.position) < self.current_grapple_max_distance
	and self.smart.ready then
		self.smart.target_ang = Angle.FromVectors(Vector3.Forward, (self.smart.position - Camera:GetPosition())) -- * Vector3.Forward
		self.smart.target_ang.roll = 0
		self.smart.ang_timer = Timer()
		self.smart.calcview = Events:Subscribe("CalcView", self, self.CalcView)
		self.smart.change = true
	end

	if self.upgrades["Range"] > 0 and not self.range.active then

		local ang = (self.upgrades["Smart"] > 0 and self.smart.ready) and self.smart.target_ang or Camera:GetAngle()
		local ray = Physics:Raycast(Camera:GetPosition(), ang * Vector3.Forward, 0, self.current_grapple_max_distance)

		if ray.distance < self.current_grapple_max_distance and ray.distance > 80 then

			local args = {
				collision = "km02.towercomplex.flz/key013_01_lod1-g_col.pfx",
				model = "",
				position = Camera:GetPosition() + (ang * (Vector3.Forward * 30)),
				angle = Camera:GetAngle()
			}
			self.range.object = ClientStaticObject.Create(args)
			self.range.end_pos = ray.position + ang * Vector3.Forward * 1.5
			self.range.active = true

			self.range.timer:Restart()

		end

	end

end

-- CAlled when a grapple upgrade is equipped/unequipped
function GrapplehookManager:ToggleEquippedGrappleUpgrade(args)

	self.upgrades = args.upgrades

	Events:Fire("ChangeGrappleRechargeTime", self.upgrades["Recharge"])

	if self.upgrades["Range"] > 0 then
		self.current_grapple_max_distance = self.range.upgrades[self.upgrades["Range"]]
	else
		self.current_grapple_max_distance = self.range.base
	end

end

function GrapplehookManager:DisableEvents()
	if self.localplayerinput then Events:Unsubscribe(self.localplayerinput) end
	if self.postrender then Events:Unsubscribe(self.postrender) end
end

function GrapplehookManager:CalcView()
	if self.smart.target_ang and self.upgrades["Smart"] > 0 then
		Camera:SetAngle(self.smart.target_ang)
		
		if self.smart.ang_timer:GetMilliseconds() > 75 then
			self.smart.ang_timer = nil
			Events:Unsubscribe(self.smart.calcview)
			self.smart.calcview = nil
			self.smart.target_ang = nil
		end
	end
end

function GrapplehookManager:Render(args)

    if LocalPlayer:InVehicle() then return end
    if not EquippableGrapplehook:GetEquipped() then return end -- If it's not equipped
	
	local left_arm_state = LocalPlayer:GetLeftArmState()
	local base_state = LocalPlayer:GetBaseState()
	
	if left_arm_state == 402 then -- shoot grapple (both hit or miss have this)
		
	end
	
	if left_arm_state == 408 then -- hook attaches to something
		
	end

	self.grappling = base_state == AnimationState.SReelFlight

	local cam_pos = Camera:GetPosition()
	local ray = Physics:Raycast(cam_pos, Camera:GetAngle() * Vector3.Forward, 0, 1000)

	self:RenderGrappleDistance(ray)

    -- Basic grapplehook durability
    if self.grappling then
        self.dura_change = self.dura_change + args.delta

        if self.sync_timer:GetSeconds() > 5 then
            Network:Send("items/GrapplehookDecreaseDura", {change = math.ceil(self.dura_change)})
            self.sync_timer:Restart()
            self.dura_change = 0
        end
    end

	local localplayer_velo = LocalPlayer:GetLinearVelocity()
	local speed = math.abs((-LocalPlayer:GetAngle() * localplayer_velo).z)

	if self.upgrades["Speed"] > 0 
	and self.grappling 
	and speed > 10 
	and speed < self.speed.upgrades[self.upgrades["Speed"]] * self.speed.base
	and ray.distance > self.speed.dist then
		LocalPlayer:SetLinearVelocity(localplayer_velo * 1.2)
		self.speed.change = self.speed.change + args.delta --* self.upgrades["Speed"]
		-- Raycast in here because otherwise sometimes the velo is set when they land and they go a bit crazy
	end

	if self.upgrades["Range"] > 0 then
		if self.range.timer:GetMilliseconds() > 600 and not self.range.moved and self.range.active then
			self.range.moved = true
			self.range.object:SetPosition(self.range.end_pos)
			self.range.timer:Restart()
		elseif self.range.timer:GetMilliseconds() > 1 and self.range.moved and self.range.active then
			self.range.object:Remove()
			self.range.object = nil
			self.range.moved = false
			self.range.active = false
		end
    end

	if self.upgrades["Range"] > 0 and self.grappling then
		self.range.change = self.range.change + args.delta
		
		if self.range.sync_timer:GetSeconds() > 5 and self.range.change > 0 then
			Network:Send("items/RangeGrapplehookDecreaseDura", {change = math.ceil(self.range.change)})
			self.range.sync_timer:Restart()
			self.range.change = 0
		end

	end

	if self.speed.sync_timer:GetSeconds() > 5 and self.speed.change > 0 then
		Network:Send("items/SpeedGrapplehookDecreaseDura", {change = math.ceil(self.speed.change)})
		self.speed.sync_timer:Restart()
		self.speed.change = 0
	end

	if self.upgrades["Smart"] > 0 and not self.grappling then
		if ray.distance < self.current_grapple_max_distance 
		and (not ray.entity or ray.entity.__type ~= "ClientStaticObject" or ray.entity ~= self.range.object) then
			self.smart.position = ray.position
			self.smart.ready = true
		end
				
		local pos_2d = Render:WorldToScreen(self.smart.position)
		local dist = pos_2d:Distance(Render.Size / 2)

		self.smart.ready = dist < self.smart.radius and dist > 1 and self.smart.position:Distance(cam_pos) < self.current_grapple_max_distance

		if self.smart.ready and not self.grappling then
			self:RenderSmartGrapple(pos_2d)
		elseif dist >= self.smart.radius or self.grappling then
			self.smart.position = Vector3(0,-5000,0)
		end

		self.smart.d = self.smart.d + args.delta * 4
	end
	
end

function GrapplehookManager:RenderSmartGrapple(pos)

	local size = self.smart.indicator_size

	Render:SetTransform(Transform2():Translate(pos):Rotate(self.smart.d + math.pi):Translate(Vector2(size * 0.05, 0)))

	Render:FillTriangle(
		Vector2(size * 1, size / 2),
		Vector2(size * 1, -size / 2),
		Vector2(size * 0.15, 0),
		self.smart.color
	)

	Render:SetTransform(Transform2():Translate(pos):Rotate(self.smart.d):Translate(Vector2(size * 0.05, 0)))

	Render:FillTriangle(
		Vector2(size * 1, size / 2),
		Vector2(size * 1, -size / 2),
		Vector2(size * 0.15, 0),
		self.smart.color
	)

	Render:ResetTransform()

end

function GrapplehookManager:RenderGrappleDistance(ray)

	local triangleColor = Color(0,200,0,150)
	
	if LocalPlayer:GetValue("NumGrappleCharges") == 0 or ray.distance > self.current_grapple_max_distance then
		triangleColor = Color(200,0,0,150)
	end
	
	if self.grappling then
		triangleColor = Color(0,0,200,150)
	end
	
	if ray.distance < 1000 then

		local str 		= 		string.format("%i m", tostring(ray.distance))
		local size 		= 		Render.Size.x / 100
		local pos 		= 		Vector2((Render.Size.x / 2) - (Render:GetTextSize(str, size).x / 2), Render.Size.y  - (Render.Size.y / 1.85))
		local color 	= 		Color(0,0,0,255)
		
		Render:DrawText(pos + (Render.Size / 1000), str, color, size)
		Render:DrawText(pos, str, Color.White, size)
		pos = pos + Vector2(0,Render:GetTextSize(str, size).y)
		Render:FillTriangle(pos - (Vector2(0,Render:GetTextSize(str, size).y)/2),
			pos - Vector2(Render.Size.x / 100,0), pos - (Vector2(0,Render:GetTextSize(str, size).y))- Vector2(Render.Size.x / 100,0), triangleColor)
		pos = pos + Vector2(Render:GetTextSize(str, size).x,0) - Vector2(0,Render:GetTextSize(str, size).y)
		Render:FillTriangle(pos + (Vector2(0,Render:GetTextSize(str, size).y)/2),
			pos + Vector2(Render.Size.x / 100,0), pos + (Vector2(0,Render:GetTextSize(str, size).y)) + Vector2(Render.Size.x / 100,0), triangleColor)
	end
	
end

GrapplehookManager = GrapplehookManager()
