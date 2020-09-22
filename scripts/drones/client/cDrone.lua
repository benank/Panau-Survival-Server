class 'cDrone'

--[[
    Creates a new drone.

    args (in table):
        id = self.id,
        level = self.level,
        config = self.config,
        max_health = self.max_health,
        health = self.health,
        personality = self.personality,
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

    output_table(args)
    self.id = args.id -- TODO: replace with server id
    self.level = args.level
    self.position = args.path_data.position -- Approximate position of the drone in the world
    self.corrective_position = self.position

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
    self.personality = self.config.attack_on_sight and DronePersonality.Hostile or DronePersonality.Defensive

    self.host = args.host -- Player who currently "controls" the drone and dictates its pathfinding

    self.angle = Angle()

    self.offset = args.path_data.target_offset -- Offset from the target the drone flies at

    self.velocity = Vector3()

    self.range = self.config.sight_range

    self.offset_timer = Timer()
    self.tether_timer = Timer()

    self.fire_timer = Timer() -- Fire rate timer
    self.next_fire_time = 0

    self.body = cDroneBody(self)

end

-- We are the host, so let's perform actions to make sure the drone has a path and other stuff
function cDrone:PerformHostActions()

    if self.state == DroneState.Wandering then
        
        if count_table(self.path) == 0 and not self.generating_path then
            self.generating_path = true
            cDronePathGenerator:GeneratePathNearPoint(self.position, self.tether_position, DRONE_PATH_RADIUS, function(edges)
                
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
            self.offset = GetRandomFollowOffset(self.config.sight_range)
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
    self.state = args.state or self.state

    self.health = args.health ~= nil and args.health or self.health
    self.body:HealthUpdated()
    self.host = args.host
    self.target = args.target -- Current active target that the drone is pursuing

    if args.path_data then

        if not self:IsHost() then
            self.path = args.path_data.current_path or self.path -- Table of points that the drone is currently pathing through
            self.path_index = args.path_data.current_path_index or self.path_index -- Current index of the path the drone is on
            self.offset = args.path_data.target_offset or self.offset -- Offset from the target the drone flies at
            self.corrective_position = args.path_data.position or self.corrective_position
        end

    end

    if self:IsDestroyed() then
        self:Destroyed()
    end

end

function cDrone:SetLinearVelocity(velo)
    self.velocity = velo
end

-- Sync stuff
function cDrone:SyncToServer(args)
    if self:IsDestroyed() then return end
    if args.type == "full" then
        Network:Send("drones/sync/full" .. tostring(self.id), self:GetFullSyncObject())
    else
        Network:Send("drones/sync/one" .. tostring(self.id), args)
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

function cDrone:IsTargetVisible()
    
    if not IsValid(self.target) then return false end

    local ray = Physics:Raycast(
        self.position,
        self.target:GetBonePosition("ragdoll_Hips") - self.position,
        0, self.range * 2, false)

    if ray.entity and (ray.entity.__type == "Player" or ray.entity.__type == "LocalPlayer") and ray.entity == self.target then return true end

end

-- Returns whether or not the drone can see its current target
function cDrone:IsTargetInSight()

    if not IsValid(self.target) then return false end
    if not self.body then return false end

    local ray = Physics:Raycast(
        self.body:GetGunPosition(DroneBodyPiece.TopGun),
        self.target:GetBonePosition("ragdoll_Hips") - self.body:GetGunPosition(DroneBodyPiece.TopGun),
        0, self.range, false)

    if ray.entity and ray.entity.__type == "Player" and ray.entity == self.target then return true end

end

function cDrone:Move(args)

    if IsValid(self.target) then
        self:TrackTarget(args)
    else
        self:Wander(args)
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
        local wandering_speed = self.personality == DronePersonality.Hostile and self.config.speed or self.config.speed / 2

        local dir = target_pos - self.position
        local velo = dir:Length() > 1 and (dir:Normalized() * wandering_speed) or Vector3.Zero

        self:SetLinearVelocity(math.lerp(self.velocity, velo, 0.01))

        -- Face towards target position
        local angle = Angle.FromVectors(Vector3.Forward, target_pos - self.position)
        angle.roll = 0

        self:SetAngle(Angle.Slerp(self.angle, angle, 0.05))

        local diff = self.position - target_pos

        -- If the node was reached, go to the next one
        if math.abs(diff.x) < 2 and math.abs(diff.z) < 2 then
            self.path_index = self.path_index + 1

            self:SyncToServer({
                type = "path_index",
                path_index = self.path_index
            })

            _debug(string.format("Path node %d/%d", self.path_index, count_table(self.path)))

            -- Path completed
            if self.path_index >= count_table(self.path) then
                self.path = {} -- Find new path
            end
        end

    end

end

function cDrone:IsHost()
    return self.host and self.host == LocalPlayer
end

-- Makes a drone track a target and face towards them 
function cDrone:TrackTarget(args)
    self.target_position = self.target:GetPosition() + self.offset
    
    if self:IsHost() then
        self.corrective_position = self.target_position
    end

    self.target_position = math.lerp(self.target_position, self.corrective_position, 0.75)

    local target_pos = self.target_position

    if not target_pos then return end

    local nearby_wall_pos, nearby_wall = self:CheckForNearbyWalls(args)
    target_pos = nearby_wall and nearby_wall_pos or target_pos

    -- Change offset if the drone cannot see the player
    if self:IsHost() and not self:IsTargetVisible() and self.offset_timer:GetSeconds() > 2 then
        self.offset = GetRandomFollowOffset(self.config.sight_range)
        self.offset_timer:Restart()
        self:SyncOffsetToServer()
    end

    -- Wall and collision detection
    if nearby_wall or (self.wall_timer and self.wall_timer:GetSeconds() < 0.5) then

        if nearby_wall then
            self.wall_timer = Timer()
            self:SetLinearVelocity(-self.velocity * 0.5)

            if self:IsHost() then
                self.offset = GetRandomFollowOffset(self.config.sight_range)
                self:SyncOffsetToServer()
            end
        end

    else

        local dir = target_pos - self.position
        local velo = dir:Length() > 1 and (dir:Normalized() * self.config.speed) or Vector3.Zero

        self:SetLinearVelocity(math.lerp(self.velocity, velo, math.min(1, args.delta * 0.5)))

    end

    -- Face towards target, if it exists
    local angle = Angle.FromVectors(Vector3.Forward, self.target:GetPosition() + Vector3.Up - self.position)
    angle.roll = 0

    self:SetAngle(Angle.Slerp(self.angle, angle, math.min(1, self.config.accuracy_modifier)))

    if self:IsTargetVisible() and self.fire_timer:GetSeconds() >= self.next_fire_time and not self.firing then
        self:Shoot()
    end

end

-- Try to shoot at the target
function cDrone:Shoot()
    self.firing = true
    self.next_fire_time = math.random() * self.config.fire_rate_interval + 1
    self.fire_timer:Restart()

    -- Time that the drone will shoot for
    local fire_time = (math.random() * (self.config.fire_time_max - self.config.fire_time_min) + self.config.fire_time_min) * 1000
    local fire_interval = 100 -- Fire every X ms

    Thread(function()
        while fire_time > 0 and self.body do
            local gun_to_fire = math.random() > 0.5 and DroneBodyPiece.LeftGun or DroneBodyPiece.RightGun
            self.body:CreateShootingEffect(gun_to_fire)
            fire_time = fire_time - fire_interval
            Events:Fire("HitDetection/DroneShootMachineGun", {
                position = self.body:GetGunPosition(gun_to_fire),
                angle = self.body:GetGunAngle(gun_to_fire),
                damage_modifier = self.config.damage_modifier
            })
            -- 38 for blood fx on person
            -- 36 for impact fx on ground
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