class 'WeaponManager'

function WeaponManager:__init()

    local weapon = LocalPlayer:GetEquippedWeapon()
    self.current_ammo = 0
    self.current_weapon = weapon.id
    self.default_weapon = self.current_weapon
    self.cheat_timer = Timer()
    self.init_timer = Timer()
    self.equipped = false
    self.enabled = false


    Network:Subscribe("items/ToggleWeaponEquipped", self, self.ToggleWeaponEquipped)
    Network:Subscribe("items/ForceWeaponSwitch", self, self.ForceWeaponSwitch)
    Events:Subscribe("PostTick", self, self.PostTick)
    Events:Subscribe("LoadingComplete", self, self.LoadingComplete)
    Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
end

function WeaponManager:LocalPlayerInput(args)
    if args.input == Action.FireRight then
        if not self.equipped or not self.enabled then return false end
    end
end

function WeaponManager:LoadingComplete()
    self:ForceInputWeaponSwitch(5000)
end

function WeaponManager:ToggleWeaponEquipped(args)
    self.equipped = args.equipped
end

function WeaponManager:PostTick(args)

    if LocalPlayer:GetValue("Loading") then return end
    if self.init_timer:GetSeconds() < 5 then return end

    local weapon = LocalPlayer:GetEquippedWeapon()
    if not weapon then return end
    if weapon.id == self.default_weapon then return end

    if not self.equipped then return end

    local current_ammo = self:GetCurrentAmmo()

    if self:GetTotalAmmoInWeapon(weapon) > current_ammo and self.cheat_timer:GetSeconds() > 1 then
        -- kick for ammo hax
        Network:Send("items/Cheating", {reason = "ammo hacks"})
        self.cheat_timer:Restart()
        return
    end

    if weapon.id ~= self.current_weapon and self.cheat_timer:GetSeconds() > 1 then
        -- kick for weapon hax
        Network:Send("items/Cheating", {reason = "weapon hacks"})
        self.cheat_timer:Restart()
        return
    end

    if self:GetTotalAmmoInWeapon(weapon) >= 0 and self:GetTotalAmmoInWeapon(weapon) < current_ammo then
        Network:Send("Items/FireWeapon", {ammo = current_ammo})
        self:SetCurrentAmmo(current_ammo - 1)
    end
        

end

function WeaponManager:SetCurrentAmmo(ammo)
    self.current_ammo = xor_cipher(ammo)
end

function WeaponManager:GetCurrentAmmo()
    return tonumber(xor_cipher(self.current_ammo))
end

function WeaponManager:GetTotalAmmoInWeapon(weapon)
    return weapon.ammo_clip + weapon.ammo_reserve
end

-- Forces the weapon to come out (and go into player's hands rather than under their legs lol)
function WeaponManager:ForceWeaponSwitch(args)

    self.init_timer:Restart()
    self.current_weapon = args.weapon
    self:SetCurrentAmmo(args.ammo)
    self.enabled = true

    Timer.SetTimeout(1500, function()
        self:ForceInputWeaponSwitch(200)
    end)
end

function WeaponManager:ForceInputWeaponSwitch(time)

    local input_sub = Events:Subscribe("InputPoll", function(args)
        local random = math.random()
        if random < 0.3 then
            Input:SetValue(Action.PrevWeapon, 1)
        elseif random < 0.6 then
            Input:SetValue(Action.NextWeapon, 1)
        else
            Input:SetValue(Action.SwitchWeapon, 1)
        end
    end)

    Timer.SetTimeout(time, function()
        Events:Unsubscribe(input_sub)
    end)
end

WeaponManager = WeaponManager()