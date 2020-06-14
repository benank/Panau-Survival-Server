class "GrenadeBullet"

function GrenadeBullet:__init(args)
    getter_setter(self, "active")
    self:SetActive(true)
    getter_setter(self, "id")
    self.id = args.id
    self.weapon_enum = args.weapon_enum
    self.velocity = args.velocity

    self.bullet_color = Color(252, 221, 121)
    self.bullet_size = args.bullet_size

    self.is_splash = args.is_splash
    self.life_timer = Timer()

    self.initial_position = LocalPlayer:GetBonePosition(BoneEnum.RightHand) + Vector3(0, 0.15, 0)
    self.current_position = Copy(self.initial_position)
    self.last_raycast_position = Copy(self.initial_position)


    local dir = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 1000).position
    dir = Angle.FromVectors(Vector3.Forward, dir - self.initial_position)
    self.target_position = Physics:Raycast(self.initial_position, dir * Vector3.Forward, 0, 1000).position
    self.angle = Angle.FromVectors(Vector3.Forward, self.target_position - self.initial_position)
    self.angle.roll = 0

    self.start_time = Client:GetElapsedSeconds()
    self.max_lifetime = 10 -- If bullet travels for longer than this, it gets removed
    self.max_lifetime_distance = 1000 -- if bullet travels farther than this distance then it gets removed
    self.total_distance_covered = 0
    self.distance_covered_since_last_raycast = 0
    self.raycast_distance = 0.01
    self.initial_probe = true

    self.lock_position = false
end

function GrenadeBullet:SetId(id)
    self.id = id
end

function GrenadeBullet:GetId()
    return self.id
end

function GrenadeBullet:PreTick(delta)
    if self.lock_position then return end

    self:CalculatePosition(delta)
    self:CalculateDistanceCovered()
    self:CalculateDistanceCoveredSinceLastRaycast()

    if self.total_distance_covered > self.max_lifetime_distance
    or Client:GetElapsedSeconds() - self.start_time > self.max_lifetime then
        self:SetActive(false)
    end

    if self.distance_covered_since_last_raycast > self.raycast_distance or self.initial_probe then
        self:ProbeForHit()
        self.initial_probe = false
    end
end

function GrenadeBullet:ProbeForHit()
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

function GrenadeBullet:BulletRaycast(raycast_position, raycast_distance_modifier)
    local raycast_distance = self.raycast_distance * raycast_distance_modifier
    local raycast = Physics:Raycast(raycast_position, self.angle * Vector3.Forward, 0, raycast_distance, true)
    if raycast.distance < raycast_distance then
        self:HitSomething(raycast)
    end
end

function GrenadeBullet:HitSomething(raycast)
    if self.is_splash then
        Events:Fire("LocalPlayerBulletSplash", {
            weapon_enum = self.weapon_enum,
            hit_position = raycast.position
        })

        if WeaponHitDetection.debug_enabled then
            Chat:Print("Bullet Splashed", Color(math.random(1, 200), math.random(1, 200), math.random(1, 200)))
        end
    else -- direct hit
        if raycast.entity then
            Events:Fire("LocalPlayerBulletDirectHitEntity", {
                entity_type = raycast.entity.__type,
                entity_id = raycast.entity:GetId(),
                weapon_enum = self.weapon_enum,
                hit_position = raycast.position,
                distance_travelled = self.total_distance_covered
            })

            if WeaponHitDetection.debug_enabled then
                Chat:Print("Raycast Hit: " .. tostring(raycast.entity), Color.Green)
            end
        end
    end

    local effect_time = 1500
    local size = 0.05
    self.effect_timer = Timer()
    self.angle = Angle.FromVectors(raycast.normal, Vector3.Forward) * Angle(0, math.pi / 2, 0)

    self.gamerender = Events:Subscribe("GameRender", function(args)
    
        local t = Transform3():Translate(self.current_position + Camera:GetAngle() * Vector3.Backward * 0.1):Rotate(Camera:GetAngle())
        Render:SetTransform(t)

        local time = self.effect_timer:GetMilliseconds()

        local color = self.bullet_color
        Render:FillCircle(Vector3.Zero, size - time / effect_time * size, color)

        if time > effect_time then
            Events:Unsubscribe(self.gamerender)
            self.gamerender = nil
        end

    end)

    --[[ClientEffect.Play(AssetLocation.Game, {
        position = raycast.position,
        angle = Angle.FromVectors(raycast.normal, Vector3.Up),
        effect_id = 2
    })]]

    if WeaponHitDetection.debug_enabled then
        Chat:Print("Bullet Distance Travelled: " .. tostring(self.total_distance_covered), Color.Yellow)
    end

    self.current_position = raycast.position
    self:SetActive(false)
end

function GrenadeBullet:GetForward()
    local life_time = self.life_timer:GetSeconds()
    if life_time < 0.001 then
        life_time = 0.01
    end
    local forward = life_time * self.velocity
    return forward
end

function GrenadeBullet:CalculatePosition(delta)
    self.angle.pitch = self.angle.pitch - math.pi * 0.05 * delta
    _debug(self.angle.pitch)
    local new_position = self.initial_position + (self.angle * (Vector3.Forward * self:GetForward()))
    self.current_position = new_position
end

function GrenadeBullet:CalculateDistanceCovered()
    self.total_distance_covered = Vector3.Distance(self.initial_position, self.current_position)
end

function GrenadeBullet:CalculateDistanceCoveredSinceLastRaycast()
    self.distance_covered_since_last_raycast = Vector3.Distance(self.last_raycast_position, self.current_position)
end

function GrenadeBullet:RenderLine()
    if not self:GetActive() then return end
    Render:DrawLine(
        self.current_position,
        self.current_position + (self.angle * (Vector3.Forward * self.velocity * self.bullet_size)),
        self.bullet_color
    )
end

function GrenadeBullet:Render()
    local pos = Render:WorldToScreen(self.current_position)
    Render:FillCircle(pos, 6.0, Color.Crimson)
    Render:FillCircle(Render:WorldToScreen(self.target_position), 5, Color.LawnGreen)
end

function GrenadeBullet:Destroy()
    -- remove any CSOs, effects, or event subscriptions here
end
