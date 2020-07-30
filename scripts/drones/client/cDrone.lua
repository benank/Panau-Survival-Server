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

    
    self.id = GetDroneId()
    self.level = args.level
    self.position = args.position -- Approximate position of the drone in the world

    self.spawn_position = args.spawn_position -- Initial spawn position
    self.tether_range = args.tether_range -- Max distance travelled from initial spawn position

    self.target_position = self.position -- Target position that the drone is currently travelling to
    self.target = nil -- Current active target that the drone is pursuing
    self.target_offset = Vector3() -- Offset from the target the drone flies at

    self.current_path = {} -- Table of points that the drone is currently pathing through
    self.current_path_index = 1 -- Current index of the path the drone is on

    self.config = GetDroneConfiguration(self.level)

    self.max_health = self.config.health
    self.health = self.max_health

    self.state = DroneState.Wandering
    self.personality = self.config.attack_on_sight and DronePersonality.Hostile or DronePersonality.Defensive

    self.host = nil -- Player who currently "controls" the drone and dictates its pathfinding

    self.host_interval = Timer.SetInterval(2500, function()
        local updated = self:ReconsiderHost()
        updated = self:ReconsiderTarget() or updated
        if updated then self:Sync() end
    end)

    self.position = args.position
    self.angle = Angle()

    self.offset = args.offset or GetRandomFollowOffset()

    self.velocity = Vector3()

    self.range = 100

    self.offset_timer = Timer()

    args.parent = self
    self.body = cDroneBody(self)

end

-- We are the host, so let's perform actions to make sure the drone has a path and other stuff
function cDrone:PerformHostActions()

    if not self.path then
        self:

end

-- Updates from server with path/position sync info (see __init for full list of args)
function cDrone:UpdatePathFromServer(args)

end

-- Updates from server with all sync info (see __init for full list of args)
function cDrone:UpdateFromServer(args)

end

function cDrone:SetLinearVelocity(velo)
    self.velocity = velo
end

function cDrone:SetPosition(pos)
    self.position = pos
    self.body:SetPosition()
end

function cDrone:SetAngle(ang)
    self.angle = ang
    self.body:SetAngle()
end

function cDrone:PostTick(args)

    self:Move(args)
    self.position = self.position + self.velocity * args.delta

    self.body:PostTick(args)
end

-- Returns whether or not the drone can see its current target
function cDrone:IsTargetInSight()

    if not IsValid(self.target) then return false end

    local ray = Physics:Raycast(
        self.body:GetGunPosition(DroneBodyPiece.TopGun),
        self.target:GetBonePosition("ragdoll_Hips") - self.body:GetGunPosition(DroneBodyPiece.TopGun),
        0, self.range)

    
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

    if not self.path and not self.generating_path then
        self.generating_path = true
        cDronePathGenerator:GeneratePathNearPoint(self.position, 500, function(edges)
            
            self.path = edges
            self.path_index = 1
            self.generating_path = false

        end)
    end

    if self.path then

        -- Traverse path
        local target_pos = self.path[self.path_index]

        local wandering_speed = DRONE_SPEED / 2 

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

            _debug(string.format("Path node %d/%d", self.path_index, count_table(self.path)))

            -- Path completed
            if self.path_index > count_table(self.path) then
                -- Set path to nil to find a new path
                self.path = nil
            end
        end

    end

end

-- Makes a drone track a target and face towards them 
function cDrone:TrackTarget(args)
    self.target_position = self.target:GetPosition() + self.offset

    local target_pos = self.target_position

    if not target_pos then return end

    local nearby_wall_pos, nearby_wall = self:CheckForNearbyWalls(args)
    target_pos = nearby_wall and nearby_wall_pos or target_pos

    -- TODO: also change offset if cannot see player

    -- Wall and collision detection
    if nearby_wall or (self.wall_timer and self.wall_timer:GetSeconds() < 0.5) then

        if nearby_wall then
            self.wall_timer = Timer()
            self:SetLinearVelocity(-self.velocity * 0.5)

            -- TODO: sync offset
            self.offset = GetRandomFollowOffset()
        end

    else

        local dir = target_pos - self.position
        local velo = dir:Length() > 1 and (dir:Normalized() * DRONE_SPEED) or Vector3.Zero

        self:SetLinearVelocity(math.lerp(self.velocity, velo, 0.01))

    end

    if self.offset_timer:GetSeconds() > 5 then
        self.offset = GetRandomFollowOffset()
        self.offset_timer:Restart()
    end

    -- Face towards target, if it exists
    local angle = Angle.FromVectors(Vector3.Forward, self.target:GetPosition() + Vector3.Up - self.position)
    angle.roll = 0

    self:SetAngle(Angle.Slerp(self.angle, angle, 0.05))

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

    self.body:Remove()

end