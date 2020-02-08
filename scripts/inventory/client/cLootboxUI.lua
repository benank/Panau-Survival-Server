class 'cLootboxUI'

function cLootboxUI:__init()

    self.open_key = 'E'

    self.contents = {}

    self.window = Window.Create("Loot")
    self.window:DisableResizing()
    self.window:SetClosable(false)
    self.window:SetSize(Vector2(Render.Size.x * 0.2, Render.Size.y * 0.4))
    self.window:SetPosition(Render.Size / 2 - self.window:GetSize() / 2)
    self.window:SetTitle("Loot")
    self.window:Hide()

    self.itemWindows = {}

    self.scrollControl = ScrollControl.Create(self.window, "scroll")
    self.scrollControl:SetSizeAutoRel(Vector2(1, 1))
    self.scrollControl:SetScrollable(false, true)

    self.tooltip = Rectangle.Create()
    self.tooltip:SetColor(Color(0, 0, 0, 150))
    self.tooltip_label = Label.Create(self.tooltip, "title")
    self.tooltip_label:SetTextSize(18)
    self.tooltip_label:SetAlignment(GwenPosition.Center)
    self.tooltip_label:SetPadding(Vector2(Render.Size.x * 0.003, Render.Size.x * 0.003), 
    Vector2(Render.Size.x * 0.003, Render.Size.x * 0.003))
    self.tooltip_label:SetTextPadding(Vector2(10,10), Vector2(10, 10))
    self.tooltip:Hide()


    self.num_rows = 10
    self.items_per_row = 3

    self:CreateWindow()
    
    LocalPlayer:SetValue("LootOpen", false)

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

    Events:Subscribe("KeyUp", self, self.KeyUp)
    Network:Subscribe("Inventory/LootboxOpen", self, self.LootboxOpen)
    Network:Subscribe("Inventory/LootboxSync", self, self.LootboxSync)
    
end

function cLootboxUI:ClickItemButton(btn)

    local index = btn:GetDataNumber("stack_index")

    if not index or not LootManager.current_box.contents[index] then return end

    Network:Send("Inventory/TakeLootStack"..tostring(LootManager.current_box.uid), {index = index})

    -- If there's an item to the right, populate the tooltip with its info
    ClientInventory.ui:PopulateTooltip(
        {button = btn, index = index + 1, tooltip = self.tooltip, tooltip_label = self.tooltip_label, loot = true})


end

function cLootboxUI:LootboxSync(args)

    if not args.contents then return end
    if not LootManager.current_box then return end

    LootManager:RecreateContents(args.contents)
    self:Update({action = "full"})

end

function cLootboxUI:LootboxOpen(args)

    if not args.contents then return end
    if not LootManager.current_box then return end

    LootManager:RecreateContents(args.contents)

    self:Update({action = "full"})
    self:ToggleVisible()

end

function cLootboxUI:WindowClosed()

    self:ToggleVisible()

end


function cLootboxUI:Update(args)

    if not LootManager.current_box then return end

    if args.action == "full" then

        for i = 1, #LootManager.current_box.contents do

            ClientInventory.ui:PopulateEntry({index = i, loot = true, window = self.itemWindows[i]})

        end

    elseif args.action == "update" or args.action == "remove" then

        ClientInventory.ui:PopulateEntry({index = args.index, loot = true, window = self.itemWindows[args.index]})

    end

    self:ResizeWindow()

end

-- Call this to hide/unhide boxes and resize it! wohoo
function cLootboxUI:ResizeWindow()

    local total = 1
    local num_used_rows = 1

    for row = 1, self.num_rows do

        for i = 0, self.items_per_row - 1 do

            local window = self.itemWindows[total]

            if window and LootManager.current_box and total <= #LootManager.current_box.contents then
                window:Show()
                num_used_rows = row
            elseif window then
                window:Hide()
            end
    
            total = total + 1
        end

    end

    -- Todo fix this so that the scroll bar doesn't always appear
    self.table:SizeToContents()

end

function cLootboxUI:HoverEnterButton(button)

    self.tooltip_render = Events:Subscribe("Render", self, self.TooltipRender)
    self.tooltip_button = button

    ClientInventory.ui:PopulateTooltip(
        {button = button, index = button:GetDataNumber("stack_index"), tooltip = self.tooltip, tooltip_label = self.tooltip_label, loot = true})

end

function cLootboxUI:HoverLeaveButton(button)

    if self.tooltip_render then
        Events:Unsubscribe(self.tooltip_render)
        self.tooltip_render = nil
    end

    self.tooltip_button = nil

    self.tooltip:Hide()

end

function cLootboxUI:TooltipRender(args)

    self.tooltip:SetPosition(Mouse:GetPosition() - Vector2(self.tooltip:GetWidth() / 2, self.tooltip:GetHeight() * 1.25))
    self.tooltip:BringToFront()

end

