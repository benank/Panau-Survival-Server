class 'cDrone'

--[[
    Creates a new drone.

    args (in table):
        id = self.id,
        level = self.level,
        config = self.config,
        max_health = self.max_health,
        health = self.health,
        path_data = self:GetPathSyncData()

        self:GetPathSyncData()
            id = self.id,
            position = self.position,
            target_position = self.target_position,
            target = self.target,
            target_offset = self.target_offset,
            current_path = self.current_path,
            current_path_index = self.current_path_index,
            state = self.state,
            host = self.host

]]
function cDrone:__init(args)

    --output_table(args)
    self.id = args.id -- TODO: replace with server id
    self.level = args.level
    self.region = args.region
    self.position = args.path_data.position -- Approximate position of the drone in the world
    self.corrective_position = self.position
    self.height_max = args.path_data.height_max or 0

    self.tether_position = args.path_data.tether_position -- Initial spawn position
    self.tether_range = args.path_data.tether_range -- Max distance travelled from initial spawn position

    self.target_position = args.path_data.position -- Target position that the drone is currently travelling to
    self.target = args.path_data.target -- Current active target that the drone is pursuing

    self.path = args.path_data.current_path -- Table of points that the drone is currently pathing through
    self.path_index = args.path_data.current_path_index -- Current index of the path the drone is on

    self.config = args.config

    self.max_health = self.config.health
    self.health = self.max_health

    self.state = args.state

    self.host = args.host -- Player who currently "controls" the drone and dictates its pathfinding

    self.angle = Angle()

    self.offset = args.path_data.target_offset -- Offset from the target the drone flies at

    self.velocity = Vector3()

    self.range = self.config.sight_range

    self.offset_timer = Timer()
    self.tether_timer = Timer()
    self.sound_timer = Timer()
    self.wander_sync_timer = Timer()
    self.wall_timer = Timer()
    self.far_shoot_timer = Timer()
    self.sound_timer_interval = math.random() * 5000 + 800

    self.attack_on_sight_timer = Timer()
    self.attack_on_sight_count = 0

    self.fire_timer = Timer() -- Fire rate timer
    self.next_fire_time = 3
    self.next_fire_time_far = 3

    self.server_updates = {}
    self.cell = GetCell(self.position, Cell_Size)

    self.body = cDroneBody(self)

end

function cDrone:GameRender(args)
    self.body:GameRender(args)
end

-- We are the host, so let's perform actions to make sure the drone has a path and other stuff
function cDrone:PerformHostActions()

    if self.state == DroneState.Wandering then
        
        if count_table(self.path) == 0 and not self.generating_path then
            self.generating_path = true
            cDronePathGenerator:GeneratePathNearPoint(self.position, self.tether_position, DRONE_PATH_RADIUS, self.region, function(edges)
                
                if not edges then
                    Network:Send("drones/DespawnDrone" .. tostring(self.id))
                    self:Remove()
                    return
                end

                self.path = edges
                self.path_index = 1
                self.generating_path = false
                self:SyncToServer({
                    type = "path",
                    path = self.path,
                    path_index = 1
                })

            end)
        end

        if self.offset_timer:GetSeconds() > 5 then
            self.offset = GetRandomFollowOffset(self.config.attack_range)
            self:SyncOffsetToServer()
            self.offset_timer:Restart()
        end

    end

end

function cDrone:IsDestroyed()
    return self.state == DroneState.Destroyed
end

