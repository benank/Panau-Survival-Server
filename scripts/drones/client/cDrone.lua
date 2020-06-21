class 'cDrone'

function cDrone:__init(args)

    self.position = args.position
    self.angle = args.angle

    self.offset = args.offset or GetRandomFollowOffset()

    self.velocity = Vector3()

    self.range = 100

    self.offset_timer = Timer()

    args.parent = self
    self.body = cDroneBody(self)

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

    self.target = LocalPlayer
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

    --[[if math.random() < 0.05 then
        drone.body:CreateShootingEffect(math.random() > 0.5 and DroneBodyPiece.LeftGun or DroneBodyPiece.RightGun)
    end]]

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