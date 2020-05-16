class 'EquippableParachute'

function EquippableParachute:__init()

    self.equipped = false

    self.blocked_actions = 
    {
        [Action.DeployParachuteWhileReelingAction] = true,
        [Action.ExitToStuntposParachute] = true,
        [Action.ParachuteOpenClose] = true,
        [Action.StuntposToParachute] = true,
        [Action.ActivateParachuteThrusters] = true
    }

    self:ToggleEnabled(false)

    Network:Subscribe(var("items/ToggleEquippedParachute"):get(), self, self.ToggleEquipped)
end

function EquippableParachute:GetEquipped()
    return self.equipped
end

function EquippableParachute:ToggleEquipped(args)
    self.equipped = args.equipped

    self:ToggleEnabled(self.equipped)
end

function EquippableParachute:ToggleEnabled(enabled)
    if enabled then
        if self.action_block then Events:Unsubscribe(self.action_block) end
        self.action_block = nil
        Game:FireEvent("ply.parachute.enable")
    else
        self.action_block = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
        Game:FireEvent("ply.parachute.disable")
    end
end

function EquippableParachute:LocalPlayerInput(args)

    if self.blocked_actions[args.input] and not self.equipped and not LocalPlayer:GetValue("StuntingVehicle") then
        return false
    end
end

EquippableParachute = EquippableParachute()