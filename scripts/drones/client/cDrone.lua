class 'cDrone'

function cDrone:__init(args)

    self.position = args.position
    self.angle = args.angle

    self.body = cDroneBody(args)

    self.target_position = self.position

end

function cDrone:SetPosition(pos)
    self.position = pos
    self.body:SetPosition(pos)
end

function cDrone:SetAngle(ang)
    self.angle = ang
    self.body:SetAngle(ang)
end

function cDrone:PostTick(args)
    self.body:PostTick(args)
end

function cDrone:Remove()

    self.body:Remove()

end