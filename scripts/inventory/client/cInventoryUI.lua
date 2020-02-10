class 'cInventoryUI'

function cInventoryUI:__init()

    self.open_key = 'G'
    self.steam_id = tostring(LocalPlayer:GetSteamId().id)

    self.bg_colors = 
    {
        None = Color(0, 0, 0, 100),
        Equipped = Color(33, 217, 33, 255),
        Equipped_Under = Color(33, 217, 33, 100),
        Use = Color(200,200,200,100)
    }

    self.window = BaseWindow.Create("Inventory")
    self.window:SetSize(Vector2(Render.Size.x * 0.5, Render.Size.y))
    self.window:SetPosition(Render.Size - self.window:GetSize())
    self.window:Hide()
    self.window:Focus()
    self.window:SetBackgroundVisible(false)
    self.table = Table.Create(self.window)
    self.table:SetColumnCount(#Inventory.config.categories)
    self.table:SetSizeAutoRel(Vector2(1, 1))
    self.tableRow = TableRow.Create(self.table)
    self.tableRow:SetSizeAutoRel(Vector2(1,1))
    self.tableRow:SetMargin(Vector2(10, 10), Vector2(10, 10))
    self.table:AddRow(self.tableRow)

    self:CreateInventory()

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

    Events:Subscribe("KeyUp", self, self.KeyUp)
    Events:Subscribe("SetInventoryState", self, self.SetInventoryState)
    
end

function cInventoryUI:SetInventoryState(open)

    if open and not self.window:GetVisible() then
        self:ToggleVisible()
    elseif not open and self.window:GetVisible() then
        self:ToggleVisible()
    end

end

function cInventoryUI:Update(args)

    if args.action == "full" then
        for cat, _ in pairs(Inventory.contents) do
            for index, stack in pairs(Inventory.contents[cat]) do
                self:PopulateEntry({index = index, cat = cat})
            end
        end
    elseif args.action == "update" or args.action == "remove" then
        self:PopulateEntry({index = args.index, cat = args.cat})
    elseif args.action == "slots" then
        -- TODO: update slot text in categories
    end

end

function cInventoryUI:GetDurabilityColor(percent)
    return Color.FromHSV(120 * percent, 0.85, 0.85)
end

function cInventoryUI:GetItemNameWithAmount(stack)
    return string.format("%s (%i)", stack:GetProperty("name"), stack:GetAmount())
end

-- Updates an entry in the inventory so it matches the current inventory
-- To use with loot, use args.window as the main window, args.index as the index of the stack in
-- the loot, and set args.loot to true
function cInventoryUI:PopulateEntry(args)

    print("pop entry")
    local itemwindow = args.window

    local stack

    if not args.loot then
        stack = Inventory.contents[args.cat][args.index]
    elseif args.loot and LootManager.current_box and LootManager.current_box.contents[args.index] then
        stack = LootManager.current_box.contents[args.index]
    end

    if not itemwindow then
        print("itemwindow_"..stack:GetProperty("category")..args.index)
        itemwindow = self.window:FindChildByName("itemwindow_"..stack:GetProperty("category")..args.index, true)
    end

    local button = itemwindow:FindChildByName("button", true)
    local button_bg = itemwindow:FindChildByName("button_bg", true)
    local dura_outer = itemwindow:FindChildByName("dura_outer", true)
    local dura_inner = itemwindow:FindChildByName("dura_inner", true)
    local equip_outer = itemwindow:FindChildByName("equip_outer", true)
    local equip_inner = itemwindow:FindChildByName("equip_inner", true)

    if not stack then return end -- No valid item found

    local item_name = stack:GetProperty("name")
    button:SetText(self:GetItemNameWithAmount(stack))
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

end

function cInventoryUI:WindowClosed()
    self:ToggleVisible()
end

function cInventoryUI:CreateInventory()

    self.itemWindows = {}
    self.columnWindows = {} -- Tables for each column in the inventory

    local contents = Inventory.contents

    for index, cat_data in ipairs(Inventory.config.categories) do
        local columnWindow = Table.Create(self.window, "columnWindow_" .. cat_data.name)
        columnWindow:SetSizeAutoRel(Vector2(1,1))
        self.columnWindows[cat_data.name] = columnWindow
        self.tableRow:SetCellContents(index - 1, columnWindow)
        self.itemWindows[cat_data.name] = {}
    end

    -- Create entries for each item
    for _, cat_data in pairs(Inventory.config.categories) do
        for i = 1, Inventory.config.max_slots_per_category do -- Pre-create all itemWindows and utilize as needed
            local itemWindow = self:CreateItemWindow(cat_data.name, i)
            self.itemWindows[cat_data.name][i] = itemWindow
        end
    end

end

-- Creates and returns a new item window. Can be used for loot and inventory
function cInventoryUI:CreateItemWindow(cat, index)

    -- For reference, look at PopulateRightClick menu in old version for vertical buttons
    local parent_column = self.columnWindows[cat]

    local tableRow = TableRow.Create(self.table)
    parent_column:AddRow(tableRow)

    print("create window " .. "itemwindow_"..cat..index)
    local itemWindow = BaseWindow.Create(tableRow, "itemwindow_"..cat..index)
    itemWindow:SetSizeAutoRel(Vector2(1,1))
    itemWindow:SetPadding(Vector2(10, 10), Vector2(10, 10))

    local button_bg = Rectangle.Create(itemWindow, "button_bg")
    button_bg:SetSizeAutoRel(Vector2(1, 1))
    button_bg:SetColor(self.bg_colors.None)

    local button = Button.Create(itemWindow, "button")
    button:SetSizeAutoRel(Vector2(1, 1))
    button:SetBackgroundVisible(false)
    button:SetTextSize(20)

    local durability_outer = Rectangle.Create(itemWindow, "dura_outer")
    durability_outer:SetSizeAutoRel(Vector2(0.9, 0.01))
    durability_outer:SetPositionRel(Vector2(0.5, 0.1) - durability_outer:GetSizeRel() / 2)
    durability_outer:SetColor(Color.Yellow)
    durability_outer:Hide()

    local equip_outer = Rectangle.Create(itemWindow, "equip_outer")
    equip_outer:SetSizeAutoRel(Vector2(0.1, 0.1))
    equip_outer:SetPositionRel(Vector2(0.05, 0.05))
    equip_outer:SetColor(Color.Black)

    local equip_inner = Rectangle.Create(equip_outer, "equip_inner")
    equip_inner:SetSizeAutoRel(Vector2(0.9, 0.9))
    equip_inner:SetPositionRel(Vector2(0.5, 0.5) - equip_inner:GetSizeRel() / 2)
    equip_inner:SetColor(Color.Green)

    equip_outer:Hide()

    local durability_inner = Rectangle.Create(durability_outer, "dura_inner")
    durability_inner:SetColor(Color.Black)

    --self:PopulateEntry({index = index})
    tableRow:SizeToContents()

    button:SetDataNumber("stack_index", index)

    button:Subscribe("Press", self, self.LeftClickItemButton)
    button:Subscribe("RightPress", self, self.RightClickItemButton)
    button:Subscribe("HoverEnter", self, self.HoverEnterButton)
    button:Subscribe("HoverLeave", self, self.HoverLeaveButton)

    button:BringToFront()

end

function cInventoryUI:HoverEnterButton(button)
    -- Called when the mouse hovers over a button
    -- use local stack = Inventory.contents[args.button:GetDataNumber("stack_index")] to get stack
end

function cInventoryUI:HoverLeaveButton(button)
    -- Called when the mouse stops hovering over a button
end

function cInventoryUI:RightClickItemButton(button)
    -- Called when a button is right clicked
end

function cInventoryUI:ConfirmAmountButtonPress(button)

    if not self.current_right_clicked then return end

    local index = self.current_right_clicked:GetDataNumber("stack_index")
    local amount = math.round(self.input_slider:GetValue())

    local stack = Inventory.contents[index]
    if not stack then return end

    if amount < 1 or amount > stack:GetAmount() then return end

    Network:Send("Inventory/" .. self.rightClickMenuAction .. self.steam_id, {index = index, amount = amount})

end

function cInventoryUI:LeftClickItemButton(button)

    local index = button:GetDataNumber("stack_index")
    local stack = Inventory.contents[index]
    if not stack then return end
    
    if stack:GetProperty("can_equip") then

        Network:Send("Inventory/ToggleEquipped" .. self.steam_id, {index = index})

    elseif stack:GetProperty("can_use") then

        Network:Send("Inventory/Use" .. self.steam_id, {index = index})

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

    elseif action == "Split" then

        Mouse:SetPosition(Render.Size / 2)

    elseif action == "Shift" then

        Network:Send("Inventory/Shift" .. self.steam_id, {index = index})

    elseif action == "Equip" or action == "Unequip" then

        Network:Send("Inventory/ToggleEquipped" .. self.steam_id, {index = index})

    elseif action == "Use" then

        Network:Send("Inventory/Use" .. self.steam_id, {index = index})

    elseif action == "Move Left" then

        Network:Send("Inventory/Swap" .. self.steam_id, {from = index, to = index - 1})

    elseif action == "Move Right" then

        Network:Send("Inventory/Swap" .. self.steam_id, {from = index, to = index + 1})

    elseif action == "Merge" then

        Network:Send("Inventory/Combine" .. self.steam_id, {index = index})

    end


end

function cInventoryUI:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

function cInventoryUI:ToggleVisible()

    if self.window:GetVisible() then
        self.window:Hide()
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

function cInventoryUI:KeyUp(args)

    if args.key == string.byte(self.open_key) then
        self:ToggleVisible()
    end

end

