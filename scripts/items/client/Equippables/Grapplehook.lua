class 'EquippableGrapplehook'

function EquippableGrapplehook:__init()

    self.equipped = false

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

    Network:Subscribe("items/ToggleEquippedGrapplehook", self, self.ToggleEquipped)
end

function EquippableGrapplehook:GetEquipped()
    return self.equipped
end

function EquippableGrapplehook:ToggleEquipped(args)
    self.equipped = args.equipped

    self:ToggleEnabled(self.equipped)
end

function EquippableGrapplehook:ToggleEnabled(enabled)
    if enabled then
        if self.action_block then Events:Unsubscribe(self.action_block) end
        self.action_block = nil
        Game:FireEvent("ply.grappling.enable")
    else
        self.action_block = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
        Game:FireEvent("ply.grappling.disable")
    end
end

function EquippableGrapplehook:LocalPlayerInput(args)
    if self.action_block[args.input] and not self.equipped then return false end
end

EquippableGrapplehook = EquippableGrapplehook()