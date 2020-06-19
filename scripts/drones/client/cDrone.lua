class 'cDrone'

function cDrone:__init(args)

    self.position = args.position
    self.angle = args.angle

    self.velocity = Vector3()

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

    self.position = self.position + self.velocity * args.delta

    self.body:PostTick(args)
end

function cDrone:Remove()

    self.body:Remove()

end