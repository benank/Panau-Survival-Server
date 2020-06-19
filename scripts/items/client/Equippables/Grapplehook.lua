class 'EquippableGrapplehook'

function EquippableGrapplehook:__init()

    self.equipped = false
    self.sync_timer = Timer()
    self.dura_change = 0

    self.uid = 0

    self.blocked_actions = 
    {
        [Action.DecGrappleDistance] = true,
        [Action.FireGrapple] = true,
        [Action.GrapplingAction] = true,
        [Action.IncGrappleDistance] = true,
        [Action.ReeledInJumpAction] = true,
        [Action.ReeledInReleaseAction] = true,
        [Action.DeployParachuteWhileReelingAction] = true,
        [Action.Kick] = true
    }

    self.base_speed = 40

    self.perk_speeds = 
    {
        [33] = 1.25,
        [73] = 1.50,
        [110] = 1.75,
        [233] = 2.00,
    }
    
    self:ToggleEnabled(false)

    Events:Subscribe("Render", self, self.Render)
    Network:Subscribe(var("items/ToggleEquippedGrapplehook"):get(), self, self.ToggleEquipped)
end

function EquippableGrapplehook:Render(args)
    
    if self.sync_timer:GetSeconds() > 5 and self.dura_change > 0 then
        if EquippableRocketGrapple:GetEquipped() then
            local perk_mods = EquippableRocketGrapple:GetPerkMods()
            
            self.dura_change = self.dura_change * perk_mods[1]

            Network:Send(var("items/RocketGrappleDecreaseDura"):get(), {uid = self.uid, change = self.dura_change})
        else
            Network:Send(var("items/GrapplehookDecreaseDura"):get(), {uid = self.uid, change = self.dura_change})
        end
        
        self.sync_timer:Restart()
        self.dura_change = 0
    end

    if LocalPlayer:InVehicle() then return end
    if not self.equipped then return end -- If it's not equipped
	
	local left_arm_state = LocalPlayer:GetLeftArmState()
	local base_state = LocalPlayer:GetBaseState()
	
	if left_arm_state == 402 then -- shoot grapple (both hit or miss have this)
		
	end
	
	if left_arm_state == 408 then -- hook attaches to something
		
	end

    self.grappling = base_state == AnimationState.SReelFlight or left_arm_state == AnimationState.LaSGrapple

    self:HandleGrapplehookSpeedPerks()
    
    -- Basic grapplehook durability
    if self.grappling then
        self.dura_change = self.dura_change + args.delta
    end

end

function EquippableGrapplehook:HandleGrapplehookSpeedPerks()

    if not self.grappling then return end

    local perks = LocalPlayer:GetValue("Perks")

    if not perks then return end

    local perk_speed_mod = 1

    for perk_id, speed_mod in pairs(self.perk_speeds) do
        if perks.unlocked_perks[perk_id] then
            perk_speed_mod = math.max(perk_speed_mod, speed_mod)
        end
    end

    if perk_speed_mod == 1 then return end -- No speed mods

    local base_state = LocalPlayer:GetBaseState()

    local parachuting = base_state == AnimationState.SParachute

    local cam_pos = Camera:GetPosition()
    if IsNaN(cam_pos.x) or IsNaN(cam_pos.y) or IsNaN(cam_pos.z) then return end
	local ray = Physics:Raycast(cam_pos, Camera:GetAngle() * Vector3.Forward, 0, 1000)

	local localplayer_velo = LocalPlayer:GetLinearVelocity()
    local speed = math.abs((-LocalPlayer:GetAngle() * localplayer_velo).z)
    
    if self.grappling 
    and not parachuting
	and speed > 5 
	and speed < self.base_speed * perk_speed_mod
    and ray.distance > 15 then
		LocalPlayer:SetLinearVelocity(localplayer_velo * 1.1)
	end

end

function EquippableGrapplehook:GetEquipped()
    return self.equipped
end

function EquippableGrapplehook:ToggleEquipped(args)
    self.equipped = args.equipped
    self.uid = self.equipped and args.uid or 0
    self:StopUsing()

    self:ToggleEnabled(self.equipped)
end

function EquippableGrapplehook:ToggleEnabled(enabled)
    if enabled then
        if self.action_block then Events:Unsubscribe(self.action_block) end
        self.action_block = nil
        if self.grapple_block then Events:Unsubscribe(self.grapple_block) end
        self.grapple_block = nil
        Game:FireEvent("ply.grappling.enable")
    else
        self.action_block = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
        self.grapple_block = Events:Subscribe("SecondTick", self, self.SecondTick)
    end
    
    LocalPlayer:SetValue("GrapplehookEnabled", enabled)
end

function EquippableGrapplehook:StopUsing()

    local base_state = LocalPlayer:GetBaseState()

    if LocalPlayer:GetBaseState() == AnimationState.SReeledInIdle then
        Network:Send("EquippableGrapplehookResetPosition")
    end

    if base_state == AnimationState.SReelFlight then
        LocalPlayer:SetBaseState(AnimationState.SUprightIdle)
    end

end

-- Continuously disable it because it doesn't always work on first join
function EquippableGrapplehook:SecondTick()
    if not self.equipped then
        Game:FireEvent("ply.grappling.disable")
        if LocalPlayer:GetBaseState() == AnimationState.SReeledInIdle then
            self:StopUsing()
        end
    end
end

function EquippableGrapplehook:LocalPlayerInput(args)
    if self.blocked_actions[args.input] and not self.equipped then return false end
end

EquippableGrapplehook = EquippableGrapplehook()