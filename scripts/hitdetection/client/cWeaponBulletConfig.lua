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
        [WeaponEnum.Handgun] = 
        {
            type = ProjectileBullet,
            speed = 350,
            bloom = 1,
            bullet_size = 0.1
        },
        [WeaponEnum.Assault] = 
        {
            type = ProjectileBullet,
            speed = 350,
            bloom = 1.5,
            bullet_size = 0.4 -- Size of visual bullet only
        },
        [WeaponEnum.BubbleGun] = 
        {
            type = ProjectileBullet,
            speed = 1,
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
            speed = 300,
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
            speed = 500,
            bloom = 0.5,
            bullet_size = 0.1
        },
        [WeaponEnum.Sniper] = 
        {
            type = ProjectileBullet,
            speed = 750,
            bloom = 5,
            bullet_size = 2
        },
        [WeaponEnum.SawnOffShotgun] = 
        {
            type = ProjectileBullet,
            speed = 200,
            bloom = 3,
            bullet_size = 0.1,
            multi_shot = 3
        },
        [WeaponEnum.Shotgun] = 
        {
            type = ProjectileBullet,
            speed = 200,
            bloom = 2,
            bullet_size = 0.2,
            multi_shot = 6
        },
    }

end

function cWeaponBulletConfig:GetByWeaponEnum(enum)
    return self.weapon_bullets[enum]
end

cWeaponBulletConfig = cWeaponBulletConfig()