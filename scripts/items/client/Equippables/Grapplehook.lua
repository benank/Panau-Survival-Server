class 'EquippableGrapplehook'

function EquippableGrapplehook:__init()

    self.equipped = false
    self.sync_timer = Timer()
    self.dura_change = 0

    self.blocked_actions = 
    {
        [Action.DecGrappleDistance] = true,
        [Action.FireGrapple] = true,
        [Action.GrapplingAction] = true,
        [Action.IncGrappleDistance] = true,
        [Action.ReeledInJumpAction] = true,
        [Action.ReeledInReleaseAction] = true,
        [Action.DeployParachuteWhileReelingAction] = true
    }
    
    self:ToggleEnabled(false)

    Events:Subscribe("Render", self, self.Render)
    Network:Subscribe(var("items/ToggleEquippedGrapplehook"):get(), self, self.ToggleEquipped)
end

function EquippableGrapplehook:Render(args)
    
    if self.sync_timer:GetSeconds() > 2 and self.dura_change > 0 then
        if EquippableRocketGrapple:GetEquipped() then
            Network:Send(var("items/RocketGrappleDecreaseDura"):get(), {change = math.ceil(self.dura_change)})
        else
            Network:Send(var("items/GrapplehookDecreaseDura"):get(), {change = math.ceil(self.dura_change)})
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

    -- Basic grapplehook durability
    if self.grappling then
        self.dura_change = self.dura_change + args.delta
    end

end

function EquippableGrapplehook:GetEquipped()
    return self.equipped
end

function EquippableGrapplehook:ToggleEquipped(args)
    self.equipped = args.equipped
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