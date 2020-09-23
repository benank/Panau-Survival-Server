class 'cHitDetection'

function cHitDetection:__init()

    self.pending = {}
    self.sync_timer = Timer()

    self.old_health = LocalPlayer:GetHealth()
    self.max_damage_screen_alpha = 150
    self.damage_screen_time = 1

    Events:Subscribe(var("PostRender"):get(), self, self.PostRender)

    Events:Subscribe(var("HitDetection/Explosion"):get(), self, self.Explosion)
    Events:Subscribe(var("HitDetection/ExplosionHitDrone"):get(), self, self.ExplosionHitDrone)
    Network:Subscribe(var("HitDetection/KnockdownEffect"):get(), self, self.KnockdownEffect)

end

function cHitDetection:KnockdownEffect(args)
    self:ApplyKnockback(args.source, args.amount)
end

function cHitDetection:ApplyKnockback(source, amount)

    local base_state = LocalPlayer:GetBaseState()
    local local_pos = LocalPlayer:GetPosition()

    if not LocalPlayer:InVehicle() 
    and not LocalPlayer:GetValue("StuntingVehicle")
    and base_state ~= AnimationState.SReeledInIdle
    and base_state ~= AnimationState.SReelFlight
    and base_state ~= AnimationState.SHangstuntIdle then
        LocalPlayer:SetRagdollLinearVelocity(
            LocalPlayer:GetLinearVelocity() + ((local_pos - source):Normalized() + Vector3(0, 1.5, 0)) * amount)
    end

end

function cHitDetection:CheckHealth()
    -- Called on PostTick to check for health changes and apply a red screen

    if LocalPlayer:GetValue("Loading") then
        self.old_health = LocalPlayer:GetHealth()
        return
    end

    local current_health = LocalPlayer:GetHealth()

    if current_health < self.old_health and self.old_health - current_health > 0.01 then

        if self.damage_screen_timer then
            self.damage_screen_timer:Restart()
        else
            self.damage_screen_timer = Timer()
        end
        
    end

    self.old_health = current_health

    if self.damage_screen_timer and self.damage_screen_timer:GetSeconds() < self.damage_screen_time then
        local alpha = self.max_damage_screen_alpha - 
            self.max_damage_screen_alpha * (self.damage_screen_timer:GetSeconds() / self.damage_screen_time)
        Render:FillArea(Vector2(0,0), Render.Size, Color(255, 0, 0, alpha))
    end

end

-- Explosions from items, like mines, that hit drones
function cHitDetection:ExplosionHitDrone(args)

    local my_dist = LocalPlayer:GetPosition():Distance(args.drone_position)

    for p in Client:GetStreamedPlayers() do
        if p:GetPosition():Distance(args.drone_position) < my_dist then return end
    end

    local explosive_data = WeaponDamage.ExplosiveBaseDamage[args.type]

    if explosive_data then

        local radius = explosive_data.radius * 1.5 -- Make it larger to account for possible perks
        args.radius = radius

        if args.drone_distance > radius then return end

        local from_pos = args.position + Vector3.Up
        local to_pos = args.drone_position
        local diff = (to_pos - from_pos):Normalized()
        local ray = Physics:Raycast(from_pos, diff, 0, args.drone_distance)

        local in_fov = math.abs(ray.distance - args.drone_distance) < 2
    
        local dist = args.drone_distance
        local percent_modifier = math.max(0, 1 - dist / radius)
    
        if percent_modifier == 0 then return end

        local knockback_effect = explosive_data.knockback * percent_modifier

        Network:Send(var("HitDetectionSyncExplosionDrone"):get(), {
            position = args.position,
            drone_position = args.drone_position,
            drone_id = args.drone_id,
            type = args.type,
            in_fov = in_fov,
            attacker_id = args.attacker_id,
            knockback_effect = in_fov and knockback_effect
        })

    end

end

-- Explosions from items, like mines
function cHitDetection:Explosion(args)

    local explosive_data = WeaponDamage.ExplosiveBaseDamage[args.type]

    if explosive_data then

        local radius = explosive_data.radius * 1.5 -- Make it larger to account for possible perks
        args.radius = radius
        self:CheckForVehicleExplosionDamage(args)

        if LocalPlayer:GetValue(var("InSafezone"):get()) then return end
        if LocalPlayer:GetValue("Invincible") then return end

        local from_pos = args.position + Vector3.Up
        local to_pos = LocalPlayer:GetBonePosition(var("ragdoll_Spine"):get())
        local diff = (to_pos - from_pos):Normalized()
        local ray = Physics:Raycast(from_pos, diff, 0, 300, false)

        local in_fov = ray.entity and ray.entity.__type == "LocalPlayer"
    
        local dist = args.position:Distance(args.local_position)
        local percent_modifier = math.max(0, 1 - dist / radius)
    
        if percent_modifier == 0 then return end

        local knockback_effect = explosive_data.knockback * percent_modifier

        local base_state = LocalPlayer:GetBaseState()

        if in_fov then
            self:ApplyKnockback(args.position, knockback_effect)
        end

        Network:Send(var("HitDetectionSyncExplosion"):get(), {
            position = args.position,
            local_position = args.local_position,
            type = args.type,
            in_fov = in_fov,
            attacker_id = args.attacker_id
        })

    end

end

function cHitDetection:CheckForVehicleExplosionDamage(args)

    -- First, check to see if we are the closest player. If we are, then we will do the checks

    local my_dist = LocalPlayer:GetPosition():Distance(args.position)

    for p in Client:GetStreamedPlayers() do
        if p:GetPosition():Distance(args.position) < my_dist then return end
    end

    args.radius = args.radius * 2

    -- Okay, we are the closest. Now lets see if this thing hit any vehicles

    local hit_vehicles = {}

    for v in Client:GetVehicles() do

        local v_pos = v:GetPosition()
        local dist = v_pos:Distance(args.position)
        local dir = (v_pos - args.position + Vector3(0, 0.1, 0)):Normalized()
        local ray = Physics:Raycast(args.position, dir, 0, args.radius)

        if dist < args.radius and v:GetHealth() > 0 and not v:GetValue("Destroyed") then
            hit_vehicles[v:GetId()] = 
            {
                in_fov = ray.entity and ray.entity.__type == "Vehicle" and ray.entity == v,
                dist = dist,
                hit_dir = (v_pos - args.position):Normalized()
            }
        end

    end

    if count_table(hit_vehicles) > 0 then
        Network:Send(var("HitDetection/VehicleExplosionHit"):get(), 
        {
            hit_vehicles = hit_vehicles, 
            token = TOKEN:get(), 
            type = args.type,
            position = args.position,
            attacker_id = args.attacker_id
        })
    end

end

function cHitDetection:PostRender(args)

    self:CheckHealth()
    -- Collision checks for hitting things when in ragdoll

    -- Sync damage every 100ms
    if self.sync_timer:GetMilliseconds() > 100 then

        if count_table(self.pending) > 0 then
            
            Network:Send(var("HitDetectionSyncHit"):get(), {
                pending = self.pending
            })

            self.pending = {}
            self.sync_timer:Restart()

        end

    end


end

cHitDetection = cHitDetection()