class 'cInventoryUI'

function cInventoryUI:__init()

    self.open_key = 'G'
    self.steam_id = tostring(LocalPlayer:GetSteamId().id)

    self.icons = {}
    self:LoadIcons()

    self.bg_colors = 
    {
        None = Color(0, 0, 0, 100),
        Equipped = Color(33, 217, 33, 255),
        Equipped_Under = Color(33, 217, 33, 100),
        Use = Color(200,200,200,100)
    }

    self.window = Window.Create("Inventory")
    self.window:SetSize(Render.Size * 0.5)
    self.window:SetPosition(Render.Size / 2 - self.window:GetSize() / 2)
    self.window:SetTitle("Inventory")
    self.window:Hide()
    self.window:Focus()

    self.tabControl = TabControl.Create(self.window, "TabControl")
    self.tabControl:SetSizeAutoRel(Vector2(1, 1))
    --self.tabControl:SetReorderAllowed(true)
    --self.tabControl:SetTabStripPosition(2) -- Make the tabs go on the side
    self:CreateTabs()

    self.rightClickMenuBackground = Button.Create()
    self.rightClickMenuBackground:SetPosition(Vector2.Zero)
    self.rightClickMenuBackground:SetSize(Render.Size)
    self.rightClickMenuBackground:SetBackgroundVisible(false)
    self.rightClickMenuBackground:Subscribe("DoubleClick", self, self.CloseMenus)
    self.rightClickMenuBackground:Subscribe("Press", self, self.CloseMenus)
    self.rightClickMenuBackground:Subscribe("RightPress", self, self.CloseMenus)
    self.rightClickMenuBackground:Hide()

    self.rightClickMenu = Rectangle.Create()
    self.rightClickMenu:SetSize(Vector2(Render.Size.x * 0.03, Render.Size.x * 0.1))
    self.rightClickMenu:SetColor(Color(0, 0, 0, 0))
    self.rightClickMenu:Hide()
    self.rightClickMenuCnt = 0

    self.rightClickMenuSubs = {}

    self.tooltip = Rectangle.Create()
    self.tooltip:SetColor(Color(0, 0, 0, 150))
    self.tooltip_label = Label.Create(self.tooltip, "title")
    self.tooltip_label:SetTextSize(18)
    self.tooltip_label:SetAlignment(GwenPosition.Center)
    self.tooltip_label:SetPadding(Vector2(Render.Size.x * 0.003, Render.Size.x * 0.003), 
    Vector2(Render.Size.x * 0.003, Render.Size.x * 0.003))
    self.tooltip_label:SetTextPadding(Vector2(10,10), Vector2(10, 10))
    self.tooltip:Hide()

    self.input_count = 0
    self.input = Rectangle.Create()
    self.input:SetSize(Vector2(Render.Size.x * 0.2, Render.Size.y * 0.15))
    self.input:SetPosition(Render.Size / 2 - self.input:GetSize() / 2)
    self.input:SetColor(Color(0,0,0,100))
    self.input_slider = HorizontalSlider.Create(self.input)
    self.input_slider:SetSizeAutoRel(Vector2(1,0.2))
    self.input_slider:SetPositionRel(Vector2(0.5, 0.5) - self.input_slider:GetSizeRel() / 2)
    self.input_slider:Subscribe("ValueChanged", self, self.SliderValueChanged)
    self.input_button = Button.Create(self.input)
    self.input_button:SetText("Drop")
    self.input_button:SetTextSize(16)
    self.input_button:SetSizeAutoRel(Vector2(1,0.25))
    self.input_button:SetPositionRel(Vector2(0, 1 - self.input_button:GetSizeRel().y))
    self.input_button:Subscribe("Press", self, self.ConfirmAmountButtonPress)
    self.input_label = Label.Create(self.input)
    self.input_label:SetText("This is item")
    self.input_label:SetTextSize(20)
    self.input_label:SetAlignment(GwenPosition.Center)
    self.input_label:SetSizeAutoRel(Vector2(1,0.5))
    self.input_label:SetPositionRel(Vector2(0, 0))
    self.input_label:SetPadding(Vector2(Render.Size.x * 0.0015, Render.Size.x * 0.0015), 
    Vector2(Render.Size.x * 0.0015, Render.Size.x * 0.0015))
    self.input_label:SetTextPadding(Vector2(10,10), Vector2(10, 10))

    self.input:Hide()

    self.hotbar = {}

    self:CreateHotbar()

    LocalPlayer:SetValue("InventoryOpen", false)

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
        [Action.VehicleFireRight] = true,
        [Action.ThrowGrenade] = true
    }

    self.hotbar_keys = {}

    -- Initialize hotbar keys
    for i = 0, 9 do
        self.hotbar_keys[string.byte(tostring(i < 9 and i + 1 or 0))] = i + 1
    end

    Events:Subscribe("KeyUp", self, self.KeyUp)
    Events:Subscribe("SetInventoryState", self, self.SetInventoryState)
    
    self.window:Subscribe("WindowClosed", self, self.WindowClosed)

