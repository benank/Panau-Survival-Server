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

    self.lootbox_title = ClientInventory.ui:CreateCategoryTitle("loot", false, self.lootbox_title_window)
    self.lootbox_title_shadow = ClientInventory.ui:CreateCategoryTitle("loot", true, self.lootbox_title_window)
    
    LocalPlayer:SetValue("LootOpen", false)

    Events:Subscribe(var("KeyUp"):get(), self, self.KeyUp)
    Network:Subscribe(var("Inventory/LootboxOpen"):get(), self, self.LootboxOpen)
    Network:Subscribe(var("Inventory/LootboxSync"):get(), self, self.LootboxSync)
    
end

function cLootboxUI:PressDismountStashButton(btn)

    local current_box = LootManager.current_box

    if not current_box.stash then return end

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

-- Updates a lootbox title (stash) and hides/shows it based on current box
function cLootboxUI:UpdateLootboxTitle()

    local current_box = LootManager.current_box

    if current_box.stash then

        self.lootbox_title_window:Show()

        local is_owner = current_box.stash.owner_id == tostring(LocalPlayer:GetSteamId())

        local text = string.format("%s (%d/%d)", 
            is_owner and current_box.stash.name or "Stash", current_box.stash.num_items, current_box.stash.capacity)

        self.lootbox_title:SetText(text)
        self.lootbox_title:SetTextSize(ClientInventory.ui.inv_dimensions.text_size)
        self.lootbox_title:SetPosition(self:GetLootboxTitlePosition(current_box))

        self.lootbox_title_shadow:SetText(text)
        self.lootbox_title_shadow:SetTextSize(ClientInventory.ui.inv_dimensions.text_size)
        self.lootbox_title_shadow:SetPosition(self:GetLootboxTitlePosition(current_box) + Vector2(1.5,1.5))

        self.stash_dismount_button:SetPosition(
            self.lootbox_title:GetPosition()
            - Vector2(self.lootbox_title:GetSize().x + 20, 14))
        self.stash_dismount_button:SetTextSize(ClientInventory.ui.inv_dimensions.text_size)

        if is_owner then
            self.stash_dismount_button:Show()
        else
            self.stash_dismount_button:Hide()
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
    self:Update({action = "full", stash = args.stash})

end

function cLootboxUI:LootboxOpen(args)

    if not args.contents then return end
    if not LootManager.current_box then return end

    LootManager:RecreateContents(args.contents)

    self:Update({action = "full", stash = args.stash})

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
        if args.stash and #LootManager.current_box.contents == 0 then
            ClientInventory.ui:PopulateEntry({index = 1, loot = true, empty = true, stash = args.stash, window = self.window})
        end

    elseif args.action == "update" or args.action == "remove" then
        ClientInventory.ui:PopulateEntry({index = args.index, loot = true, stash = args.stash, window = self.window})
    end

    if not self.window:GetVisible() or (#LootManager.current_box.contents == 0 and not args.stash) then
        --self:RepositionWindow(args.stash and args.stash.capacity or nil)
        self:RepositionWindow()
        self:ToggleVisible()
    end

    self:UpdateLootboxTitle()

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
            Network:Send("Inventory/CloseBox" .. tostring(LootManager.current_box.uid)) -- Send event to close box
        end
    else

        self.window:Show()
        self.lootbox_title_window:Show()
        Mouse:SetPosition(Render.Size / 2)
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
        elseif IsValid(LootManager.current_looking_box) and not self.window:GetVisible() then
            LootManager.current_box = LootManager.current_looking_box
            Network:Send("Inventory/TryOpenBox" .. tostring(LootManager.current_looking_box.uid))
        end
        self.lootbox_title_window:SendToBack()

    end

end