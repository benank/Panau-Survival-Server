class 'EquippableRocketGrapple'

function EquippableRocketGrapple:__init()
    
    self.equipped = false
    
    self.dura_change = 0
    self.sync_timer = Timer()
    self.range = 1000
    self.position = Vector3.Zero


    self.grapple = {position = Vector3.Zero, active = false, timer = Timer()}
    self.speed_base = 40
    self.speed_mod = 2
    self.speed_dist = 10

    self.grapple_fx = {}

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("Render", self, self.Render)

	Network:Subscribe("items/ToggleEquippedRocketGrapple", self, self.ToggleEquippedRocketGrapple)
end

function EquippableRocketGrapple:GetEquipped()
    return self.equipped
end

function EquippableRocketGrapple:ModuleUnload()
	if IsValid(self.grapple.object) then self.grapple.object:Remove() end
end

function EquippableRocketGrapple:FireGrapplehook()

end

function EquippableRocketGrapple:FireGrapplehookHit()

end

-- Called right before the grapplehook is fired. May not be 100% accurate
function EquippableRocketGrapple:FireGrapplehookPre()

    if not self.equipped then return end

	if not self.grapple.active then

		local ang = Camera:GetAngle()
		local ray = Physics:Raycast(Camera:GetPosition(), ang * Vector3.Forward, 0, self.range)

		if ray.distance < self.range and ray.distance > 80 then

			local args = {
				collision = "km02.towercomplex.flz/key013_01_lod1-g_col.pfx",
				model = "",
				position = Camera:GetPosition() + (ang * (Vector3.Forward * 40)),
				angle = Camera:GetAngle()
			}
			self.grapple.object = ClientStaticObject.Create(args)
			self.grapple.end_pos = ray.position + ang * Vector3.Forward * 1.5
			self.grapple.active = true

			self.grapple.timer:Restart()

		end

	end

end

-- CAlled when a grapple upgrade is equipped/unequipped
function EquippableRocketGrapple:ToggleEquippedRocketGrapple(args)
    self.equipped = args.equipped
    EquippableGrapplehook:ToggleEquipped(args)

    if self.equipped then
        self:SubscribeAllEvents()
    else
        self:UnsubscribeAllEvents()
    end
end

function EquippableRocketGrapple:SubscribeAllEvents()
    self.events = 
    {
        Events:Subscribe("FireGrapplehook", self, self.FireGrapplehook),
        Events:Subscribe("FireGrapplehookHit", self, self.FireGrapplehookHit),
        Events:Subscribe("FireGrapplehookPre", self, self.FireGrapplehookPre)
    }
end

function EquippableRocketGrapple:UnsubscribeAllEvents()
    for _, event in pairs(self.events) do
        Events:Unsubscribe(event)
    end
    self.events = {}

    if IsValid(self.grapple.object) then
        self.grapple.object:Remove()
    end

    if self.grapple_fx[LocalPlayer:GetId()] and not EquippableGrapplehook:GetEquipped() then
        self.grapple_fx[LocalPlayer:GetId()]:Remove()
        self.grapple_fx[LocalPlayer:GetId()] = nil
    end

    EquippableGrapplehook:StopUsing()

end

-- Render the FX for other players' rocket grapples
function EquippableRocketGrapple:HandleOtherPlayerRocketGrapples()

    for player in Client:GetStreamedPlayers() do
        self:HandlePlayerRocketGrapple(player)
    end

end

function EquippableRocketGrapple:HandlePlayerRocketGrapple(player)

    if not player:GetValue("RocketGrappleEquipped") then return end
    
    local base_state = player:GetBaseState()
	local left_arm_state = LocalPlayer:GetLeftArmState()
	local grappling = base_state == AnimationState.SReelFlight or left_arm_state == AnimationState.LaSGrapple
	local player_velo = player:GetLinearVelocity()
    local speed = math.abs((-player:GetAngle() * player_velo).z)
    local parachuting = base_state == AnimationState.SParachute
    
    local rocket_grappling = grappling and speed > 10 and not parachuting
    if rocket_grappling then
        local arm_pos = player:GetBonePosition("ragdoll_AttachHandLeft")
        if not self.grapple_fx[player:GetId()] then
            self.grapple_fx[player:GetId()] = ClientEffect.Create(AssetLocation.Game, {
                position = arm_pos,
                angle = Angle(),
                effect_id = 427
            })
            self.grapple_fx[player:GetId()]:Play()
        end
        self.grapple_fx[player:GetId()]:SetPosition(arm_pos)
    elseif not rocket_grappling and IsValid(self.grapple_fx[player:GetId()]) then
        self.grapple_fx[player:GetId()]:Remove()
        self.grapple_fx[player:GetId()] = nil
    end

end

function EquippableRocketGrapple:Render(args)

    self:HandleOtherPlayerRocketGrapples()

    if LocalPlayer:InVehicle() then return end
    if not EquippableGrapplehook:GetEquipped() or not self.equipped then return end -- If it's not equipped
	
	local left_arm_state = LocalPlayer:GetLeftArmState()
	local base_state = LocalPlayer:GetBaseState()
	
	if left_arm_state == 402 then -- shoot grapple (both hit or miss have this)
		
	end
	
	if left_arm_state == 408 then -- hook attaches to something
		
	end

    self.grappling = base_state == AnimationState.SReelFlight or left_arm_state == AnimationState.LaSGrapple
    local parachuting = base_state == AnimationState.SParachute

    local cam_pos = Camera:GetPosition()
    if IsNaN(cam_pos.x) or IsNaN(cam_pos.y) or IsNaN(cam_pos.z) then return end
	local ray = Physics:Raycast(cam_pos, Camera:GetAngle() * Vector3.Forward, 0, 1000)

	self:RenderGrappleDistance(ray)

    self:HandlePlayerRocketGrapple(LocalPlayer)

	local localplayer_velo = LocalPlayer:GetLinearVelocity()
	local speed = math.abs((-LocalPlayer:GetAngle() * localplayer_velo).z)

    if self.grappling 
    and not parachuting
	and speed > 10 
	and speed < self.speed_mod * self.speed_base
	and ray.distance > self.speed_dist then
		LocalPlayer:SetLinearVelocity(localplayer_velo * 1.05)
	end

    if self.grapple.timer:GetMilliseconds() > 600 and not self.grapple.moved and self.grapple.active then
        self.grapple.moved = true
        self.grapple.object:SetPosition(self.grapple.end_pos)
        self.grapple.timer:Restart()
    elseif self.grapple.timer:GetMilliseconds() > 1 and self.grapple.moved and self.grapple.active then
        self.grapple.object:Remove()
        self.grapple.object = nil
        self.grapple.moved = false
        self.grapple.active = false
    end

end

function EquippableRocketGrapple:RenderGrappleDistance(ray)

	local triangleColor = Color(0,200,0,150)
	
	if LocalPlayer:GetValue("NumGrappleCharges") == 0 or ray.distance > self.range then
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

EquippableRocketGrapple = EquippableRocketGrapple()