-- Updates from server with all sync info (see __init for full list of args)
function cDrone:UpdateFromServer(args)

    if self.state == DroneState.Wandering and args.state == DroneState.Pursuing and not self.config.attack_on_sight then
        self.fire_timer:Restart()
        self.body:PlaySound("intruder_alert")
    elseif self.state == DroneState.Pursuing and args.state == DroneState.Wandering then
        self.path = {}
        self.path_index = 1
    end

    self.state = args.state or self.state

    if args.health ~= nil and args.health < self.health then
        self.health = args.health
        self.body:HealthUpdated()
    end

    self.host = args.host
    self.target = args.target -- Current active target that the drone is pursuing

    if not self:IsHost() then
        self.path = args.current_path or self.path -- Table of points that the drone is currently pathing through
        self.path_index = args.current_path_index or self.path_index -- Current index of the path the drone is on
        self.offset = args.target_offset or self.offset -- Offset from the target the drone flies at
        self.corrective_position = args.position or self.corrective_position
    end

    self.cell = GetCell(self.position, Cell_Size)

    if self:IsDestroyed() then
        self:Destroyed()
    end

end

function cDrone:SetLinearVelocity(velo)
    self.velocity = velo
end

function cDrone:SyncedToServer()
    self.server_update = false
    self.server_updates = {}
end

-- Sync stuff
function cDrone:SyncToServer(args)
    if not self:IsHost() then return end
    if self:IsDestroyed() then return end
    self.server_update = true

    for key, value in pairs(args) do
        self.server_updates[key] = value
    end
end

function cDrone:SyncOffsetToServer()
    self:SyncToServer({
        type = "offset",
        offset = self.offset,
        position = self.position
    })
end

-- Full sync object including path
function cDrone:GetFullSyncObject()
    return {}
end

function cDrone:SetPosition(pos)
    self.position = pos
    if self.body then self.body:SetPosition() end
end

function cDrone:SetAngle(ang)
    self.angle = ang
    if self.body then self.body:SetAngle() end
end

function cDrone:PostTick(args)

    self:Move(args)
    self.position = self.position + self.velocity * args.delta

    if self.body then self.body:PostTick(args) end

end

function cDrone:IsPlayerAValidTarget(player, distance)
    return IsValid(player) and
        not player:GetValue("Invisible") and 
        player:GetHealth() > 0 and
        not player:GetValue("Loading") and
        not player:GetValue("dead") and
        not player:GetValue("InSafezone") and
        Distance2D(self.position, player:GetPosition()) < (distance or 500)
end

function cDrone:IsTargetVisible(_target)

    local target = _target or self.target
    
    if not IsValid(target) then return false end

    local ray = Physics:Raycast(
        self.position,
        target:GetBonePosition("ragdoll_Hips") - self.position,
        0, 500, false)

    if ray.entity and (ray.entity.__type == "Player" or ray.entity.__type == "LocalPlayer") and ray.entity == target then return true, ray end

end

function cDrone:IsTargetInAttackRange(_target)

    local target = _target or self.target
    
    if not IsValid(target) then return false end

    local ray = Physics:Raycast(
        self.position,
        target:GetBonePosition("ragdoll_Hips") - self.position,
        0, self.config.attack_range * 1.25, false)

    if ray.entity and (ray.entity.__type == "Player" or ray.entity.__type == "LocalPlayer") and ray.entity == target then return true, ray end
    if ray.entity and (ray.entity.__type == "Vehicle") then return true, ray end

end

-- Returns if the drone can shoot (aka it is not looking at a wall). Prevents drone from shooting through walls
function cDrone:CanShoot()

    if not IsValid(self.target) then return false end
    if not self.body then return false end

    local ray = Physics:Raycast(
        self.body:GetGunPosition(DroneBodyPiece.TopGun),
        self.angle * Vector3.Forward,
        0, 1, false)

    if ray.distance == 1 then return true end

end

-- Returns whether or not the drone can see its current target
function cDrone:IsTargetInSight(_target)

    local target = _target or self.target
    
    if not IsValid(target) then return false end
    if not self.body then return false end

    local ray = Physics:Raycast(
        self.body:GetGunPosition(DroneBodyPiece.TopGun),
        target:GetBonePosition("ragdoll_Hips") - self.body:GetGunPosition(DroneBodyPiece.TopGun),
        0, self.range, false)

    if ray.entity and (ray.entity.__type == "Player" or ray.entity.__type == "LocalPlayer") and ray.entity == target then return true, ray end
    if ray.entity and (ray.entity.__type == "Vehicle") then return true, ray end

