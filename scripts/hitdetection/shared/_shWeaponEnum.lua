class "WeaponEnum"

function WeaponEnum:__init()
    self.MachineGun = 1
    self.Handgun = 2
    self.Assault = 3
    self.BubbleGun = 4
    self.GrenadeLauncher = 5
    self.Revolver = 6
    self.RocketLauncher = 7
    self.SMG = 8
    self.Sniper = 9
    self.SawnOffShotgun = 10
    self.Shotgun = 11

    -- Vehicle Weapons
    self.V_Minigun = 12--26
    self.V_Rockets = 13--116
    self.V_Cannon = 14--134
    self.V_MachineGun = 15--28
    self.V_Minigun_Warmup = 16
    self.V_Cannon_Slow = 17

    -- Drone weapons
    self.Drone_MachineGun = 18
    self.Drone_Rockets = 19

    self.descriptions = {
        [self.MachineGun] = "Machine Gun",
        [self.Handgun] = "Handgun",
        [self.Assault] = "Assault Rifle",
        [self.BubbleGun] = "Bubble Gun",
        [self.GrenadeLauncher] = "Grenade Launcher",
        [self.Revolver] = "Revolver",
        [self.RocketLauncher] = "Rocket Launcher",
        [self.SMG] = "SMG",
        [self.Sniper] = "Sniper Rifle",
        [self.SawnOffShotgun] = "Sawn-Off Shotgun",
        [self.Shotgun] = "Shotgun",
        [self.V_Minigun] = "Vehicle Minigun",
        [self.V_Rockets] = "Vehicle Rockets",
        [self.V_Cannon] = "Vehicle Auto Cannon",
        [self.V_MachineGun] = "Vehicle Machine Gun",
        [self.V_Minigun_Warmup] = "Vehicle Minigun",
        [self.V_Cannon_Slow] = "Vehicle Auto Cannon",
        [self.Drone_MachineGun] = "Drone Machine Gun",
        [self.Drone_Rockets] = "Drone Rockets"
    }

    --] li""t is on https://wiki.jc-mp.com/Lua/Shared/Weapon
    self.enum_to_weapon_id_mapping = {
        [self.MachineGun] = 28,
        [self.Handgun] = 2,
        [self.Assault] = 11,
        [self.BubbleGun] = 43,
        [self.GrenadeLauncher] = 17,
        [self.Revolver] = 4,
        [self.RocketLauncher] = 16,
        [self.SMG] = 5,
        [self.Sniper] = 14,
        [self.SawnOffShotgun] = 6,
        [self.Shotgun] = 13
    }

    self.weapon_id_to_enum_mapping = {}
    for weapon_enum, weapon_id in pairs(self.enum_to_weapon_id_mapping) do
        self.weapon_id_to_enum_mapping[weapon_id] = weapon_enum
    end
end

function WeaponEnum:GetDescription(weapon_enum)
    return self.descriptions[weapon_enum]
end

function WeaponEnum:GetWeaponId(weapon_enum)
    return self.enum_to_weapon_id_mapping[weapon_enum]
end

function WeaponEnum:GetByWeaponId(weapon_id)
    return self.weapon_id_to_enum_mapping[weapon_id]
end


WeaponEnum = WeaponEnum()
