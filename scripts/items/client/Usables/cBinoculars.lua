class 'cBinoculars'

function cBinoculars:__init()

    self.using = false
    self.equipped = false
    self.use_key = 'B'

    self.old_fov = Camera:GetFOV()

    self.fov_range = {max = 0.5, min = 0.01}
    self.fov_step = 1.01

    self.scan_timer = Timer()
    self.scan_display_time = 20 -- Scans last for 20 seconds
    self.drones = {}

    self.allowed_actions = 
    {
        [Action.LookLeft] = true,
        [Action.LookRight] = true,
        [Action.LookUp] = true,
        [Action.LookDown] = true
    }

    Network:Subscribe("items/ToggleUsingBinoculars", self, self.ToggleUsingBinoculars)
    Network:Subscribe("items/ToggleBinocularsEquipped", self, self.ToggleBinocularsEquipped)
    Events:Subscribe("KeyUp", self, self.KeyUp)

end

function cBinoculars:KeyUp(args)
    if args.key == string.byte(self.use_key) and self.equipped then
        self:ToggleUsingBinoculars({using = not self.using, local_update = true})
    end
end

function cBinoculars:ToggleBinocularsEquipped(args)
    self.equipped = args.equipped

    if self.using and not self.equipped then
        self:ToggleUsingBinoculars({using = false, local_update = true})
    end
end

function cBinoculars:ToggleUsingBinoculars(args)
    if args.using == self.using then return end -- No change in using status

    self.using = args.using
    LocalPlayer:SetValue("UsingBinoculars", self.using)

    if args.local_update then
        Network:Send("items/ToggleUsingBinoculars", {using = self.using})
    end

    if self.using then
        self:StartUsing()
    else
        self:StopUsing()
    end
end

function cBinoculars:Render(args)
    -- Display binoculars

    self:RenderDrones()

    local size = Render.Size

    -- Display green flash when scan is used
    local seconds = self.scan_timer:GetSeconds()
    local flash_time = 0.5
    if seconds < flash_time then
        Render:FillArea(Vector2(), size, Color(0, 255, 0, 255 - seconds / flash_time * 255))
    end

    Render:FillArea(Vector2(), Vector2(size.x, size.y * 0.2), Color.Black)
    Render:FillArea(Vector2(0, size.y - size.y * 0.2), size, Color.Black)
    Render:FillArea(Vector2(), Vector2(size.x * 0.1, size.y), Color.Black)
    Render:FillArea(Vector2(size.x - size.x * 0.1, 0), size, Color.Black)

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 2000)
    if ray.distance < 1000 then
        local text = string.format("%.0f m", ray.distance)
        local text_size_f = size.y * 0.04
        local text_size = Render:GetTextSize(text, text_size_f)
        Render:SetFont(AssetLocation.SystemFont, "Courier New")
        Render:DrawText(Vector2(size.x / 2 - text_size.x / 2, size.y * 0.9 - text_size.y / 2), text, Color(0, 255, 0), text_size_f)
        Render:ResetFont()
    end

    local text = string.format("Press SPACE to scan for drones", ray.distance)
    local text_size_f = size.y * 0.03
    local text_size = Render:GetTextSize(text, text_size_f)
    Render:SetFont(AssetLocation.SystemFont, "Courier New")
    Render:DrawText(Vector2(size.x / 2 - text_size.x / 2, size.y * 0.05 - text_size.y / 2), text, Color(0, 255, 0), text_size_f)
    Render:ResetFont()

end

function cBinoculars:RenderDrones()
    Render:SetFont(AssetLocation.SystemFont, "Courier New")

    for id, drone_data in pairs(self.drones) do
        local pos_2d = Render:WorldToScreen(drone_data.position)
        self:DrawDroneDisplay(pos_2d, drone_data.distance)
    end

    Render:ResetFont()
end

function cBinoculars:DrawDroneDisplay(position, distance)
    local size = Render.Size.y * 0.03
    local alpha = math.max(0, 1 - self.scan_timer:GetSeconds() / self.scan_display_time) * 255
    local color = Color(255, 0, 0, alpha)

    local top_left = position - Vector2(size, size) / 2
    local top_right = top_left + Vector2(size, 0)
    local bottom_left = top_left + Vector2(0, size)
    local bottom_right = bottom_left + Vector2(size, 0)

    Render:DrawLine(top_left, top_right, color)
    Render:DrawLine(top_left, bottom_left, color)
    Render:DrawLine(top_right, bottom_right, color)
    Render:DrawLine(bottom_left, bottom_right, color)

    local fill_color = Color(255, 0, 0, alpha / 5)
    Render:FillArea(top_left, Vector2(size, size), fill_color)

    local text = string.format("%.0f m", distance)
    local text_size_f = size / 2
    local text_size = Render:GetTextSize(text, text_size_f)
    Render:SetFont(AssetLocation.SystemFont, "Courier New")
    local text_pos = Vector2(bottom_left.x + size / 2 - text_size.x / 2, bottom_left.y + text_size.y / 2)
    Render:DrawText(text_pos, text, color, text_size_f)

end

function cBinoculars:ScanForDrones()

    Network:Send("items/BinocularsScan")

    self.drones = {}

    for id, drone in pairs(cDroneContainer.cso_id_to_drone) do
        local distance = Camera:GetPosition():Distance(drone.cso:GetPosition())
        if drone and distance < 1000 then
            self.drones[drone.id] = {position = drone.cso:GetPosition(), distance = distance}
        end
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

    -- Scan for drones
    if args.input == Action.Jump and self.scan_timer:GetSeconds() > 1 then
        self.scan_timer:Restart()
        self:ScanForDrones()
    end

    if not self.allowed_actions[args.input] then return false end
end

function cBinoculars:CalcView(args)
    Camera:SetPosition(LocalPlayer:GetBonePosition("ragdoll_Head"))
    --return false
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