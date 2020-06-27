class 'cLootboxUI'

function cLootboxUI:__init()

    self.open_key = 'E'

    self.contents = {}

    self.window = BaseWindow.Create("Loot")
    self.window:SetSize(Vector2(ClientInventory.ui.inv_dimensions.button_size.x, Render.Size.y))
    self.window:SetPosition(Render.Size / 2 - self.window:GetSize() / 2)
    self.window:Hide()
    self.window:Focus()
    self.window:SetBackgroundVisible(false)

    self.window_created = false
    self:CreateWindow()

    self.lootbox_title_window = BaseWindow.Create("LootboxTitle")
    self.lootbox_title_window:SetSize(Render.Size)
    self.lootbox_title_window:SetPosition(Vector2(0,0))
    self.lootbox_title_window:SetBackgroundVisible(false)
    self.lootbox_title_window:SendToBack()
    self.lootbox_title_window:Hide()

    self.stash_dismount_button = Button.Create(self.lootbox_title_window)
    self.stash_dismount_button:SetSize(self.itemWindows[1]:GetSize())
    self.stash_dismount_button:SetText("DISMOUNT")
    self.stash_dismount_button:SetTextColor(Color.Red)
    self.stash_dismount_button:SetTextNormalColor(Color.Red)
    self.stash_dismount_button:SetTextHoveredColor(Color.Red)
    self.stash_dismount_button:SetTextPressedColor(Color.Red)
    self.stash_dismount_button:SetTextDisabledColor(Color.Red)
    self.stash_dismount_button:Hide()
    self.stash_dismount_button:Subscribe("Press", self, self.PressDismountStashButton)

    self:CreateAccessModeMenu()

    self.lootbox_title = ClientInventory.ui:CreateCategoryTitle("loot", false, self.lootbox_title_window)
    self.lootbox_title_shadow = ClientInventory.ui:CreateCategoryTitle("loot", true, self.lootbox_title_window)
    
    LocalPlayer:SetValue("LootOpen", false)

    Events:Subscribe(var("KeyUp"):get(), self, self.KeyUp)
    self.window:Subscribe(var("PostRender"):get(), self, self.WindowRender)
    Network:Subscribe(var("Inventory/LootboxOpen"):get(), self, self.LootboxOpen)
    Network:Subscribe(var("Inventory/LootboxSync"):get(), self, self.LootboxSync)
    
end

function cLootboxUI:CreateAccessModeMenu()

    self.access_mode_menu = Rectangle.Create(self.lootbox_title_window)
    self.access_mode_menu:SetColor(Color(0, 0, 0, 150))
    self.access_mode_menu:SetSize(Vector2(self.stash_dismount_button:GetWidth() * 0.5, self.stash_dismount_button:GetHeight() * 3))
    self.access_mode_menu:Subscribe("PostRender", self, self.AccessModeRender)

    local button_names = 
    {
        "Everyone",
        "Friends",
        "Only Me"
    }

    for i = 1, 3 do
        local button = Button.Create(self.access_mode_menu)
        button:SetText(button_names[i])
        button:SetSizeRel(Vector2(1, 1/3))
        button:SetTextSize(button:GetHeight() / 2)
        button:SetDock(GwenPosition.Top)
        button:SetTextPadding(Vector2(button:GetWidth() * 0.25, 0), Vector2.Zero)
        button:SetBackgroundVisible(false)
        button:SetDataNumber("access_mode", i)
        button:Subscribe("Press", self, self.PressStashAccessModeButton)
    end

end

function cLootboxUI:PressStashAccessModeButton(btn)

    if not LootManager.current_box then return end

    local new_access_mode = btn:GetDataNumber("access_mode")

    if new_access_mode == LootManager.current_box.stash.access_mode then return end

    Network:Send("Stashes/UpdateStashAccessMode", {
        mode = btn:GetDataNumber("access_mode")
    })

end

function cLootboxUI:AccessModeRender(args)

    local pos = self.lootbox_title_window:GetPosition() + self.access_mode_menu:GetPosition()

    local t = Transform2():Translate(pos)
    Render:SetTransform(t)

    local size = self.access_mode_menu:GetSize()

    Render:DrawLine(Vector2.Zero, Vector2(0, size.y), Color.White)
    Render:DrawLine(Vector2.Zero, Vector2(size.x, 0), Color.White)
    Render:DrawLine(size, size + Vector2(-size.x, 0), Color.White)
    Render:DrawLine(size, size + Vector2(0, -size.y), Color.White)
    
    Render:DrawLine(Vector2(0, size.y * 1 / 3), Vector2(0, size.y * 1 / 3) + Vector2(size.x, 0), Color.White)
    Render:DrawLine(Vector2(0, size.y * 2 / 3), Vector2(0, size.y * 2 / 3) + Vector2(size.x, 0), Color.White)

    local access_mode = LootManager.current_box.stash.access_mode
    local circle_size =  size.y / 3 * 0.2
    Render:FillCircle(
        Vector2(size.y / 6, size.y / 6 + size.y * (access_mode - 1) / 3) - Vector2(circle_size, circle_size) / 2, 
        circle_size, 
        Color.Red)

    Render:ResetTransform()