end

function cInventoryUI:SetInventoryState(open)

    if open and not self.window:GetVisible() then
        self:ToggleVisible()
    elseif not open and self.window:GetVisible() then
        self:ToggleVisible()
    end

end

function cInventoryUI:CloseMenus()

    self.rightClickMenuBackground:Hide()
    self.rightClickMenu:Hide()
    self.input:Hide()

end

function cInventoryUI:SliderValueChanged()

    if self.input_slider:GetDataString("action") == "Hotbar" then
        self.input_button:SetText("Assign to slot " .. round(self.input_slider:GetValue()))
    else
        local index = self.current_right_clicked:GetDataNumber("stack_index")
        local stack = Inventory.contents[index]
        local val = round(self.input_slider:GetValue())
        if IsNaN(val) then
            val = 1
        end
        self.input_button:SetText(self.input_slider:GetDataString("action") .. " " .. val)
    end

end

function cInventoryUI:UpdateHotbar(args)

    -- First, reset all old hotbar values
    for hotbar_index, inventory_index in pairs(self.hotbar) do

        local itemwindow = self.window:FindChildByName("itemwindow"..inventory_index, true)

        if itemwindow then

            if itemwindow:GetDataNumber("hotbar_link") > 0 then

                local hotbaritem = self.hotbar_window:FindChildByName("hotbaritem"..hotbar_index, true)
                hotbaritem:SetDataNumber("inv_link", 0)
                self:PopulateEntry(
                    {window = hotbaritem, index = 0, hotbar = true})

            end

            itemwindow:SetDataNumber("hotbar_link", 0)
        end

    end

    self.hotbar = args

    -- Then, reinitialize new hotbar values
    for hotbar_index, inventory_index in pairs(self.hotbar) do

        local itemwindow = self.window:FindChildByName("itemwindow"..inventory_index, true)

        if itemwindow then
            itemwindow:SetDataNumber("hotbar_link", hotbar_index)

            local hotbaritem = self.hotbar_window:FindChildByName("hotbaritem"..hotbar_index, true)
            hotbaritem:SetDataNumber("inv_link", inventory_index)

            self:PopulateEntry({index = inventory_index})
        end

    end

end

function cInventoryUI:Update(args)

    if args.action == "full" then

        local slots = GetInventoryNumSlots()
        for i = 1, slots do

            self:PopulateEntry({index = i})

        end

    elseif args.action == "update" or args.action == "remove" then

        self:PopulateEntry({index = args.index})

    end

end

function cInventoryUI:GetDurabilityColor(percent)

    return Color.FromHSV(120 * percent, 0.85, 0.85)

end

