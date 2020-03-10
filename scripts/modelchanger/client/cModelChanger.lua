class 'cModelChanger'

function cModelChanger:__init()

 -- 240
    self.model_change_areas = {}

    self.window = BaseWindow.Create("Model Change")
    self.window:Hide()
    self.window:SetSize(Vector2(300, 550))
    self.window:SetPosition(Vector2(Render.Size.x * 0.75, Render.Size.y / 2) - self.window:GetSize() / 2)

    self.buttons = {}
    self.current_zone = nil
    self.request_timer = Timer()
    self.streaming_dist = 1500

    for i = 1, 6 do
        local button = Button.Create(self.window, "Button1")
        button:SetSizeRel(Vector2(1, 0.1))
        button:SetPositionRel(Vector2(0, (i - 1) * 0.11))
        button:SetTextSize(16)
        button:SetText(i == 1 and "Model Change" or "Model Name")
        button:SetBackgroundVisible(i ~= 1)

        if i == 1 then
            local rect = Rectangle.Create(button)
            rect:SetSizeRel(Vector2(1,1))
            rect:SetColor(Color(0,0,0,150))
            rect:SendToBack()
            button:SetTextNormalColor(Color.White)
            button:SetTextHoveredColor(Color.White)
            button:SetTextPressedColor(Color.White)
            button:SetTextDisabledColor(Color.White)
            button:SetTextSize(20)
        else
            button:SetDataBool("model_button", true)
            button:Subscribe("Press", self, self.PressButton)
            table.insert(self.buttons, button)
        end
        
    end

    self.blocked_actions = 
    {
        [Action.FireLeft] = true,
        [Action.FireRight] = true,
        [Action.McFire] = true,
        [Action.LookDown] = true,
        [Action.LookLeft] = true,
        [Action.LookRight] = true,
        [Action.LookUp] = true,
        [Action.HeliTurnRight] = true,
        [Action.HeliTurnLeft] = true,
        [Action.VehicleFireLeft] = true,
        [Action.ThrowGrenade] = true,
        [Action.VehicleFireRight] = true,
        [Action.Reverse] = true,
        [Action.UseItem] = true,
        [Action.GuiPDAToggleAOI] = true,
        [Action.GrapplingAction] = true,
        [Action.PickupWithLeftHand] = true,
        [Action.PickupWithRightHand] = true,
        [Action.ActivateBlackMarketBeacon] = true,
        [Action.GuiPDAZoomOut] = true,
        [Action.GuiPDAZoomIn] = true,
        [Action.NextWeapon] = true,
        [Action.PrevWeapon] = true,
        [Action.ExitVehicle] = true
    }

    if not ModelLocations then ModelLocations = {} end

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("SecondTick", self, self.SecondTick)
end

function cModelChanger:PressButton(button)
    if not button:GetDataBool("model_button") then return end

    if not self.current_zone then return end

    local index = button:GetDataNumber("index")
    if not index then return end

    if self.request_timer:GetSeconds() < 0.5 then return end
    self.request_timer:Restart()

    Network:Send("ChangeModel", {
        name = self.current_zone,
        index = index
    })

end

function cModelChanger:EnterZone(name)
    
    local zone_data = ModelLocations[name]

    if self.model_change_areas[name] and not self.window:GetVisible() then
        self.window:Show()
        Mouse:SetVisible(true)
        Mouse:SetPosition(Render.Size / 2)
        self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
        self.current_zone = name

        for index, data in pairs(zone_data.models) do
            self.buttons[index]:SetText(data.name)
            self.buttons[index]:SetDataNumber("index", index)
        end

    end

end

function cModelChanger:ExitZone(name)
    
    if self.model_change_areas[name] and self.window:GetVisible() then
        self.window:Hide()
        Mouse:SetVisible(false)
        Events:Unsubscribe(self.lpi)
        self.lpi = nil
    end

end

function cModelChanger:SecondTick()
    -- Check for nearby zones

    local player_pos = LocalPlayer:GetPosition()

    if LocalPlayer:GetHealth() <= 0 then return end

    for name, zone_data in pairs(ModelLocations) do
        local dist = player_pos:Distance(zone_data.pos)

        if dist < self.streaming_dist and not self.model_change_areas[name] then
            self.model_change_areas[name] = cModelChangeArea({
                position = zone_data.pos,
                name = name
            })
        elseif dist > self.streaming_dist and self.model_change_areas[name] then
            self.model_change_areas[name]:Remove()
            self.model_change_areas[name] = nil
        end

    end
end

function cModelChanger:LocalPlayerInput(args)
    if self.blocked_actions[args.input] then return false end
end

function cModelChanger:ModuleUnload()
    for k,v in pairs(self.model_change_areas) do
        v:Remove()
    end
end

cModelChanger = cModelChanger()