end

function cLootboxUI:WindowRender()

    for index, stack in pairs(LootManager.current_box.contents) do

        local itemWindow = self.itemWindows[index]
        InventoryUIStyle:RenderItemWindow(itemWindow, stack, self.window)

    end

end

function cLootboxUI:PressDismountStashButton(btn)

    local current_box = LootManager.current_box

    if not current_box.stash then return end

    if current_box.tier == Lootbox.Types.Workbench then
        Network:Send("Workbenches/StartCombine", {
            id = current_box.stash.id
        })
        return
    end

    local is_owner = current_box.stash.owner_id == tostring(LocalPlayer:GetSteamId())

    if not is_owner then return end

    Network:Send("Stashes/Dismount", {
        id = current_box.stash.id
    })

end

function cLootboxUI:GetLootboxTitlePosition(box)

    return self.window:GetPosition() + Vector2(
        0,
        -ClientInventory.ui.inv_dimensions.button_size.y
        -ClientInventory.ui.inv_dimensions.padding + self.lootbox_title:GetSize().y
    )

end

function cLootboxUI:SetLootboxTitle(name, num_items, capacity)

    local text = string.format("%s (%s/%d)", name, tostring(num_items), tostring(capacity))

    self.lootbox_title:SetText(text)
    self.lootbox_title:SetTextSize(ClientInventory.ui.inv_dimensions.text_size)
    self.lootbox_title:SetPosition(self:GetLootboxTitlePosition(current_box))

    self.lootbox_title_shadow:SetText(text)
    self.lootbox_title_shadow:SetTextSize(ClientInventory.ui.inv_dimensions.text_size)
    self.lootbox_title_shadow:SetPosition(self:GetLootboxTitlePosition(current_box) + Vector2(1.5,1.5))

end

-- Updates a lootbox title (stash) and hides/shows it based on current box
function cLootboxUI:UpdateLootboxTitle(locked)

    local current_box = LootManager.current_box

    if current_box.stash then

        self.lootbox_title_window:Show()

        local is_owner = current_box.stash.owner_id == tostring(LocalPlayer:GetSteamId())

        local name = Lootbox.Stashes[current_box.tier].name

        if current_box.stash and current_box.stash.name and is_owner then
            name = current_box.stash.name
        end 

        self:SetLootboxTitle(name, locked and "?" or current_box.stash.num_items, current_box.stash.capacity)

        self.stash_dismount_button:SetPosition(
            self.lootbox_title:GetPosition()
            - Vector2(self.lootbox_title:GetSize().x + 20, 14))
        self.stash_dismount_button:SetTextSize(ClientInventory.ui.inv_dimensions.text_size)

        self.access_mode_menu:SetPosition(self.stash_dismount_button:GetPosition() + 
            Vector2(0, self.stash_dismount_button:GetHeight() * 2))

        if is_owner then
            self.stash_dismount_button:Show()
            self.stash_dismount_button:SetText("DISMOUNT")
            self.stash_dismount_button:SetTextColor(Color.Red)
            self.stash_dismount_button:SetTextNormalColor(Color.Red)
            self.stash_dismount_button:SetTextHoveredColor(Color.Red)
            self.stash_dismount_button:SetTextPressedColor(Color.Red)
            self.stash_dismount_button:SetTextDisabledColor(Color.Red)

            if current_box.stash.can_change_access then
                self.access_mode_menu:Show()
            else
                self.access_mode_menu:Hide()
            end
        else
            if current_box.tier == Lootbox.Types.Workbench and count_table(current_box.contents) > 0 then
                self.stash_dismount_button:Show()
                self.stash_dismount_button:SetText("COMBINE")
                self.stash_dismount_button:SetTextColor(Color(0, 230, 0))
                self.stash_dismount_button:SetTextNormalColor(Color(0, 230, 0))
                self.stash_dismount_button:SetTextHoveredColor(Color(0, 230, 0))
                self.stash_dismount_button:SetTextPressedColor(Color(0, 230, 0))
                self.stash_dismount_button:SetTextDisabledColor(Color(0, 230, 0))
            else
                self.stash_dismount_button:Hide()
            end
            self.access_mode_menu:Hide()
        end

        local is_full = current_box.stash.num_items == current_box.stash.capacity
        self.lootbox_title:SetTextColor(
            is_full and InventoryUIStyle.category_title_colors.Full or InventoryUIStyle.category_title_colors.Normal)

    else

        self.lootbox_title_window:Hide()

    end


end

function cLootboxUI:ClickItemButton(btn)

    local index = btn:GetDataNumber("stack_index")
    if not index or not LootManager.current_box.contents[index] then return end

    Network:Send("Inventory/TakeLootStack"..tostring(LootManager.current_box.uid), {index = index})

end

