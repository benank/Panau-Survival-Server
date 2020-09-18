class 'cLandclaimObjectMenu'

function cLandclaimObjectMenu:__init()

    self.button_cooldown = Timer()
    self.range = 6
    
    self.blockedActions = {
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

    Events:Subscribe("MouseUp", self, self.MouseUp)

end

function cLandclaimObjectMenu:MouseUp(args)
    if args.button == 2 then
        -- Right click
        self:TryToOpenMenu()
    end
end

function cLandclaimObjectMenu:GetLandclaimObjectFromRaycastEntity(entity)
    if not IsValid(entity) then return end
    if entity.__type ~= "ClientStaticObject" then return end

    return entity:GetValue("LandclaimObject")
end

function cLandclaimObjectMenu:TryToOpenMenu()
    if LocalPlayer:GetValue("Loading") then return end
    if cObjectPlacer.placing then return end
    if LocalPlayer:GetValue("InventoryOpen") then return end
    if LocalPlayer:InVehicle() then return end

    -- Get current object that we are looking at
    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.range)
    local landclaim_object = self:GetLandclaimObjectFromRaycastEntity(ray.entity)
    if not landclaim_object then return end

    self.object = landclaim_object

    local owner_id = landclaim_object.landclaim.owner_id
    local my_id = tostring(LocalPlayer:GetSteamId())

    -- No editing permissions
    if not landclaim_object.landclaim:CanPlayerPlaceObject(LocalPlayer) then return end
    if not landclaim_object.landclaim:IsActive() then return end

    local options = {}
    options.remove = true

    if owner_id == my_id and landclaim_object.name == "Door" then
        options.access = true
    end

    if landclaim_object.name == "Bed" then
        if landclaim_object.custom_data.player_spawns[my_id] then
            options.unset_spawn = true
        else
            options.spawn = true
        end
    end

    self:CreateMenu(options)

end

--[[
Recreates the menu with specified options

    options (in table):
        remove = true: adds the "Remove" option so the object can be removed
        access = true: adds the access mode options to the menu for doors (similar to stash access menu)
        spawn = true: add the "Set Spawn" option
        unset_spawn = true: adds the "Unset Spawn" option

]] 

function cLandclaimObjectMenu:CreateMenu(options)

    if self.menu then
        self.menu:Remove()
        Events:Unsubscribe(self.lpi)
    end

    self.has_access_mode = false
    local button_height = Render.Size.y * 0.15 * 0.2

    Mouse:SetPosition(Render.Size / 2)
    Mouse:SetVisible(true)
    self.button_names = {}

    if options.access then
        table.insert(self.button_names, "Access: Only Me")
        table.insert(self.button_names, "Access: Friends")
        table.insert(self.button_names, "Access: Everyone")
        self.has_access_mode = true
    end

    if options.spawn then
        table.insert(self.button_names, "Set Spawn")
    end

    if options.unset_spawn then
        table.insert(self.button_names, "Unset Spawn")
    end

    if options.remove then
        table.insert(self.button_names, "Remove")
    end

    self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)

    self.menu = Rectangle.Create()
    self.menu:SetColor(Color(0, 0, 0, 150))
    self.menu:SetSize(Vector2(Render.Size.x * 0.1, button_height * count_table(self.button_names)))
    self.menu:SetPosition(Render.Size / 2 + Vector2(0, 50) - Vector2(self.menu:GetSize().x / 2, 0))
    self.render = self.menu:Subscribe("PostRender", self, self.PostRender)

    self.buttons = {}
    for index, name in ipairs(self.button_names) do
        local button = Button.Create(self.menu)
        button:SetText(name)
        button:SetSize(Vector2(self.menu:GetSize().x, button_height))
        button:SetTextSize(button:GetHeight() / 2)
        button:SetDock(GwenPosition.Top)
        button:SetAlignment(GwenPosition.Fill + GwenPosition.CenterV)
        button:SetTextPadding(Vector2(button:GetWidth() * 0.25, 0), Vector2.Zero)
        button:SetBackgroundVisible(false)
        button:SetDataString("button_name", name)
        button:Subscribe("Press", self, self.PressButton)
        self.buttons[name] = button
    end

end

function cLandclaimObjectMenu:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
    self:CloseMenu()
end

function cLandclaimObjectMenu:CloseMenu()
    self.menu:Remove()
    self.menu = nil
    Events:Unsubscribe(self.lpi)
    self.lpi = nil
    Mouse:SetVisible(false)
    self.object = nil
end

function cLandclaimObjectMenu:PostRender(args)

    local pos = self.menu:GetPosition()

    local t = Transform2():Translate(pos)
    Render:SetTransform(t)

    local num_buttons = count_table(self.buttons)
    local size = self.menu:GetSize()
    local button_height = size.y / num_buttons

    Render:DrawLine(Vector2.Zero, Vector2(0, size.y), Color.White)
    Render:DrawLine(Vector2.Zero, Vector2(size.x, 0), Color.White)
    Render:DrawLine(size, size + Vector2(-size.x, 0), Color.White)
    Render:DrawLine(size, size + Vector2(0, -size.y), Color.White)
    
    local i = 1
    for name, button in pairs(self.buttons) do
        local height = button:GetSize().y
        Render:DrawLine(Vector2(0, height * i), Vector2(0, height * i) + Vector2(size.x, 0), Color.White)
        i = i + 1
    end

    if self.has_access_mode then
        local access_mode = self.object.custom_data.access_mode
        local circle_size =  size.y / 3 * 0.15
        Render:FillCircle(
            Vector2(size.x * 0.125, button_height / 2 + button_height * (access_mode - 1)) - Vector2(circle_size, circle_size) / 2, 
            circle_size, 
            Color.Red)
    end

    Render:ResetTransform()

end

function cLandclaimObjectMenu:PressButton(btn)

    if not self.object then return end

    if self.button_cooldown:GetSeconds() < 1 then return end
    self.button_cooldown:Restart()

    Network:Send("build/PressBuildObjectMenuButton", {
        name = btn:GetDataString("button_name"),
        id = self.object.id,
        landclaim_id = self.object.landclaim.id,
        landclaim_owner_id = self.object.landclaim.owner_id
    })

    self:CloseMenu()

end

cLandclaimObjectMenu = cLandclaimObjectMenu()