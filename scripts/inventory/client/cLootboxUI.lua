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
    
    LocalPlayer:SetValue("LootOpen", false)

    Events:Subscribe("KeyUp", self, self.KeyUp)
    Network:Subscribe("Inventory/LootboxOpen", self, self.LootboxOpen)
    Network:Subscribe("Inventory/LootboxSync", self, self.LootboxSync)
    
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
    if not self.window_created then return end

    if args.action == "full" then

        for i = 1, Inventory.config.max_slots_per_category do
            self.itemWindows[i]:Hide()
        end

        for i = 1, #LootManager.current_box.contents do
            ClientInventory.ui:PopulateEntry({index = i, loot = true, window = self.window})
        end

        self:RepositionWindow()

    elseif args.action == "update" or args.action == "remove" then
        ClientInventory.ui:PopulateEntry({index = args.index, loot = true, window = self.window})
        self:RepositionWindow()
    end

end

-- Adjusts y position of window to center it depending on how many items are in it
function cLootboxUI:RepositionWindow()
    local num_items = #LootManager.current_box.contents
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
    self:ToggleVisible() -- If they do anything that's not a blocked action, like move, close the UI

end

function cLootboxUI:ToggleVisible()

    if self.window:GetVisible() then
        self.window:Hide()
        Events:Unsubscribe(self.LPI)
        self.LPI = nil
        if LootManager.current_box then
            Network:Send("Inventory/CloseBox" .. tostring(LootManager.current_box.uid)) -- Send event to close box
        end
    else
        self.window:Show()
        Mouse:SetPosition(Render.Size / 2)
        self:RepositionWindow()
        self.LPI = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    end

    Mouse:SetVisible(self.window:GetVisible())
    LocalPlayer:SetValue("LootOpen", self.window:GetVisible())

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
