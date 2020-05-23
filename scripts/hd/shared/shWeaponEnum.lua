class "WeaponEnum"

function WeaponEnum:__init()
    self.MachineGun = 1
    self.PanayRocketLauncher = 2
    self.RocketLauncher = 3

    self.descriptions = {
        [self.MachineGun] = "Machine Gun",
        [self.PanayRocketLauncher] = "Panay Rocket Launcher",
        [self.RocketLauncher] = "Rocket Launcher"
    }

    -- list is on https://wiki.jc-mp.com/Lua/Shared/Weapon
    self.enum_to_weapon_id_mapping = {
        [self.MachineGun] = 28,
        [self.PanayRocketLauncher] = 66,
        [self.RocketLauncher] = 16
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