-- Updates an entry in the inventory so it matches the current inventory
-- To use with loot, use args.window as the main window, args.index as the index of the stack in
-- the loot, and set args.loot to true
function cInventoryUI:PopulateEntry(args)

    local itemwindow = args.window

    if not itemwindow then

        itemwindow = self.window:FindChildByName("itemwindow"..args.index, true)

    end

    local stack

    if not args.loot then

        stack = Inventory.contents[args.index]

    elseif args.loot and LootManager.current_box and LootManager.current_box.contents[args.index] then

        stack = LootManager.current_box.contents[args.index]

    end

    local button = itemwindow:FindChildByName("button", true)
    local imagePanel = itemwindow:FindChildByName("imagepanel", true)
    local amount = itemwindow:FindChildByName("amount", true)
    local button_bg = itemwindow:FindChildByName("button_bg", true)
    local dura_outer = itemwindow:FindChildByName("dura_outer", true)
    local dura_inner = itemwindow:FindChildByName("dura_inner", true)
    local equip_outer = itemwindow:FindChildByName("equip_outer", true)
    local equip_inner = itemwindow:FindChildByName("equip_inner", true)

    if stack then

        local item_name = stack:GetProperty("name")
        imagePanel:SetImage(self.icons["item_"..item_name] and self.icons["item_"..item_name] or self.icons["item_Unknown"])
        amount:SetText(tostring(stack:GetAmount())) 
        --[[button_bg:SetColor(
            stack.contents[1].equipped and self.bg_colors.Equipped 
            or (stack:GetOneEquipped() and self.bg_colors.Equipped_Under or self.bg_colors.None))--]]
        
        if stack:GetOneEquipped() then

            equip_inner:SetColor(
                stack.contents[1].equipped and self.bg_colors.Equipped 
                or (stack:GetOneEquipped() and self.bg_colors.Equipped_Under or self.bg_colors.None)
            )
            equip_outer:Show()

        else

            equip_outer:Hide()

        end

        
        if stack:GetProperty("durable") then

            dura_inner:SetSizeAutoRel(Vector2(1, 1 - (stack.contents[1].durability / stack.contents[1].max_durability)))
            dura_outer:SetColor(self:GetDurabilityColor(stack.contents[1].durability / stack.contents[1].max_durability))
            dura_outer:Show()

        else

            dura_outer:Hide()

        end

    else
        imagePanel:SetImage(self.icons["item_None"])
        amount:SetText("")
        button_bg:SetColor(self.bg_colors.None)
        dura_outer:Hide()
        equip_outer:Hide()
    end


    if args.hotbar or args.loot then return end

    local hotbar_link = itemwindow:GetDataNumber("hotbar_link")

    if hotbar_link > 0 then
        self:PopulateEntry({window = self.hotbar_window:FindChildByName("hotbaritem"..hotbar_link, true), index = args.index, hotbar = true})
    end

end

function cInventoryUI:WindowClosed()

    self:ToggleVisible()

end

function cInventoryUI:ShowRightClickMenu()

    self.rightClickMenuBackground:BringToFront()
    self.rightClickMenuBackground:Show()
    self.rightClickMenu:BringToFront()
    self.rightClickMenu:Show()

end

function cInventoryUI:ShowInputMenu()

    self.rightClickMenuBackground:BringToFront()
    self.rightClickMenuBackground:Show()
    self.input:BringToFront()
    self.input:Show()

end

