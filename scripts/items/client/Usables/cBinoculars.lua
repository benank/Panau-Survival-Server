class 'cBinoculars'

function cBinoculars:__init()

    self.using = false

    self.old_fov = Camera:GetFOV()

    self.fov_range = {max = 0.5, min = 0.01}
    self.fov_step = 1.01

    self.allowed_actions = 
    {
        [Action.LookLeft] = true,
        [Action.LookRight] = true,
        [Action.LookUp] = true,
        [Action.LookDown] = true
    }

    Network:Subscribe("items/ToggleUsingBinoculars", self, self.ToggleUsingBinoculars)

end

function cBinoculars:ToggleUsingBinoculars(args)
    if args.using == self.using then return end -- No change in using status

    self.using = args.using
    LocalPlayer:SetValue("UsingBinoculars", self.using)

    if self.using then
        self:StartUsing()
    else
        self:StopUsing()
    end
end

function cBinoculars:Render(args)
    -- Display binoculars
    local size = Render.Size
    Render:FillArea(Vector2(), Vector2(size.x, size.y * 0.2), Color.Black)
    Render:FillArea(Vector2(0, size.y - size.y * 0.2), size, Color.Black)
    Render:FillArea(Vector2(), Vector2(size.x * 0.1, size.y), Color.Black)
    Render:FillArea(Vector2(size.x - size.x * 0.1, 0), size, Color.Black)

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 2000)
    if ray.distance < 2000 then
        local text = string.format("%.0f m", ray.distance)
        local text_size = Render:GetTextSize(text, 20)
        Render:DrawText(Vector2(size.x / 2 - text_size.x / 2, size.y * 0.9), text, Color(0, 255, 0), 20)
    end
end

function cBinoculars:LocalPlayerInput(args)
    if not self.using then return end

    if args.input == Action.MoveForward then
        -- Zoom in
        Camera:SetFOV(math.clamp(Camera:GetFOV() / self.fov_step, self.fov_range.min, self.fov_range.max))
    elseif args.input == Action.MoveBackward then
        -- Zoom out
        Camera:SetFOV(math.clamp(Camera:GetFOV() * self.fov_step, self.fov_range.min, self.fov_range.max))
    end

    if not self.allowed_actions[args.input] then return false end
end

function cBinoculars:CalcView(args)
    Camera:SetPosition(LocalPlayer:GetBonePosition("ragdoll_Head"))
    return false
end

function cBinoculars:InputPoll(args)
    for action, _ in pairs(self.allowed_actions) do
        local value = Input:GetValue(action)
        if value > 1 then
            Input:SetValue(action, Camera:GetFOV() * 0.1)
        end
    end
end

function cBinoculars:StartUsing()
    self.old_fov = Camera:GetFOV()
    Camera:SetFOV(self.fov_range.max)
    self.events = 
    {
        Events:Subscribe("Render", self, self.Render),
        Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput),
        Events:Subscribe("CalcView", self, self.CalcView),
        Events:Subscribe("InputPoll", self, self.InputPoll)
    }
end

function cBinoculars:StopUsing()
    Camera:SetFOV(self.old_fov)
    for _, event in pairs(self.events) do
        Events:Unsubscribe(event)
    end
    self.events = {}
end

cBinoculars = cBinoculars()