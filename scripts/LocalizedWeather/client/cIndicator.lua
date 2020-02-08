class 'Indicator'

--[[

    args: a table containing:

        position: a Vector3
        color: a Color
        size: a number
        rotating: boolean if this is rotating
        flashing: boolean if this is flashing

]]

local mod = 0.5

function Indicator:__init(args)

    self.position = args.position
    self.size = args.size or 0.25
    self.color = args.color or Color(255, 0, 0, 255)
    self.rotating = args.rotating or false
    self.flashing = args.flashing or false

    self.delta = 0

    self:CreateModel()

end

function Indicator:CreateModel()

    local vertices = {}

    table.insert(vertices, Vertex(Vector3.Zero, self.color))
    table.insert(vertices, Vertex(Vector3.Zero + Vector3(mod * self.size, self.size, mod * self.size), self.color))
    table.insert(vertices, Vertex(Vector3.Zero + Vector3(mod * self.size, self.size, -mod * self.size), self.color))

    table.insert(vertices, Vertex(Vector3.Zero + Vector3(-mod * self.size, self.size, mod * self.size), self.color))
    table.insert(vertices, Vertex(Vector3.Zero + Vector3(-mod * self.size, self.size, -mod * self.size), self.color))
    
    table.insert(vertices, Vertex(Vector3.Zero, self.color))
    table.insert(vertices, Vertex(Vector3.Zero + Vector3(-mod * self.size, self.size, -mod * self.size), self.color))
    table.insert(vertices, Vertex(Vector3.Zero, self.color))

    table.insert(vertices, Vertex(Vector3.Zero, self.color))
    table.insert(vertices, Vertex(Vector3.Zero + Vector3(mod * self.size, self.size, -mod * self.size), self.color))
    table.insert(vertices, Vertex(Vector3.Zero + Vector3(-mod * self.size, self.size, -mod * self.size), self.color))

    table.insert(vertices, Vertex(Vector3.Zero, self.color))
    table.insert(vertices, Vertex(Vector3.Zero + Vector3(-mod * self.size, self.size, mod * self.size), self.color))
    table.insert(vertices, Vertex(Vector3.Zero + Vector3(mod * self.size, self.size, mod * self.size), self.color))

    self.model = Model.Create(vertices)
    self.model:SetTopology(Topology.TriangleStrip)

end

function Indicator:Render(args)

    if self.model then

        local t = Transform3()
        t:Translate(self.position):Rotate(Angle(self.delta, 0, 0))

        if (self.rotating) then self.delta = self.delta + args.delta end
        if (self.flashing) then self.model:SetTextureAlpha(math.abs(math.cos(self.delta * 3)) * 255) end

        Render:SetTransform(t)

        self.model:Draw()

    end

end