function cInventoryUI:LoadIcons()

    local loading_icons = {}

    -- Start loading all the icons
    --Events:Fire("loader/RegisterResource", {count = #Inventory.config.icons})

    for index, icon_name in pairs(Inventory.config.icons) do

        self.icons[icon_name] = Image.Create(AssetLocation.Resource, icon_name)
        
    end

    for k,v in pairs(self.icons) do loading_icons[k] = true end

    self.resource_loader = Timer.SetInterval(250, function()

        for icon_name, v in pairs(loading_icons) do

            if not self.icons[icon_name]:GetFailed() then
                --Events:Fire("loader/CompleteResource", {count = 1})
                --print("finish icon " .. icon_name)

                loading_icons[icon_name] = nil

                -- Finished loading icons
                if #loading_icons == 0 and self.resource_loader then

                    Timer.Clear(self.resource_loader)
                    self.resource_loader = nil

                end
            end

        end


    end)

end

function cInventoryUI:CreateTabs()

    self.tabButtons = {}
    self.itemWindows = {}

    local contents = Inventory.contents

    local total_index = 1

    for index, tab_data in ipairs(Inventory.config.categories) do

        local tab_name = tab_data.name
        local slots = tab_data.slots

        local tab = self.tabControl:AddPage(tab_name)
        table.insert(self.tabButtons, tab)

        local scrollControl = ScrollControl.Create(tab:GetPage())
        scrollControl:SetSizeAutoRel(Vector2(1, 1))
        scrollControl:SetScrollable(false, true)

        local table = Table.Create(scrollControl)
        table:SetColumnCount(8)
        table:SetSizeAutoRel(Vector2(1, 1))

        self.itemWindows[tab_name] = {}
        local slots_left = slots - 1

        for j = 1, round(slots / 8) do

            local tableRow = TableRow.Create(table)
            tableRow:SetMargin(Vector2(0, 0), Vector2(0, Render.Size.x * 0.01))
            table:AddRow(tableRow)

            for i = 0, math.min(slots_left, 7) do
                local itemWindow = BaseWindow.Create(scrollControl, "itemwindow"..total_index)
                itemWindow:SetSize(Vector2(Render.Size.x * 0.05, Render.Size.x * 0.05))
                itemWindow:SetDataNumber("hotbar_link", 0)

                local button_bg = Rectangle.Create(itemWindow, "button_bg")
                button_bg:SetSizeAutoRel(Vector2(1, 1))
                button_bg:SetColor(self.bg_colors.None)

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

                local stack = contents[total_index]

                local imagePanel = ImagePanel.Create(button_bg, "imagepanel")
                imagePanel:SetSizeAutoRel(Vector2(0.7, 0.7))
                imagePanel:SetPositionRel(Vector2(0.5, 0.5) - imagePanel:GetSizeRel() / 2)

                self:PopulateEntry({index = total_index})

                button:SetDataNumber("stack_index", total_index)

                tableRow:SetCellContents(i, itemWindow)

                button:Subscribe("Press", self, self.LeftClickItemButton)
                button:Subscribe("RightPress", self, self.RightClickItemButton)
                button:Subscribe("HoverEnter", self, self.HoverEnterButton)
                button:Subscribe("HoverLeave", self, self.HoverLeaveButton)

                button:BringToFront()

                self.itemWindows[tab_name][i] = itemWindow
                slots_left = slots_left - 1
                total_index = total_index + 1
            end

        end

    end

end

function cInventoryUI:CreateHotbar()

    self.hotbar_window = Rectangle.Create("hotbar")
    self.hotbar_window:SetColor(Color(0,0,0,0))
    self.hotbar_window:SetSize(Vector2(Render.Size.x * 0.425, Render.Size.y * 0.085))
    self.hotbar_window:SetPosition(
        Vector2(Render.Size.x / 2, Render.Size.y) - Vector2(self.hotbar_window:GetSize().x / 2, self.hotbar_window:GetSize().y * 1.5))


    local table = Table.Create(self.hotbar_window)
    table:SetSizeAutoRel(Vector2(1, 1))
    table:SetColumnCount(10)

    local tableRow = TableRow.Create(table)
    tableRow:SetSizeAutoRel(Vector2(1,1))
    table:AddRow(tableRow)

    for i = 0, 9 do
        table:SetColumnWidth(i, Render.Size.x * 0.0425)

        local itemWindow = BaseWindow.Create(self.hotbar_window, "hotbaritem"..i+1)
        itemWindow:SetSize(Vector2(Render.Size.x * 0.04, Render.Size.x * 0.04))
        itemWindow:SetMargin(Vector2(Render.Size.x * 0.01, Render.Size.x * 0.01), Vector2(Render.Size.x * 0.01, Render.Size.x * 0.01))
        itemWindow:SetDock(GwenPosition.Center)
        itemWindow:SetDataNumber("inv_link", 0)

        local button_bg = Rectangle.Create(itemWindow, "button_bg")
        button_bg:SetSizeAutoRel(Vector2(1, 1))
        button_bg:SetColor(self.bg_colors.None)

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
        equip_inner:SetSizeAutoRel(Vector2(0.85, 0.85))
        equip_inner:SetPositionRel(Vector2(0.5, 0.5) - Vector2(0.85, 0.85) / 2.5)
        equip_inner:SetColor(Color.Green)

        equip_outer:Hide()

        local durability_inner = Rectangle.Create(durability_outer, "dura_inner")
        durability_inner:SetColor(Color.Black)

        local amount = Label.Create(itemWindow, "amount")
        amount:SetSizeAutoRel(Vector2(1, 1))
        amount:SetPadding(Vector2(Render.Size.x * 0.003, Render.Size.x * 0.003), 
            Vector2(Render.Size.x * 0.003, Render.Size.x * 0.003))
        amount:SetTextSize(10)

        local imagePanel = ImagePanel.Create(button_bg, "imagepanel")
        imagePanel:SetSizeAutoRel(Vector2(0.7, 0.7))
        imagePanel:SetPositionRel(Vector2(0.5, 0.5) - imagePanel:GetSizeRel() / 2)

        self:PopulateEntry({window = itemWindow, hotbar = true})

        button:SetDataNumber("stack_index", i+1)

        tableRow:SetCellContents(i, itemWindow)

        button:BringToFront()

    end

end

function cInventoryUI:HoverEnterButton(button)

    self.tooltip_render = Events:Subscribe("Render", self, self.TooltipRender)
    self.tooltip_button = button

    self:PopulateTooltip({button = button, tooltip = self.tooltip, tooltip_label = self.tooltip_label})

end

function cInventoryUI:HoverLeaveButton(button)

    if self.tooltip_render then
        Events:Unsubscribe(self.tooltip_render)
        self.tooltip_render = nil
    end

    self.tooltip_button = nil

    self.tooltip:Hide()

end

-- button, tooltip, tooltip_label, loot
function cInventoryUI:PopulateTooltip(args)

    local stack = Inventory.contents[args.button:GetDataNumber("stack_index")]

    if args.loot then
        stack = LootManager.current_box.contents[args.index]
    end

    if not stack then return end

    args.tooltip_label:SetText(stack:GetProperty("name"))
    args.tooltip_label:SizeToContents()

    args.tooltip:SizeToChildren()
    args.tooltip:Show()
    args.tooltip:BringToFront()

end

function cInventoryUI:TooltipRender(args)

    self.tooltip:SetPosition(Mouse:GetPosition() - Vector2(self.tooltip:GetWidth() / 2, self.tooltip:GetHeight() * 1.25))
    self.tooltip:BringToFront()

end

function cInventoryUI:RightClickItemButton(button)

    self.rightClickMenu:SetPosition(Mouse:GetPosition() - Vector2(5, 5))
    self:PopulateRightClickMenu(button)
    self.current_right_clicked = button

end

-- Add buttons to the menu based on what item was right clicked
function cInventoryUI:PopulateRightClickMenu(button)

    local stack = Inventory.contents[button:GetDataNumber("stack_index")]

    if not stack then return end

    -- Remove all existing children
    self.rightClickMenu:RemoveAllChildren()

    local options = {}

    if stack:GetProperty("can_equip") then
        table.insert(options, stack:GetProperty("equipped") and "Unequip" or "Equip")
    elseif stack:GetProperty("can_use") then
        table.insert(options, "Use")
    end

    if stack:GetAmount() > 1 then

        table.insert(options, "Split")
        if stack:GetProperty("can_equip") or stack:GetProperty("durable") then
            table.insert(options, "Shift")
        end

    end

    -- THESE THINGS STOP WORKING AFTER CONSUMABLES CATEGORY
    if self:GetCategoryFromIndex(button:GetDataNumber("stack_index") - 1) == stack:GetProperty("category") then
        table.insert(options, "Move Left")
    end
    
    if self:GetCategoryFromIndex(button:GetDataNumber("stack_index") + 1) == stack:GetProperty("category") then
        table.insert(options, "Move Right")
    end
    

    if stack:GetProperty("can_equip") or stack:GetProperty("can_use") then
        table.insert(options, "Hotbar")
    end

    
    if stack:GetAmount() < stack:GetProperty("stacklimit") then
        table.insert(options, "Merge")
    end

    if not LocalPlayer:InVehicle() then -- TODO change this so they can drop items to vehicle storage
        table.insert(options, "Drop")
    end

    local button_size = Vector2(Render.Size.x * 0.04, 0)
    self.rightClickMenu:SetSize(Vector2(button_size.x, button_size.y * #options))

    local table = Table.Create(self.rightClickMenu)
    table:SetColumnCount(1)
    table:SetSizeAutoRel(Vector2(1, 1))

    -- For as many options as we have
    for i = 1, #options do

        -- Add a table row and a button
        local tableRow = TableRow.Create(table)
        tableRow:SetSize(button_size)
        tableRow:SetMargin(Vector2(0,0), Vector2(0,-3))
        table:AddRow(tableRow)

        local buttonWindow = BaseWindow.Create(tableRow)
        buttonWindow:SetSize(button_size)
        buttonWindow:SetMargin(Vector2(0, 0), Vector2(0, 0))
        buttonWindow:SetPadding(Vector2(0, 0), Vector2(0, 0))

        local button = Button.Create(buttonWindow)
        button:SetText(options[i])
        --button:SetTextSize(16)
        button:SetPadding(Vector2(Render.Size.x * 0.005, Render.Size.x * 0.005), Vector2(Render.Size.x * 0.005, Render.Size.x * 0.005))
        button:SizeToContents()
        button:SetWidthRel(1)
        button:SetMargin(Vector2(0, 0), Vector2(0, 0))

        button:Subscribe("Press", self, self.ClickRightClickMenuButton)

        buttonWindow:SizeToChildren()
        tableRow:SetCellContents(0, buttonWindow)
        tableRow:SizeToContents()

    end

    table:SizeToContents()
    self.rightClickMenu:SizeToChildren()
    self:ShowRightClickMenu()

end

function cInventoryUI:PopulateInput(args)

    local index = args.button:GetDataNumber("stack_index")
    local stack = Inventory.contents[index]

    self.input_slider:SetDataString("action", args.action)

    if args.action == "Drop" then

        self.input_slider:SetRange(1, stack:GetAmount())
        self.input_slider:SetNotchCount(stack:GetAmount() - 1)
        self.input_slider:SetValue(round(stack:GetAmount()))
        self.input_button:SetText(self.input_slider:GetDataString("action") .. " " .. round(stack:GetAmount()))
        self.input_label:SetText(stack:GetProperty("name"))

    elseif args.action == "Split" then

        self.input_slider:SetRange(1, stack:GetAmount() - 1)
        self.input_slider:SetNotchCount(stack:GetAmount() - 2)
        self.input_slider:SetValue(math.ceil((stack:GetAmount() - 1) / 2))
        self.input_button:SetText(self.input_slider:GetDataString("action") .. " " .. math.ceil((stack:GetAmount() - 1) / 2))
        self.input_label:SetText(stack:GetProperty("name"))

    elseif args.action == "Hotbar" then

        self.input_slider:SetRange(1, 10)
        self.input_slider:SetNotchCount(10)
        self.input_slider:SetValue(1, true)
        self.input_button:SetText("Assign to slot 1")
        self.input_label:SetText("Assign to Hotbar")

    end

    self.input_slider:SetClampToNotches(true)
    self.input:BringToFront()

end

function cInventoryUI:ConfirmAmountButtonPress(button)

    if not self.current_right_clicked then return end

    self:CloseMenus()

    local index = self.current_right_clicked:GetDataNumber("stack_index")
    local amount = round(self.input_slider:GetValue())

    if self.rightClickMenuAction ~= "Hotbar" then

        local stack = Inventory.contents[index]
        if not stack then return end

        if amount < 1 or amount > stack:GetAmount() then return end

        Network:Send("Inventory/" .. self.rightClickMenuAction .. self.steam_id, {index = index, amount = amount})

    else

        Network:Send("Inventory/" .. self.rightClickMenuAction .. self.steam_id, {index = index, hotbar_index = amount})

    end


end

function cInventoryUI:LeftClickItemButton(button)

    local index = button:GetDataNumber("stack_index")
    local stack = Inventory.contents[index]
    if not stack then return end
    
    if stack:GetProperty("can_equip") then

        Network:Send("Inventory/ToggleEquipped" .. self.steam_id, {index = index})
        self:CloseMenus()
        self.rightClickMenu:Hide()

    elseif stack:GetProperty("can_use") then

        Network:Send("Inventory/Use" .. self.steam_id, {index = index})
        self:CloseMenus()
        self.rightClickMenu:Hide()

    end

end

function cInventoryUI:ClickRightClickMenuButton(button)

    if not self.current_right_clicked then return end

    local index = self.current_right_clicked:GetDataNumber("stack_index")
    local stack = Inventory.contents[index]
    if not stack then return end

    local action = button:GetText()
    self.rightClickMenuAction = action

    if action == "Drop" then

        Mouse:SetPosition(Render.Size / 2)
        self:PopulateInput({button = self.current_right_clicked, action = action})
        self:ShowInputMenu()
        self.rightClickMenu:Hide()

    elseif action == "Split" then

        Mouse:SetPosition(Render.Size / 2)
        self:PopulateInput({button = self.current_right_clicked, action = action})
        self:ShowInputMenu()
        self.rightClickMenu:Hide()

    elseif action == "Shift" then

        Network:Send("Inventory/Shift" .. self.steam_id, {index = index})
        self:CloseMenus()
        self.rightClickMenu:Hide()

    elseif action == "Equip" or action == "Unequip" then

        Network:Send("Inventory/ToggleEquipped" .. self.steam_id, {index = index})
        self:CloseMenus()
        self.rightClickMenu:Hide()

    elseif action == "Use" then

        Network:Send("Inventory/Use" .. self.steam_id, {index = index})
        self:CloseMenus()
        self.rightClickMenu:Hide()

    elseif action == "Move Left" then

        Network:Send("Inventory/Swap" .. self.steam_id, {from = index, to = index - 1})
        self:CloseMenus()
        self.rightClickMenu:Hide()

    elseif action == "Move Right" then

        Network:Send("Inventory/Swap" .. self.steam_id, {from = index, to = index + 1})
        self:CloseMenus()
        self.rightClickMenu:Hide()

    elseif action == "Merge" then

        Network:Send("Inventory/Combine" .. self.steam_id, {index = index})
        self:CloseMenus()
        self.rightClickMenu:Hide()

    elseif action == "Hotbar" then

        Mouse:SetPosition(Render.Size / 2)
        self:PopulateInput({button = self.current_right_clicked, action = action})
        self:ShowInputMenu()
        self.rightClickMenu:Hide()

    end


end

function cInventoryUI:LocalPlayerInput(args)

    if self.blockedActions[args.input] then return false end

end

function cInventoryUI:ToggleVisible()

    if self.window:GetVisible() then
        self.window:Hide()
        self.rightClickMenu:Hide()
        self.tooltip:Hide()
        self.input_count = 0
        self:CloseMenus()
        Events:Unsubscribe(self.LPI)
        self.LPI = nil
    else
        self.window:Show()
        Mouse:SetPosition(Render.Size / 2)
        self.LPI = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    end

    Mouse:SetVisible(self.window:GetVisible())
    LocalPlayer:SetValue("InventoryOpen", self.window:GetVisible())

end

function cInventoryUI:GetCategoryFromIndex(index)

    local slots = 0
    
    for k,v in ipairs(Inventory.config.categories) do

        slots = slots + v.slots

        if index <= slots and index > 0 then return v.name end

    end

end


function cInventoryUI:KeyUp(args)

    if args.key == string.byte(self.open_key) then
        
        self:ToggleVisible()

    elseif self.hotbar_keys[args.key] then

        local hotbarwindow = self.hotbar_window:FindChildByName("hotbaritem"..self.hotbar_keys[args.key], true)
        local hotbar_bg = hotbarwindow:FindChildByName("button_bg", true)
        hotbar_bg:SetColor(self.bg_colors.Use)

        Timer.SetTimeout(100, function()
            hotbar_bg:SetColor(self.bg_colors.None)
        end)

        if hotbarwindow:GetDataNumber("inv_link") > 0 then
            Network:Send("Inventory/HotbarUse" .. self.steam_id, {index = self.hotbar_keys[args.key]})
        end

    end

    if Game:GetState() ~= GUIState.Game then
        self.hotbar_window:Hide()
    else
        self.hotbar_window:Show()
    end

end

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end





