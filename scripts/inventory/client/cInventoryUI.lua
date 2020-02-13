class 'cInventoryUI'

function cInventoryUI:__init()

    self.open_key = 'G'
    self.steam_id = tostring(LocalPlayer:GetSteamId().id)
    self.dropping_counter = 0 -- Amount of stacks the player is trying to drop. If > 0, then drop items on inventory close
    self.dropping_items = {} -- Table of items (cat + index + amount) that the player is trying to drop
    self.hovered_button = nil -- Button in inventory currently hovered

    self.bg_colors = 
    {
        None = Color(0, 0, 0, 100),
        Equipped = Color(33, 217, 33, 255),
        Equipped_Under = Color(33, 217, 33, 100),
        Use = Color(200,200,200,100)
    }

    self.padding = 4

    self.window = BaseWindow.Create("Inventory")
    self.window:SetSize(Vector2(math.max(Render.Size.x / 2, 800), Render.Size.y))
    self.window:SetPosition(Render.Size - self.window:GetSize())
    self.window:Hide()
    self.window:Focus()
    self.window:SetBackgroundVisible(false)

    self.inv_dimensions = 
    {
        padding = self.padding, -- Padding on all sides is the same
        text_size = 20,
        button_size = Vector2(
            (self.window:GetSize().x - self.padding * #Inventory.config.categories) / #Inventory.config.categories, 40),
        cat_offsets = {} -- Per category offsets
    }
    
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
    Events:Subscribe("MouseScroll", self, self.MouseScroll)
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
        self:UpdateAllCategoryTitles()
    elseif args.action == "update" or args.action == "remove" then
        self:PopulateEntry({index = args.index, cat = args.cat})
        self:UpdateAllCategoryTitles()
    elseif args.action == "slots" then
        self:UpdateAllCategoryTitles()
    elseif args.action == "cat" then
        for i = 1, Inventory.config.max_slots_per_category do
            self:PopulateEntry({index = i, cat = args.cat})
        end
        self:UpdateAllCategoryTitles()
    end

end

function cInventoryUI:GetDurabilityColor(percent)
    return Color.FromHSV(120 * percent, 0.85, 0.85)
end

-- Gets formatted stack name for inventory/loot, like: Lockpick (50)
function cInventoryUI:GetItemNameWithAmount(stack, index)
    return string.format("%s (%s)", stack:GetProperty("name"), tostring(self:GetItemButtonStackAmount(stack, index)))
end

-- Returns 5/10 if dropping, otherwise returns the amount in the stack
function cInventoryUI:GetItemButtonStackAmount(stack, index)
    local itemWindow = self.window:FindChildByName("itemwindow_"..stack:GetProperty("category")..index, true)
    local button = itemWindow:FindChildByName("button", true)

    if button:GetDataBool("dropping") then -- If they are dropping this stack
        return string.format("%i/%i", button:GetDataNumber("drop_amount"), stack:GetAmount())
    else -- Otherwise
        return stack:GetAmount()
    end
end

-- Updates an entry in the inventory so it matches the current inventory
-- To use with loot, use args.window as the main window, args.index as the index of the stack in
-- the loot, and set args.loot to true
function cInventoryUI:PopulateEntry(args)

    local itemwindow = args.window

    local stack

    if not args.loot then
        stack = Inventory.contents[args.cat][args.index]
    elseif args.loot and LootManager.current_box and LootManager.current_box.contents[args.index] then
        stack = LootManager.current_box.contents[args.index]
    end

    if not itemwindow then
        itemwindow = self.window:FindChildByName("itemwindow_"..(args.cat or stack:GetProperty("category"))..args.index, true)
    end

    local button = itemwindow:FindChildByName("button", true)
    local button_bg = itemwindow:FindChildByName("button_bg", true)
    local durability = itemwindow:FindChildByName("dura", true)
    local equip_outer = itemwindow:FindChildByName("equip_outer", true)
    local equip_inner = itemwindow:FindChildByName("equip_inner", true)

    if not stack then -- No item found, hide the entry
        itemwindow:Hide()
        return
    else
        itemwindow:Show()
    end

    local item_name = stack:GetProperty("name")
    button:SetText(self:GetItemNameWithAmount(stack, args.index))
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

        durability:SetSizeAutoRel(Vector2((stack.contents[1].durability / stack.contents[1].max_durability) / 0.95, 0.1))
        durability:SetColor(self:GetDurabilityColor(stack.contents[1].durability / stack.contents[1].max_durability))
        durability:Show()

    else

        durability:Hide()

    end

end

function cInventoryUI:CreateInventory()

    self.itemWindows = {}
    self.categoryTitles = {}

    local contents = Inventory.contents

    for index, cat_data in ipairs(Inventory.config.categories) do
        self.itemWindows[cat_data.name] = {}
        self.inv_dimensions[cat_data.name] = Vector2(
            self.inv_dimensions.button_size.x * (index - 1) +
            self.inv_dimensions.padding * (index + 1), 0) 
    end

    -- Create entries for each item
    for _, cat_data in pairs(Inventory.config.categories) do
        self.categoryTitles[cat_data.name] = self:CreateCategoryTitle(cat_data.name)
        for i = 1, Inventory.config.max_slots_per_category do -- Pre-create all itemWindows and utilize as needed
            local itemWindow = self:CreateItemWindow(cat_data.name, i)
            self.itemWindows[cat_data.name][i] = itemWindow
        end
    end

end

-- Updates all category titles in the inventory. Should be called when number of available slots changes (level up, items added/removed)
function cInventoryUI:UpdateAllCategoryTitles()
    for cat, _ in pairs(Inventory.contents) do
        self:UpdateCategoryTitle(cat)
    end
end

-- TODO: make this method shared
function cInventoryUI:GetNumSlotsInCategory(cat)
    if not Inventory.slots then return end
    assert(Inventory.slots[cat] ~= nil, "cInventoryUI:GetNumSlotsInCategory failed: category was invalid (given: " .. cat .. ")")
    local total = 0

    for slot_type, amount in pairs(Inventory.slots[cat]) do
        total = total + amount
    end

    return total
end

function cInventoryUI:GetCategoryTitleText(cat)
    return string.format("%s %i/%i", -- TODO: add backpack support
        cat,
        #Inventory.contents[cat],
        self:GetNumSlotsInCategory(cat) or 0)
end

function cInventoryUI:UpdateCategoryTitle(cat)
    self.categoryTitles[cat]:SetText(self:GetCategoryTitleText(cat))
    self.categoryTitles[cat]:SetPosition(self:GetCategoryTitlePosition(cat))
end

function cInventoryUI:CreateCategoryTitle(cat)
    local categoryTitle = Label.Create(self.window, "categorytitle_"..cat)
    categoryTitle:SetSize(Vector2(self.inv_dimensions.button_size.x, self.inv_dimensions.button_size.y * 0.5))
    categoryTitle:SetTextSize(14)
    categoryTitle:SetAlignment(GwenPosition.Center)
    return categoryTitle
end

function cInventoryUI:GetCategoryTitlePosition(cat)
    local index = Inventory.contents and #Inventory.contents[cat] or 0
    return Vector2(
        self.inv_dimensions[cat].x - self.inv_dimensions.padding * 2,
        self.window:GetSize().y - (self.inv_dimensions.button_size.y * index)
        - self.inv_dimensions.padding * (index + 1) - self.categoryTitles[cat]:GetSize().y
    )
end

function cInventoryUI:GetItemWindowPosition(cat, index)
    return Vector2(
        self.inv_dimensions[cat].x - self.inv_dimensions.padding * 2,
        self.window:GetSize().y - (self.inv_dimensions.button_size.y * index)
        - self.inv_dimensions.padding * index
    )
end

-- Creates and returns a new item window. Can be used for loot and inventory
function cInventoryUI:CreateItemWindow(cat, index)

    local itemWindow = BaseWindow.Create(self.window, "itemwindow_"..cat..index)
    itemWindow:SetSize(self.inv_dimensions.button_size)
    itemWindow:SetPosition(self:GetItemWindowPosition(cat, index))

    local button_bg = Rectangle.Create(itemWindow, "button_bg")
    button_bg:SetSizeAutoRel(Vector2(1, 1))
    button_bg:SetColor(InventoryUIStyle.colors.default.background)

    local button = Button.Create(itemWindow, "button")
    button:SetSizeAutoRel(Vector2(1, 1))
    button:SetBackgroundVisible(false)
    button:SetTextSize(self.inv_dimensions.text_size)
    button:SetTextPadding(Vector2(500,500), Vector2(500,500))
    local colors = InventoryUIStyle.colors.default
    button:SetTextColor(colors.text)
    button:SetTextNormalColor(colors.text)
    button:SetTextHoveredColor(colors.text_hover)
    button:SetTextPressedColor(colors.text_hover)

    local durability = Rectangle.Create(itemWindow, "dura")
    durability:SetPositionRel(Vector2(0.05, 0.75))
    durability:Hide()

    local equip_outer = Rectangle.Create(itemWindow, "equip_outer")
    equip_outer:SetSizeAutoRel(Vector2(20, 20))
    equip_outer:SetPositionRel(Vector2(0.05, 0.05))
    equip_outer:SetColor(Color.Black)

    local equip_inner = Rectangle.Create(equip_outer, "equip_inner")
    equip_inner:SetSizeAutoRel(Vector2(0.9, 0.9))
    equip_inner:SetPositionRel(Vector2(0.5, 0.5) - equip_inner:GetSizeRel() / 2)
    equip_inner:SetColor(Color.Green)

    local border_top = Rectangle.Create(itemWindow, "border_top")
    border_top:SetSizeAutoRel(Vector2(1, 0))
    border_top:SetHeight(InventoryUIStyle.border_size)
    border_top:SetPosition(Vector2(0, 0))

    local border_right = Rectangle.Create(itemWindow, "border_right")
    border_right:SetSizeAutoRel(Vector2(0, 1))
    border_right:SetWidth(InventoryUIStyle.border_size)
    border_right:SetPosition(Vector2(itemWindow:GetWidth() - InventoryUIStyle.border_size, 0))

    local border_bottom = Rectangle.Create(itemWindow, "border_bottom")
    border_bottom:SetSizeAutoRel(Vector2(1, 0))
    border_bottom:SetHeight(InventoryUIStyle.border_size)
    border_bottom:SetPosition(Vector2(0, itemWindow:GetHeight() - InventoryUIStyle.border_size))

    local border_left = Rectangle.Create(itemWindow, "border_left")
    border_left:SetSizeAutoRel(Vector2(0, 1))
    border_left:SetWidth(InventoryUIStyle.border_size)
    border_left:SetPosition(Vector2(0, 0))

    self:SetItemWindowBorderColor(itemWindow, colors.border)

    equip_outer:Hide()

    button:SetDataNumber("stack_index", index)
    button:SetDataString("stack_category", cat)
    button:SetDataBool("dropping", false)
    button:SetDataNumber("drop_amount", 0)
    itemWindow:Hide()

    button:Subscribe("Press", self, self.LeftClickItemButton)
    button:Subscribe("RightPress", self, self.RightClickItemButton)
    button:Subscribe("HoverEnter", self, self.HoverEnterButton)
    button:Subscribe("HoverLeave", self, self.HoverLeaveButton)

    button:BringToFront()

end

function cInventoryUI:HoverEnterButton(button)
    -- Called when the mouse hovers over a button
    self.hovered_button = button
end

function cInventoryUI:HoverLeaveButton(button)
    -- Called when the mouse stops hovering over a button
    self.hovered_button = nil
end

function cInventoryUI:RightClickItemButton(button)
    -- Called when a button is right clicked
    local cat = button:GetDataString("stack_category")
    local index = button:GetDataNumber("stack_index")

    if not Inventory.contents[cat][index] then
        error("cInventoryUI:RightClickItemButton failed: no stack was found")
    end

    local amount = Inventory.contents[cat][index]:GetAmount()
    button:SetDataNumber("drop_amount", amount) -- Reset dropping amount when they right click it
    self:ToggleDroppingItemButton(button)

    self.dropping_counter = button:GetDataBool("dropping") and self.dropping_counter + 1 or self.dropping_counter - 1
        
    -- Add or remove from self.dropping_items depending on if they are dropping it or not
    self.dropping_items[cat .. tostring(index)] = button:GetDataBool("dropping") and {cat = cat, index = index, amount = amount} or nil

end

function cInventoryUI:ToggleDroppingItemButton(button)

    button:SetDataBool("dropping", not button:GetDataBool("dropping"))
    local colors = button:GetDataBool("dropping") and InventoryUIStyle.colors.dropping or InventoryUIStyle.colors.default

    local cat = button:GetDataString("stack_category")
    local index = button:GetDataNumber("stack_index")
    local amount = Inventory.contents[cat][index]:GetAmount()
    button:SetDataNumber("drop_amount", amount) -- Reset dropping amount when they right click it

    button:SetTextColor(colors.text)
    button:SetTextNormalColor(colors.text)
    button:SetTextHoveredColor(colors.text_hover)
    button:SetTextPressedColor(colors.text_hover)
    button:GetParent():FindChildByName("button_bg", true):SetColor(colors.background)
    self:SetItemWindowBorderColor(button:GetParent(), colors.border)
    button:SetText(self:GetItemNameWithAmount(Inventory.contents[cat][index], index))

end

function cInventoryUI:MouseScroll(args)
    if self.dropping_counter == 0 then return end -- Not dropping any items
    if not self.hovered_button then return end -- Not hovering over a button
    if not self.hovered_button:GetDataBool("dropping") then return end -- Not scrolling on an item they are dropping

    local cat = self.hovered_button:GetDataString("stack_category")
    local index = self.hovered_button:GetDataNumber("stack_index")

    local change = args.delta < 0 and -1 or 1 -- Normalizing the change
    local new_drop_amount = self.hovered_button:GetDataNumber("drop_amount") + change

    -- Bounds on dropping the item
    if new_drop_amount == 0 then
        new_drop_amount = Inventory.contents[cat][index]:GetAmount()
    elseif new_drop_amount > Inventory.contents[cat][index]:GetAmount() then
        new_drop_amount = 1
    end

    self.hovered_button:SetDataNumber("drop_amount", new_drop_amount)
    self.hovered_button:SetText(self:GetItemNameWithAmount(Inventory.contents[cat][index], index))

    -- Update dropping amount
    self.dropping_items[cat .. tostring(index)].amount = new_drop_amount

end

function cInventoryUI:SetItemWindowBorderColor(itemWindow, border_color)
    itemWindow:FindChildByName("border_top", true):SetColor(border_color)
    itemWindow:FindChildByName("border_right", true):SetColor(border_color)
    itemWindow:FindChildByName("border_bottom", true):SetColor(border_color)
    itemWindow:FindChildByName("border_left", true):SetColor(border_color)
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

function cInventoryUI:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

-- Called when the inventory is closed
function cInventoryUI:InventoryClosed()

    -- If we're trying to drop something
    if self.dropping_counter > 0 then
        self.dropping_counter = 0

        -- If there are actually items to drop
        if count_table(self.dropping_items) > 0 then

            -- Reset UI
            for _, data in pairs(self.dropping_items) do
                self:ToggleDroppingItemButton(
                    self.window:FindChildByName("itemwindow_"..data.cat..tostring(data.index), true):FindChildByName("button", true))
            end

            -- Send to server to drop
            Network:Send("Inventory/Drop" .. self.steam_id, {stacks = self.dropping_items})

        end

        self.dropping_items = {}
        -- loop through all items, find those that were marked for dropping (with amounts)
    end

end

function cInventoryUI:ToggleVisible()

    if self.window:GetVisible() then -- Close inventory
        self.window:Hide()
        Events:Unsubscribe(self.LPI)
        self.LPI = nil
        self:InventoryClosed()
    else -- Open inventory
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

