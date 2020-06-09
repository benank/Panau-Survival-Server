class 'cWeaponBulletConfig'

function cWeaponBulletConfig:__init()

    self.weapon_bullets = {
        [WeaponEnum.MachineGun] = 
        {
            type = ProjectileBullet,
            speed = 600,
            bloom = 1.5,
            bullet_size = 0.5 -- Size of visual bullet only
        },
        [WeaponEnum.Handgun] = 
        {
            type = ProjectileBullet,
            speed = 550,
            bloom = 1,
            bullet_size = 0.1
        },
        [WeaponEnum.Assault] = 
        {
            type = ProjectileBullet,
            speed = 550,
            bloom = 1.5,
            bullet_size = 0.4 -- Size of visual bullet only
        },
        [WeaponEnum.BubbleGun] = 
        {
            type = ProjectileBullet,
            speed = 4,
            bloom = 50,
            bullet_size = 0
        },
        [WeaponEnum.GrenadeLauncher] = 
        {
            type = GrenadeBullet,
            speed = 30,
            bloom = 0,
            bullet_size = 0.1,
            splash = true
        },
        [WeaponEnum.Revolver] = 
        {
            type = ProjectileBullet,
            speed = 500,
            bloom = 5,
            bullet_size = 0.25
        },
        [WeaponEnum.RocketLauncher] = 
        {
            type = ProjectileBullet,
            speed = 100,
            bloom = 0,
            bullet_size = 1,
            splash = true
        },
        [WeaponEnum.SMG] = 
        {
            type = ProjectileBullet,
            speed = 700,
            bloom = 0.75,
            bullet_size = 0.1
        },
        [WeaponEnum.Sniper] = 
        {
            type = ProjectileBullet,
            speed = 1000,
            bloom = 5,
            bullet_size = 2
        },
        [WeaponEnum.SawnOffShotgun] = 
        {
            type = ProjectileBullet,
            speed = 400,
            bloom = 1.5,
            bullet_size = 0.1,
            multi_shot = 3
        },
        [WeaponEnum.Shotgun] = 
        {
            type = ProjectileBullet,
            speed = 400,
            bloom = 1,
            bullet_size = 0.2,
            multi_shot = 3
        },
        -- Vehicle Weapons
        [WeaponEnum.V_Minigun] = 
        {
            type = ProjectileBullet,
            speed = 800,
            bloom = 0.5,
            bullet_size = 0.2,
            indicator = true,
            angle = function(cam_angle, v_angle)
                return v_angle * Angle(0, -math.pi * 0.0425, 0)
            end
        },
        [WeaponEnum.V_Rockets] = 
        {
            type = ProjectileBullet,
            speed = 400,
            bloom = 0,
            bullet_size = 0,
            splash = true,
            indicator = true,
            angle = function(cam_angle, v_angle)
                return v_angle * Angle(0, -math.pi * 0.04, 0)
            end
        },
        [WeaponEnum.V_Cannon] = 
        {
            type = ProjectileBullet,
            speed = 500,
            bloom = 5,
            bullet_size = 1.0,
            splash = true,
            indicator = true,
            angle = function(cam_angle, v_angle)
                return v_angle * Angle(0, -math.pi * 0.04, 0)
            end
        },
        [WeaponEnum.V_MachineGun] = 
        {
            type = ProjectileBullet,
            speed = 700,
            bloom = 1,
            bullet_size = 0.5,
            angle = function(cam_angle, v_angle)
                return cam_angle
            end
        }
    }

end

function cWeaponBulletConfig:GetByWeaponEnum(enum)
    return self.weapon_bullets[enum]
end

cWeaponBulletConfig = cWeaponBulletConfig()