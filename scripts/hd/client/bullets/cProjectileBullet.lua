class "ProjectileBullet"

function ProjectileBullet:__init(args)
    getter_setter(self, "active")
    self:SetActive(true)
    getter_setter(self, "id")
    self:SetId(args.id)
    self.weapon_enum = args.weapon_enum
    self.velocity = args.velocity
    self.bloom = args.bloom or 0

    self.is_splash = args.is_splash
    self.life_timer = Timer()

    self.initial_position = Camera:GetPosition()
    self.current_position = Copy(self.initial_position)
    self.last_raycast_position = Copy(self.initial_position)

    local target_position = Camera:GetPosition() + (Camera:GetAngle() * (Vector3.Forward * 80 + self:GetBloom()))
    self.angle = Angle.FromVectors(Vector3.Forward, target_position - Camera:GetPosition())
    self.angle.roll = 0

    self.max_lifetime_distance = 1000 -- if bullet travels farther than this distance then it gets removed
    self.total_distance_covered = 0
    self.distance_covered_since_last_raycast = 0
    self.raycast_distance = 10
    self.initial_probe = true

    self.lock_position = false
end

function ProjectileBullet:GetBloom()
    return self.bloom > 0 and 
    Vector3(-self.bloom / 2 + math.random() * self.bloom, 
        -self.bloom / 2 + math.random() * self.bloom, 
        -self.bloom / 2 + math.random() * self.bloom) 
    or Vector3.Zero
end

function ProjectileBullet:PreTick(delta)
    if self.lock_position then return end

    self:CalculatePosition()
    self:CalculateDistanceCovered()
    self:CalculateDistanceCoveredSinceLastRaycast()

    if self.total_distance_covered > self.max_lifetime_distance then
        self:SetActive(false)
    end

    if self.distance_covered_since_last_raycast > self.raycast_distance or self.initial_probe then
        self:ProbeForHit()
        self.initial_probe = false
    end
end

function ProjectileBullet:ProbeForHit()
    local raycast_position
    if not self.initial_probe then
        raycast_position = self.last_raycast_position + (self.angle * (Vector3.Forward * self.raycast_distance))
    else
        raycast_position = Copy(self.initial_position)
    end

    -- if the bullet is further
    local raycast_distance_modifier = 1
    if self.distance_covered_since_last_raycast > self.raycast_distance * 2.0 then
        raycast_distance_modifier = math.floor(self.distance_covered_since_last_raycast / self.raycast_distance)
        --print("distance_covered_since_last_raycast: ", self.distance_covered_since_last_raycast)
        --print("raycast_distance_modifier", raycast_distance_modifier)
    end

    self:BulletRaycast(raycast_position , raycast_distance_modifier)

    self.distance_covered_since_last_raycast = 0
    if raycast_distance_modifier ~= 1 then
        self.last_raycast_position = Copy(raycast_position) + (self.angle * (Vector3.Forward * (self.raycast_distance * (raycast_distance_modifier - 1))))
    else
        self.last_raycast_position = Copy(raycast_position)
    end
end

function ProjectileBullet:BulletRaycast(raycast_position, raycast_distance_modifier)
    local raycast_distance = self.raycast_distance * raycast_distance_modifier
    local raycast = Physics:Raycast(raycast_position, self.angle * Vector3.Forward, 0, raycast_distance, true)
    if raycast.distance < raycast_distance then
        self:HitSomething(raycast)
    end
end

function ProjectileBullet:HitSomething(raycast)
    if self.is_splash then
        Events:Fire("LocalPlayerBulletSplash", {
            weapon_enum = self.weapon_enum,
            hit_position = raycast.position
        })

        if HitDetection.debug_enabled then
            Chat:Print("Bullet Splashed", Color(math.random(1, 200), math.random(1, 200), math.random(1, 200)))
        end
    else -- direct hit
        if raycast.entity then
            Events:Fire("LocalPlayerBulletDirectHitEntity", {
                entity_type = raycast.entity.__type,
                entity_id = raycast.entity:GetId(),
                weapon_enum = self.weapon_enum,
                hit_position = raycast.position
            })

            if HitDetection.debug_enabled then
                Chat:Print("Raycast Hit: " .. tostring(raycast.entity), Color.Green)
            end
        end
    end


    if HitDetection.debug_enabled then
        Chat:Print("Bullet Distance Travelled: " .. tostring(self.total_distance_covered), Color.Yellow)
    end

    self.current_position = raycast.position
    self:SetActive(false)
end

function ProjectileBullet:CalculatePosition()
    local life_time = self.life_timer:GetSeconds()
    if life_time < 0.001 then
        life_time = 0.01
    end
    local forward = life_time * self.velocity
    local new_position = self.initial_position + (self.angle * (Vector3.Forward * forward))
    self.current_position = new_position
end

function ProjectileBullet:CalculateDistanceCovered()
    self.total_distance_covered = Vector3.Distance(self.initial_position, self.current_position)
end

function ProjectileBullet:CalculateDistanceCoveredSinceLastRaycast()
    self.distance_covered_since_last_raycast = Vector3.Distance(self.last_raycast_position, self.current_position)
end

function ProjectileBullet:Render()
    local pos = Render:WorldToScreen(self.current_position)
    Render:FillCircle(pos, 6.0, Color.Crimson)
end

function ProjectileBullet:Destroy()
    -- remove any CSOs, effects, or event subscriptions here
end
