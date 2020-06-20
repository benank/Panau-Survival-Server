class 'cRunSwimSpeed'

function cRunSwimSpeed:__init()

    self.base_swim_speed = 3.4
    self.base_run_speed = 8.4

    self.swim_states = 
    {
        [AnimationState.SSwimNavigation] = true,
        [AnimationState.SSwimDiveNavigation] = true
    }

    self.run_states = 
    {
        [AnimationState.SDash] = true
    }

    self.perks = -- 1: swim 2: sprint
    {
        [21] = {[1] = 0.2, [2] = 0.2},
        [71] = {[1] = 0.2, [2] = 0.2},
        [94] = {[1] = 0.2, [2] = 0.2},
        [124] = {[1] = 0.2, [2] = 0.2},
        [146] = {[1] = 0.2, [2] = 0.2},
    }

    Events:Subscribe("PostTick", self, self.PostTick)

end

function cRunSwimSpeed:GetPerkMods()

    local perk_mods = {[1] = 1, [2] = 1}

    local perks = LocalPlayer:GetValue("Perks")

    if perks then

        for perk_id, perk_mod_data in pairs(self.perks) do
            local choice = perks.unlocked_perks[perk_id]
            if choice and perk_mod_data[choice] then
                perk_mods[choice] = perk_mods[choice] + perk_mod_data[choice]
            end
        end

    end

    return perk_mods

end

function cRunSwimSpeed:PostTick(args)

    -- Use PostTick instead of LocalPlayerInput so people can auto swim/run with chat open

    local base_state = LocalPlayer:GetBaseState()
    local speed = math.abs(-(-LocalPlayer:GetAngle() * LocalPlayer:GetLinearVelocity()).z)

    local perk_mods = self:GetPerkMods()

    if self.swim_states[base_state] and perk_mods[1] > 1 and speed < self.base_swim_speed * perk_mods[1] and speed > 3 then

        local spine_pos = LocalPlayer:GetBonePosition("ragdoll_Hips")
        if spine_pos.y > 200.25 then return end
        
        local new_swim_speed = self.base_swim_speed * perk_mods[1]

        LocalPlayer:SetLinearVelocity(LocalPlayer:GetAngle() * Vector3.Forward * 10)

    elseif self.run_states[base_state] and perk_mods[2] > 1 and speed < self.base_run_speed * perk_mods[2] and speed > 3 then

        local ray = Physics:Raycast(LocalPlayer:GetPosition() + Vector3.Up, Vector3.Down, 0, 1.5)
        if ray.distance == 1.5 then return end

        local ray2 = Physics:Raycast(LocalPlayer:GetPosition() + Vector3(0, 0.1, 0), LocalPlayer:GetAngle() * Vector3.Forward, 0, 1)
        if ray2.distance < 1 then return end

        LocalPlayer:SetLinearVelocity(LocalPlayer:GetLinearVelocity() * 1.05)

    end

end

cRunSwimSpeed = cRunSwimSpeed()