end

function cDrone:Move(args)

    if IsValid(self.target) then
        self:TrackTarget(args)
    else
        self:Wander(args)
    end

    if self:IsHost() then
        self.corrective_position = self.position
    end

end

-- Makes a drone wander through the sky
function cDrone:Wander(args)

    if self.path then

        -- Traverse path
        local target_pos = self.path[self.path_index]
        if not target_pos then return end
        target_pos = target_pos + self.offset

        -- Wandering speed is base speed / 2
        local wandering_speed = self.config.attack_on_sight and self.config.speed or self.config.speed / 2

        local dir = target_pos - self.position
        local velo = dir:Length() > 1 and (dir:Normalized() * wandering_speed) or Vector3.Zero

        self:SetLinearVelocity(math.lerp(self.velocity, velo, 0.01))

        -- Face towards target position
        local angle = Angle.FromVectors(Vector3.Forward, target_pos - self.position)
        angle.roll = 0

        self:SetAngle(Angle.Slerp(self.angle, angle, 0.05))

        local diff = self.position - target_pos

        if self.wander_sync_timer:GetSeconds() >= 1 and self:IsHost() then
            self.wander_sync_timer:Restart()
            self:SyncOffsetToServer()
        end

        -- If the node was reached, go to the next one
        if math.abs(diff.x) < 2 and math.abs(diff.z) < 2 then
            self.path_index = self.path_index + 1

            if self:IsHost() then
                self:SyncToServer({
                    type = "path_index",
                    path_index = self.path_index,
                    position = self.position
                })
            end

            --_debug(string.format("Path node %d/%d", self.path_index, count_table(self.path)))

            -- Path completed
            if self.path_index >= count_table(self.path) then
                self.path = {} -- Find new path
            end
        end

        if self.config.attack_on_sight and self.attack_on_sight_timer:GetSeconds() > 0.5 and not LocalPlayer:GetValue("Invisible") then
            self.attack_on_sight_timer:Restart()
            local is_visible, ray = self:IsTargetInSight(LocalPlayer)
            self.attack_on_sight_count = is_visible and self.attack_on_sight_count + 1 or math.max(0, self.attack_on_sight_count - 1)

            if is_visible and (ray.distance < self.config.sight_range * 0.1 or self.attack_on_sight_count >= 5) then
                Network:Send("drones/AttackOnSightTarget" .. tostring(self.id))
                self.attack_on_sight_count = 0
                self.body:PlaySound("hostile_spotted")
            end
        end

    end

    if self.sound_timer:GetSeconds() >= self.sound_timer_interval then
        if self.position:Distance(LocalPlayer:GetPosition()) < 80 then
            self.body:PlaySound(math.random() > 0.5 and "enemy_presence_in_the_area" or "trespasser_in_the_area")
        else
            self.body:PlaySound("be_on_the_lookout")
        end
        self.sound_timer_interval = math.random() * 5000 + 800
        self.sound_timer:Restart()
    end

end

function cDrone:IsHost()
    return IsValid(self.host) and self.host == LocalPlayer
end

