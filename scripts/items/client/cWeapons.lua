class 'WeaponManager'

-- Encrypted weapon class for easy management
class 'CWeapon'

function CWeapon:__init(args)
    self.id = var(args.id)
    self.ammo = var(args.ammo)
end

function CWeapon:GetId()
    return tonumber(self.id:get())
end

function CWeapon:GetAmmo()
    return tonumber(self.ammo:get())
end

function CWeapon:SetAmmo(ammo)
    self.ammo:set(ammo)
end

function WeaponManager:__init()

    self.weapons = {} -- table of CWeapons

    self.cheat_timer = Timer()
    self.equipped = false
    self.enabled = false
    self.ready = false

    self.firing_actions = 
    {
        [Action.FireRight] = true,
        [Action.Fire] = true,
        [Action.FireLeft] = true,
        [Action.McFire] = true,
        [Action.VehicleFireLeft] = true,
        [Action.VehicleFireRight] = true
    }

    self.last_slot = 1

    Network:Subscribe(var("items/ToggleWeaponEquipped"):get(), self, self.ToggleWeaponEquipped)
    Network:Subscribe(var("items/ForceWeaponSwitch"):get(), self, self.ForceWeaponSwitch)
    Network:Subscribe(var("items/ForceWeaponZoomout"):get(), self, self.ForceWeaponZoomout)
    Events:Subscribe(var("PostTick"):get(), self, self.PostTick)
    Events:Subscribe(var("LocalPlayerInput"):get(), self, self.LocalPlayerInput)
    Events:Subscribe(var("LocalPlayerDeath"):get(), self, self.LocalPlayerDeath)
    Events:Subscribe(var("InputPoll"):get(), self, self.InputPoll)
    Events:Subscribe(var("LoadingFinished"):get(), self, self.LoadingFinished)
end

function WeaponManager:LoadingFinished()
    self:ForceInputWeaponSwitch(self.last_slot)
end

function WeaponManager:LocalPlayerDeath()
    self.ready = false
end

function WeaponManager:IsCurrentWeaponOutOfAmmo()
    local weapon = LocalPlayer:GetEquippedWeapon()
    
    local cweapon = self.weapons[weapon.id]
    if not cweapon then return true end

    return cweapon:GetAmmo() == 0
end

function WeaponManager:InputPoll(args)
    if Game:GetState() ~= GUIState.Game then return end
    if self:IsCurrentWeaponOutOfAmmo() and not LocalPlayer:InVehicle() then
        for action, _ in pairs(self.firing_actions) do
            Input:SetValue(action, 0)
        end
    end
end

function WeaponManager:LocalPlayerInput(args)
    if self.firing_actions[args.input] and not LocalPlayer:InVehicle() then
        if not self.equipped or not self.enabled then return false end
        
        -- Stop action when out of ammo to fix JC2MP sync bug
        -- You can fire rockets when 0 ammo because it appears on other clients' screens
        if self:IsCurrentWeaponOutOfAmmo() then return false end
    end
end

function WeaponManager:ToggleWeaponEquipped(args)
    self.equipped = args.equipped
    self.ready = false
end

function WeaponManager:PostTick(args)

    if LocalPlayer:GetValue("Loading") then return end

    local weapon = LocalPlayer:GetEquippedWeapon()
    if not weapon then return end

    local cweapon = self.weapons[weapon.id]
    if not cweapon then return end

    local current_ammo = cweapon:GetAmmo()

    -- Wait for player to equip weapon and load ammo into it
    if not self.ready and self:GetTotalAmmoInWeapon(weapon) ~= current_ammo then
        return
    end

    local current_weapon_id = cweapon:GetId()

    -- Weapon is equipped and we are ready
    if not self.ready and LocalPlayer:GetEquippedWeapon().id == current_weapon_id then
        self.ready = true
    end

    if not self.ready then return end
    if not self.equipped then return end

    if weapon.id ~= current_weapon_id 
    and self.cheat_timer:GetSeconds() > 1 then
        -- kick for weapon hax
        Network:Send("items/Cheating", 
        {
            reason = string.format("Weapon mismatch. Expected: %s, found: %s", tostring(current_weapon_id), tostring(weapon.id)),
            p_reason = "Weapon mismatch"
        })
        self.cheat_timer:Restart()
        return
    end

    if self:GetTotalAmmoInWeapon(weapon) > current_ammo 
    and self.cheat_timer:GetSeconds() > 1 then
        -- kick for ammo hax
        Network:Send("items/Cheating", 
        {
            reason = string.format("Ammo mismatch. Expected: %s, found: %s", tostring(current_ammo), tostring(self:GetTotalAmmoInWeapon(weapon))),
            p_reason = "Ammo mismatch"
        })
        self.cheat_timer:Restart()
        return
    end

    -- Weapon was fired
    if weapon.id == current_weapon_id and self:GetTotalAmmoInWeapon(weapon) >= 0 and self:GetTotalAmmoInWeapon(weapon) < current_ammo then
        Network:Send("Items/FireWeapon", {ammo = current_ammo})
        cweapon:SetAmmo(current_ammo - 1)
        self:FireWeapon()
    end

end

function WeaponManager:FireWeapon()
    Events:Fire(var("FireWeapon"):get())
end

function WeaponManager:GetTotalAmmoInWeapon(weapon)
    return weapon.ammo_clip + weapon.ammo_reserve
end

-- Forces the weapon to come out (and go into player's hands rather than under their legs lol)
function WeaponManager:ForceWeaponSwitch(args)

    if not self.weapons[args.weapon] then
        self.weapons[args.weapon] = CWeapon({
            id = args.weapon,
            ammo = args.ammo
        })
    else
        self.weapons[args.weapon]:SetAmmo(args.ammo)
    end

    self.enabled = true

    self.last_slot = args.slot

    if self.switching then return end
        self.switching = true

    Timer.SetTimeout(1000, function()
        self:ForceInputWeaponSwitch(args.slot)
        self.switching = false
    end)
    
end

function WeaponManager:ForceWeaponZoomout()

    -- Thanks to Alpha for showing me LocalPlayer:GetAimMode()
    if LocalPlayer:GetAimMode() == AimMode.Normal then return end

    local inputPollEvent

    inputPollEvent = Events:Subscribe("InputPoll", function()
        if Game:GetState() ~= GUIState.Game then
            return
        end

        Input:SetValue(Action.ShoulderCam, 1)

        if not inputPollEvent then
            return
        end

        inputPollEvent = Events:Unsubscribe(inputPollEvent)
    end)

end

function WeaponManager:ForceInputWeaponSwitch(slot)

    if LocalPlayer:GetValue("Loading") then return end

    if self.weapon_switch_input_sub then return end

    self.weapon_switch_input_sub = Events:Subscribe("InputPoll", function(args)

        if slot == WeaponSlot.Primary then
            Input:SetValue(Action.EquipTwohanded, 1)
        elseif slot == WeaponSlot.Right then
            Input:SetValue(Action.EquipRightSlot, 1)
        end

    end)

    Timer.SetTimeout(100, function()
        if self.weapon_switch_input_sub then
            self.weapon_switch_input_sub = Events:Unsubscribe(self.weapon_switch_input_sub)
        end
    end)

end

WeaponManager = WeaponManager()