function cLootboxUI:CreateWindow()

    local table = Table.Create(self.scrollControl, "table")
    table:SetSizeRel(Vector2(1,1))
    table:SetColumnCount(self.items_per_row)

    self.table = table
    self.tableRows = {}
    local total_index = 1

    for row = 1, self.num_rows do

        self.tableRows[row] = TableRow.Create(table, "tablerow"..tostring(row))
        self.tableRows[row]:SetSizeAutoRel(Vector2(1,1))
        table:AddRow(self.tableRows[row])
        self.tableRows[row]:SetMargin(Vector2(Render.Size.x * 0.005, Render.Size.x * 0.005), Vector2(0, 0))
    
        for i = 0, self.items_per_row - 1 do
            --table:SetColumnWidth(i, Render.Size.x * 0.05)
            local index = total_index

            local name = "lootitem" .. tostring(index)
    
            local itemWindow = BaseWindow.Create(self.scrollControl, name)
            itemWindow:SetSize(Vector2(Render.Size.x * 0.05, Render.Size.x * 0.05))
            itemWindow:SetMargin(Vector2(Render.Size.x * 0.01, Render.Size.x * 0.01), Vector2(Render.Size.x * 0.01, Render.Size.x * 0.01))
    
            local button_bg = Rectangle.Create(itemWindow, "button_bg")
            button_bg:SetSizeAutoRel(Vector2(1, 1))
            button_bg:SetColor(ClientInventory.ui.bg_colors.None)
    
            local button = Button.Create(itemWindow, "button")
            button:SetSizeAutoRel(Vector2(1, 1))
            button:SetBackgroundVisible(false)
    
            local durability_outer = Rectangle.Create(itemWindow, "dura_outer")
            durability_outer:SetSizeAutoRel(Vector2(0.0575, 0.9))
            durability_outer:SetPositionRel(Vector2(1, 0.5) - Vector2(durability_outer:GetSizeRel().x * 1.5, durability_outer:GetSizeRel().y / 2))
            durability_outer:SetColor(Color.Green)
            durability_outer:Hide()
    
            local equip_outer = Rectangle.Create(itemWindow, "equip_outer")
            equip_outer:SetSizeAutoRel(Vector2(0.15, 0.15))
            equip_outer:SetPositionRel(Vector2(1, 0.05) - Vector2(equip_outer:GetSizeRel().x * 2, 0))
            equip_outer:SetColor(Color.Black)
    
            local equip_inner = Rectangle.Create(equip_outer, "equip_inner")
            equip_inner:SetSizeAutoRel(Vector2(0.75, 0.75))
            equip_inner:SetPositionRel(Vector2(0.5, 0.5) - Vector2(0.75, 0.75) / 2.5)
            equip_inner:SetColor(Color.Green)
    
            equip_outer:Hide()
    
            local durability_inner = Rectangle.Create(durability_outer, "dura_inner")
            durability_inner:SetColor(Color.Black)
    
            local amount = Label.Create(itemWindow, "amount")
            amount:SetSizeAutoRel(Vector2(1, 1))
            amount:SetPadding(Vector2(Render.Size.x * 0.003, Render.Size.x * 0.003), 
                Vector2(Render.Size.x * 0.003, Render.Size.x * 0.003))
            amount:SetTextSize(12)
    
            local imagePanel = ImagePanel.Create(button_bg, "imagepanel")
            imagePanel:SetSizeAutoRel(Vector2(0.7, 0.7))
            imagePanel:SetPositionRel(Vector2(0.5, 0.5) - imagePanel:GetSizeRel() / 2)
    
            button:SetDataNumber("stack_index", index)
            button:Subscribe("Press", self, self.ClickItemButton)
            button:Subscribe("HoverEnter", self, self.HoverEnterButton)
            button:Subscribe("HoverLeave", self, self.HoverLeaveButton)

    
            self.tableRows[row]:SetCellContents(i, itemWindow)
    
            button:BringToFront()

            self.itemWindows[index] = itemWindow
            total_index = total_index + 1

        end
    

    end

    table:SizeToContents()

end

function cLootboxUI:LocalPlayerInput(args)

    if self.blockedActions[args.input] then return false end
    self:ToggleVisible()

end

function cLootboxUI:ToggleVisible()

    if self.window:GetVisible() then
        self.tooltip:Hide()
        self.window:Hide()
        ClientInventory.ui.tooltip:Hide()
        Events:Unsubscribe(self.LPI)
        self.LPI = nil
        if LootManager.current_box then
            Network:Send("Inventory/CloseBox" .. tostring(LootManager.current_box.uid)) -- Send event to close box
        end
    else
        self.window:Show()
        Mouse:SetPosition(Render.Size / 2)
        self.window:SetPosition(Render.Size / 2 - self.window:GetSize() / 2)
        self.LPI = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    end

    Mouse:SetVisible(self.window:GetVisible())
    LocalPlayer:SetValue("LootOpen", self.window:GetVisible())

end

function cLootboxUI:GetCategoryFromIndex(index)

    local slots = 0
    
    for k,v in pairs(Inventory.config.categories) do

        slots = slots + v.slots

        if index <= slots and index > 0 then return v.name end

    end

end


function cLootboxUI:KeyUp(args)

    if args.key == string.byte(self.open_key) then

        if self.window:GetVisible() then
            self:ToggleVisible()
        elseif IsValid(LootManager.current_looking_box) then
            LootManager.current_box = LootManager.current_looking_box
            Network:Send("Inventory/TryOpenBox" .. tostring(LootManager.current_looking_box.uid))
        end

    end

end
