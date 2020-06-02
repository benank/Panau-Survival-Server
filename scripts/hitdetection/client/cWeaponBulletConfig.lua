class 'cWeaponBulletConfig'

function cWeaponBulletConfig:__init()

    self.weapon_bullets = {
        [WeaponEnum.MachineGun] = 
        {
            type = ProjectileBullet,
            speed = 400,
            bloom = 1.5,
            bullet_size = 0.5 -- Size of visual bullet only
        },
        [WeaponEnum.Revolver] = 
        {
            type = ProjectileBullet,
            speed = 300,
            bloom = 5,
            bullet_size = 0.25
        },
        [WeaponEnum.Handgun] = 
        {
            type = ProjectileBullet,
            speed = 350,
            bloom = 1,
            bullet_size = 0.1
        },
        [WeaponEnum.BubbleGun] = 
        {
            type = ProjectileBullet,
            speed = 1,
            bloom = 50,
            bullet_size = 0
        },
        [WeaponEnum.RocketLauncher] = 
        {
            type = ProjectileBullet,
            speed = 550,
            bloom = 0,
            bullet_size = 0
        }
    }

end

function cWeaponBulletConfig:GetByWeaponEnum(enum)
    return self.weapon_bullets[enum]
end

cWeaponBulletConfig = cWeaponBulletConfig()