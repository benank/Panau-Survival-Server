class 'Fog2'

function Fog2:__init(args)

    -- How many layers you want. Increase for smoother transitions
    self.num_layers = args and args.num_layers or 75

    -- Distance of first layer from camera. 
    self.first_layer_dist = args and args.first_layer_dist or 15

    -- Distance between layers. Closer = smoother transition
    self.dist_between_layers = args and args.dist_between_layers or 0.25

    -- Color of the layers. Keep in mind the alpha.
    self.color = args and args.color or Color(0,0,0,20)

    self.fade_out_time = args and args.fade_out_time or 10
    self.fading_out = false

    self.fade_in_time = args and args.fade_in_time or 10
    self.fading_in = false

    self.fade_delta = 0

    self.range = 75 -- Size of rectangles

    self:CreateModel()

end

function Fog2:CreateModel()

    local vertices = {}


    for i = self.num_layers, 0, -1 do

        local basepos = Vector3(0,0,- i * self.dist_between_layers)
        local range = self.range + 10 * (self.dist_between_layers * i)

        -- 1
        table.insert(vertices, 
            Vertex(
                basepos + Vector3(range, range, 0),
                self.color
            ))

        -- 2
        table.insert(vertices, 
        Vertex(
            basepos + Vector3(-range, range, 0),
            self.color
        ))

        -- 3
        table.insert(vertices, 
        Vertex(
            basepos + Vector3(-range, -range, 0),
            self.color
        ))

        -- 4
        table.insert(vertices, 
            Vertex(
                basepos + Vector3(-range, -range, 0),
                self.color
            ))

        -- 5
        table.insert(vertices, 
        Vertex(
            basepos + Vector3(range, -range, 0),
            self.color
        ))

        -- 6
        table.insert(vertices, 
        Vertex(
            basepos + Vector3(range, range, 0),
            self.color
        ))

    end

    self.model = Model.Create(vertices)
    self.model:SetTopology(Topology.TriangleStrip)
    self.model:SetTextureAlpha(0)

end

function Fog2:Render(args)

    if not self.model then return end

    local t = Transform3()
    local cam_pos = Camera:GetPosition()
    local cam_ang = Camera:GetAngle()

    -- Translate fog to correct position
    t:Translate(cam_pos):Rotate(cam_ang):Translate(Vector3(0,0,-self.first_layer_dist))
    Render:SetTransform(t)

    self.model:Draw()

    if self.fading_out then

        local alpha = math.max(255 - 255 * (self.fade_timer:GetSeconds() / self.fade_out_time), 0)
        self.model:SetTextureAlpha(alpha)

        if alpha <= 0 then
            self:Remove()
        end

    elseif self.fading_in then

        local alpha = math.min(255 * (self.fade_timer:GetSeconds() / self.fade_out_time), 255)
        self.model:SetTextureAlpha(alpha)

        if alpha >= 255 then
            self.fading_in = false
            self.fade_timer = nil
        end

    end

    Render:ResetTransform()

end

-- Call this to fade out the fog
function Fog2:FadeOut(time)

    self.fade_out_time = time or self.fade_out_time
    self.fading_out = true
    self.fade_timer = Timer()

end

-- Call this to fade out the fog
function Fog2:FadeIn(time)

    self.fade_in_time = time or self.fade_in_time
    self.fading_in = true
    self.fade_timer = Timer()

end

function Fog2:Remove()

    self.model = nil
    self = nil

end
