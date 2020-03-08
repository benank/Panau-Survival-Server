class  'cModelChangeArea'

function cModelChangeArea:__init(args)

    self.position = args.position
    self.name = args.name

    self.fx = {}
    self:Create()

end

function cModelChangeArea:Create()

    local radius = 5
    local coords = self:GetCircleCoordinates(Vector2.Zero, radius, 20, 0, 1)

    for _, point in pairs(coords) do
        table.insert(self.fx, ClientParticleSystem.Create(AssetLocation.Game, {
            position = self.position + Vector3(point.x, -0.5, point.y),
            angle = Angle(),
            path = "fire_lave_medium_05.psmb"
        }))
    end

end

function cModelChangeArea:GetCircleCoordinates(position, radius, resolution, start_percent, final_percent)

    local coords = {}

    for theta = 0 + math.pi * 2 * (start_percent or 0), 2 * math.pi * (final_percent or 1), 2 * math.pi / resolution do
        local x = radius * math.sin(theta)
        local y = radius * math.cos(theta)
        local point = position - Vector2(-x,y)
        table.insert(coords, point)
    end

    return coords

end

function cModelChangeArea:Remove()
    for k,v in pairs(self.fx) do
        if IsValid(v) then v:Remove() end
    end
end