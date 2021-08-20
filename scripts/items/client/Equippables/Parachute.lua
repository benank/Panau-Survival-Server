class 'EquippableParachute'

function EquippableParachute:__init()

    self.equipped = false
    self.sync_timer = Timer()
    self.velocity_set_timer = Timer()
    self.dura_change = 0
    self.boost_amount = 0.75
    self.players_with_thrusters = {}

    self.thrusting = false
    
    self.blocked_actions = 
    {
        [Action.DeployParachuteWhileReelingAction] = true,
        [Action.ExitToStuntposParachute] = true,
        [Action.ParachuteOpenClose] = true,
        [Action.StuntposToParachute] = true
    }

    self:ToggleEnabled(false)

    Network:Subscribe(var("items/ToggleEquippedParachute"):get(), self, self.ToggleEquipped)
    Events:Subscribe("PostTick", self, self.PostTick)
end

function EquippableParachute:GetEquipped()
    return self.equipped
end

function EquippableParachute:ToggleEquipped(args)
    self.equipped = args.equipped
    self.name = args.name

    self.thrusting = false
    self.uid = args.uid
    
    if not self.equipped then
        Network:Send("items/DeactivateParaThrusters")
    end

    self:ToggleEnabled(self.equipped)
end

function EquippableParachute:ToggleEnabled(enabled)
    
    if self.name ~= "RocketPara" or not enabled then
        if self.thruster_input then
            self.thruster_input = Events:Unsubscribe(self.thruster_input)
        end
    end
    
    if enabled then
        if self.action_block then Events:Unsubscribe(self.action_block) end
        self.action_block = nil
        
        if self.name == "RocketPara" then
            self.thruster_input = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInputThrusters)
        end
        
        Game:FireEvent("ply.parachute.enable")
    else

        if LocalPlayer:GetBaseState() == AnimationState.SParachute then
            LocalPlayer:SetBaseState(AnimationState.SFallToSkydive)
        end

        self.action_block = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
        Game:FireEvent("ply.parachute.disable")

    end
end

function EquippableParachute:CheckPlayerRocketPara(p)
    local id = p:GetId()

    if self.players_with_thrusters[id] and not p:GetValue("ThrustersActive") then
        
        for _, effect in pairs(self.players_with_thrusters[id].effects) do
            effect:Remove()
        end

        self.players_with_thrusters[id] = nil
    elseif not self.players_with_thrusters[id] and p:GetValue("ThrustersActive") then
        local effects = {}

        local num_effects = 2
        for i = 1, num_effects do
            effects[i] = ClientEffect.Create(AssetLocation.Game, {
                position = p:GetPosition(),
                angle = p:GetAngle(),
                effect_id = 427
            })
        end

        self.players_with_thrusters[id] = 
        {
            effects = effects,
            player = p
        }
    end
end

function EquippableParachute:PostTick(args)

    if self.sync_timer:GetSeconds() > 2 and self.dura_change > 0 then
        Network:Send(var("items/ParaDecreaseDura"):get(), {uid = self.uid, change = math.ceil(self.dura_change)})
        
        self.sync_timer:Restart()
        self.dura_change = 0
    end

    if self.boosting and not self.boosting_synced then

        Network:Send("items/ActivateParaThrusters")
        self.boosting_synced = true
    elseif not self.boosting and self.boosting_synced then

        Network:Send("items/DeactivateParaThrusters")
        self.boosting_synced = false
    end

    self:CheckPlayerRocketPara(LocalPlayer)
    for p in Client:GetStreamedPlayers() do
        self:CheckPlayerRocketPara(p)
    end

    for id, data in pairs(self.players_with_thrusters) do

        if IsValid(data.player) and data.player:GetValue("ThrustersActive") then

            local offsets = {Vector3(0.2, 2, 0), Vector3(-0.2, 2, 0)}
            for _, effect in pairs(data.effects) do

                effect:SetPosition(data.player:GetPosition() + data.player:GetAngle() * offsets[_])
                effect:SetAngle(data.player:GetAngle())

            end

        else
            for _, effect in pairs(self.players_with_thrusters[id].effects) do
                effect:Remove()
            end
            self.players_with_thrusters[id] = nil
        end

    end

    if self.boosting then
        self.dura_change = self.dura_change + args.delta
    end

end

function EquippableParachute:Thrusters(args)
    
    local bs = LocalPlayer:GetBaseState()
    if bs ~= AnimationState.SParachute then
        self.boosting = false
        return false
    end

    local forward = LocalPlayer:GetAngle() * Vector3.Forward
    local speed = -(-LocalPlayer:GetAngle() * LocalPlayer:GetLinearVelocity()).z
    
    if self.velocity_set_timer:GetSeconds() > 0.05 then
        LocalPlayer:SetLinearVelocity(LocalPlayer:GetLinearVelocity() + forward * self.boost_amount)
        self.velocity_set_timer:Restart()
    end

    self.boosting = true

    if self.boost_timer then 
        Timer.Clear(self.boost_timer)
        self.boost_timer = nil
    end

    self.boost_timer = Timer.SetTimeout(100, function()
        self.boosting = false
        self.boost_timer = nil
    end)
    
    return false

end

function EquippableParachute:LocalPlayerInputThrusters(args)
    if self.equipped and args.input == Action.ActivateParachuteThrusters and self.name == "RocketPara" then
        self:Thrusters(args)
    end
end

function EquippableParachute:LocalPlayerInput(args)

    if self.thrusters_active and self.thruster_timer:GetSeconds() > 0.1 then
        -- Disable thrusters
        self.thrusters_active = false
    end
    
    if self.blocked_actions[args.input] and not self.equipped and not LocalPlayer:GetValue("StuntingVehicle") then
        return false
    end
end

EquippableParachute = EquippableParachute()