-- Makes a drone track a target and face towards them 
function cDrone:TrackTarget(args)
    if not IsValid(self.target) or self.target:GetHealth() <= 0 then return end
    self.attack_on_sight_count = 0
    self.target_position = self.target:GetPosition() + self.offset
    local distance = self.position:Distance(self.target:GetPosition())
    
    -- Only use corrective position if not host and if the drone is close to the target
    if not self:IsHost() and distance < self.config.attack_range * 2 then
        self.target_position = math.lerp(self.target_position, self.corrective_position, 0.5)
    end

    local target_pos = self.target_position

    if not target_pos then return end

    local nearby_wall_pos, nearby_wall = self:CheckForNearbyWalls(args)
    target_pos = nearby_wall and nearby_wall_pos or target_pos

    -- Change offset if the drone cannot see the player or every 5 seconds
    if (self:IsHost() and not self:IsTargetVisible() and self.offset_timer:GetSeconds() > 2) or self.offset_timer:GetSeconds() > 5 then
        self.offset = GetRandomFollowOffset(self.config.attack_range)
        self.offset_timer:Restart()
        self:SyncOffsetToServer()
    end

    -- Wall and collision detection
    if nearby_wall and self.wall_timer:GetSeconds() > 0.1 then

        self.wall_timer:Restart()
        self:SetLinearVelocity(-self.velocity * 1)

        if self:IsHost() then
            self.offset = GetRandomFollowOffset(self.config.attack_range)
            self:SyncOffsetToServer()
        end

    else

        local dir = target_pos - self.position
        local speed = self.config.speed

        -- Speed up to get in range
        if distance > self.config.attack_range then
            speed = speed * math.min(distance / self.config.attack_range, 2)
        end

        local velo = dir:Length() > 1 and (dir:Normalized() * speed) or Vector3.Zero

        self:SetLinearVelocity(math.lerp(self.velocity, velo, math.min(1, 0.01)))

    end

    -- Face towards target, if it exists
    local angle = Angle.FromVectors(Vector3.Forward, self.target:GetPosition() + Vector3.Up - self.position)
    angle.roll = 0

    self:SetAngle(Angle.Slerp(self.angle, angle, math.min(1, self.config.accuracy_modifier)))

    local can_shoot_close = self:IsTargetInAttackRange() and self.fire_timer:GetSeconds() >= self.next_fire_time
    local can_shoot_far = self:IsTargetVisible() and self.fire_timer:GetSeconds() >= self.next_fire_time_far
    if (can_shoot_close or can_shoot_far) and not self.firing and self:CanShoot() and self:IsPlayerAValidTarget(self.target) then
        self:Shoot()
    end

end

-- Try to shoot at the target
function cDrone:Shoot()
    self.firing = true
    self.next_fire_time = math.random() * self.config.fire_rate_interval + 1
    self.next_fire_time_far = (math.random() * self.config.fire_rate_interval + 2) * 2
    self.fire_timer:Restart()

    -- Time that the drone will shoot for
    local fire_time = (math.random() * (self.config.fire_time_max - self.config.fire_time_min) + self.config.fire_time_min) * 1000
    local fire_interval = 100 -- Fire every X ms

    Thread(function()
        while fire_time > 0 and self.body and self:CanShoot() do
            local gun_to_fire = math.random() > 0.5 and DroneBodyPiece.LeftGun or DroneBodyPiece.RightGun
            self.body:CreateShootingEffect(gun_to_fire)
            fire_time = fire_time - fire_interval
            Events:Fire("HitDetection/DroneShootMachineGun", {
                position = self.body:GetGunPosition(gun_to_fire),
                angle = self.body:GetGunAngle(gun_to_fire),
                damage_modifier = self.config.damage_modifier
            })
            Timer.Sleep(fire_interval)
        end
        self.firing = false
    end)

end

function cDrone:Destroyed()
    ClientEffect.Play(AssetLocation.Game, {
        position = self.position,
        effect_id = 84,
        angle = self.angle
    })
    self:Remove()
end

-- Checks for naerby walls or obstructions and stops the drone if it gets close
function cDrone:CheckForNearbyWalls(args)

    local speed = self.velocity:Length()

    if speed == 0 then return end

    local normalized = self.velocity:Normalized()
    local ray = Physics:Raycast(self.position + normalized / 2, normalized, 0, 1)

    if ray.distance < 1 or ray.position.y < 201 then

        -- Return hit position + a margin
        return ray.position - normalized * 1, true

    end

end

function cDrone:Remove()
    if not self.body then return end
    self.body = self.body:Remove()
    cDroneManager.drones[self.id] = nil
end