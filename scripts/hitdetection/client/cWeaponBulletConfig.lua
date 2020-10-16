class 'cWeaponBulletConfig'

function cWeaponBulletConfig:__init()

    local fixed_reticle_angle_func = function(cam_angle, v_angle)

        local initial_pos = LocalPlayer:GetBonePosition(BoneEnum.RightHand)
        
        -- Fixed reticle
        local angle = v_angle * Angle(0, -math.pi * 0.0425, 0)
        local ray = Physics:Raycast(initial_pos, angle * Vector3.Forward, 0, 1000)

        local pos, on_screen = Render:WorldToScreen(ray.position)

        local cam_ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 1000)
        local cam_angle = Angle.FromVectors(Vector3.Forward, cam_ray.position - initial_pos)

        local cam_pos, cam_on_screen = Render:WorldToScreen(cam_ray.position)

        local middle = Render.Size / 2

        local max_table = 
        {
            [30] = {y = 200, x = 100},
            [34] = {y = 200, x = 100},
            [62] = {y = 900, x = 400},
            [64] = {y = 900, x = 400}
        }

        local v = LocalPlayer:GetVehicle()

        local y_max = 200
        local x_max = 100

        if IsValid(v) and max_table[v:GetModelId()] then
            y_max = max_table[v:GetModelId()].y
            x_max = max_table[v:GetModelId()].x
        end

        if on_screen and cam_on_screen
        and math.abs(cam_pos.x - pos.x) < x_max
        and math.abs(cam_pos.y - pos.y) < y_max then
            return cam_angle
        else
            return angle
        end

    end

    self.weapon_bullets = {
        [WeaponEnum.MachineGun] = 
        {
            type = ProjectileBullet,
            speed = 650,
            bloom = 1.2,
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
            bloom = 1.25,
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
            speed = 600,
            bloom = 5,
            bullet_size = 0.25
        },
        [WeaponEnum.RocketLauncher] = 
        {
            type = ProjectileBullet,
            speed = 100,
            bloom = 0,
            bullet_size = 0,
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
            speed = 1500,
            bloom = 4.5,
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
            speed = 600,
            bloom = 0.3,
            bullet_size = 0.2,
            indicator = true,
            angle = fixed_reticle_angle_func
        },
        [WeaponEnum.V_Minigun_Warmup] = 
        {
            type = ProjectileBullet,
            speed = 600,
            bloom = 0.75,
            bullet_size = 0.3,
            indicator = true,
            angle = function(cam_angle, v_angle, model_id)
                if model_id == 69 then
                    return cam_angle
                else
                    return fixed_reticle_angle_func(cam_angle, v_angle)
                end
            end
        },
        [WeaponEnum.V_Rockets] = 
        {
            type = ProjectileBullet,
            speed = 300,
            bloom = 0,
            bullet_size = 0,
            splash = true,
            indicator = true,
            angle = fixed_reticle_angle_func
        },
        [WeaponEnum.V_Cannon] = 
        {
            type = ProjectileBullet,
            speed = 300,
            bloom = 6,
            bullet_size = 0.5,
            splash = true,
            indicator = true,
            angle = fixed_reticle_angle_func
        },
        [WeaponEnum.V_Cannon_Slow] = 
        {
            type = ProjectileBullet,
            speed = 300,
            bloom = 10,
            bullet_size = 0.5,
            splash = true,
            indicator = true,
            angle = function(cam_angle, v_angle, model_id)
                if model_id == 75 then
                    return cam_angle
                else
                    return fixed_reticle_angle_func(cam_angle, v_angle)
                end
            end
        },
        [WeaponEnum.V_MachineGun] = 
        {
            type = ProjectileBullet,
            speed = 500,
            bloom = 1.5,
            bullet_size = 0.5,
            indicator = true,
            angle = function(cam_angle, v_angle)
                return cam_angle
            end
        },
        [WeaponEnum.Drone_MachineGun] = -- Drone bullets, not to be used by LocalPlayer
        {
            type = ProjectileBullet,
            speed = 400,
            bloom = 0,
            bullet_size = 0.03,
            angle = function(angle)
                return angle
            end
        }
    }

end

function cWeaponBulletConfig:GetByWeaponEnum(enum)
    return self.weapon_bullets[enum]
end

cWeaponBulletConfig = cWeaponBulletConfig()