function cLootboxUI:LootboxSync(args)

    if not args.contents then return end
    if not LootManager.current_box then return end

    LootManager:RecreateContents(args.contents)
    LootManager.current_box.stash = args.stash

    LootManager.loot[LootManager.current_box.cell.x][LootManager.current_box.cell.y][LootManager.current_box.uid] = LootManager.current_box

    self:Update({action = "full", stash = args.stash})

end

function cLootboxUI:LootboxOpen(args)

    if not args.contents then return end
    if not LootManager.current_box then return end

    LootManager:RecreateContents(args.contents)
    LootManager.current_box.stash = args.stash

    LootManager.loot[LootManager.current_box.cell.x][LootManager.current_box.cell.y][LootManager.current_box.uid] = LootManager.current_box

    self:Update({action = "full", stash = args.stash, locked = args.locked})

end

function cLootboxUI:WindowClosed()
    self:ToggleVisible()
end


function cLootboxUI:Update(args)

    if not LootManager.current_box then return end
    if not self.window_created then return end

    LootManager.current_box.stash = args.stash

    if args.action == "full" then

        for i = 1, Inventory.config.max_slots_per_category do
            self.itemWindows[i]:Hide()
        end

        for i = 1, #LootManager.current_box.contents do
            ClientInventory.ui:PopulateEntry({index = i, loot = true, stash = args.stash, window = self.window})
        end
        --[[if args.stash then
            for i = #LootManager.current_box.contents + 1, args.stash.capacity do
                ClientInventory.ui:PopulateEntry({index = i, loot = true, empty = true, stash = args.stash, window = self.window})
            end
            self:RepositionWindow(args.stash.capacity)
        end]]

        if args.locked then
            ClientInventory.ui:PopulateEntry({index = 1, loot = true, locked = true, window = self.window})
        elseif args.stash and #LootManager.current_box.contents == 0 then
            ClientInventory.ui:PopulateEntry({index = 1, loot = true, empty = true, stash = args.stash, window = self.window})
        elseif not args.stash and #LootManager.current_box.contents == 0 then 
            ClientInventory.ui:PopulateEntry({index = 1, loot = true, empty = true, window = self.window})
        end

    elseif args.action == "update" or args.action == "remove" then
        ClientInventory.ui:PopulateEntry({index = args.index, loot = true, stash = args.stash, window = self.window})
    end

    if not self.window:GetVisible() --[[or (#LootManager.current_box.contents == 0 and not args.stash and not LocalPlayer:GetValue("InSafezone"))]] then
        --self:RepositionWindow(args.stash and args.stash.capacity or nil)
        self:RepositionWindow()
        self:ToggleVisible()
    end

    self:UpdateLootboxTitle(args.locked)

end

-- Adjusts y position of window to center it depending on how many items are in it
function cLootboxUI:RepositionWindow(capacity)
    local num_items = capacity or #LootManager.current_box.contents
    local items_height = num_items * self.itemWindows[1]:GetHeight() + num_items * ClientInventory.ui.inv_dimensions.padding
    local center = Render.Size.y / 2
    self.window:SetPosition(Vector2(self.window:GetPosition().x, center - items_height / 2))
end

function cLootboxUI:CreateWindow()

    self.itemWindows = {}

    -- Create entries for each item
    for i = 1, Inventory.config.max_slots_per_category do -- Pre-create all itemWindows and utilize as needed
        local itemWindow = ClientInventory.ui:CreateItemWindow("loot", i, self.window)
        self.itemWindows[i] = itemWindow
    end

    self.window_created = true

end

function cLootboxUI:LocalPlayerInput(args)

    if ClientInventory.ui.blockedActions[args.input] then return false end

end

function cLootboxUI:ToggleVisible()

    if self.window:GetVisible() then
        self.window:Hide()
        self.lootbox_title_window:Hide()
        Events:Unsubscribe(self.LPI)
        self.LPI = nil
        if LootManager.current_box then
            Network:Send(var("Inventory/CloseBox" .. tostring(LootManager.current_box.uid)):get()) -- Send event to close box
        end
    else

        self.window:Show()
        self.lootbox_title_window:Show()
        Mouse:SetPosition(Render.Size / 2)
        self.window:BringToFront()
        --self:RepositionWindow()
        self.LPI = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    end

    if not ClientInventory.ui.window:GetVisible() then
        Mouse:SetVisible(self.window:GetVisible())
    end

    LocalPlayer:SetValue("LootOpen", self.window:GetVisible())

end

function cLootboxUI:KeyUp(args)

    if args.key == string.byte(self.open_key) then

        if self.window:GetVisible() then
            self:ToggleVisible()
        elseif IsValid(LootManager.current_looking_box) 
        and not self.window:GetVisible()
        and LootManager.current_looking_box.position:Distance(LocalPlayer:GetPosition()) < 10 then
            LootManager.current_box = LootManager.current_looking_box
            self:LootboxOpen(LootManager.current_box)
            Network:Send("Inventory/TryOpenBox" .. tostring(LootManager.current_looking_box.uid))
        end
        self.lootbox_title_window:SendToBack()

    end

end