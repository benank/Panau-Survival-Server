class 'sInventory'

function sInventory:__init(player)

    player:SetValue("InventoryOperationBlock", 0)
    player:SetValue("CurrentLootbox", nil)

    self.player = player
    self.contents = {} -- Contents of the player's inventory
    self.slots = {} -- Number of slots that the player has for each inventory category (use self:GetSlots(cat))
    self.initial_sync = false
    self.steamID = tostring(player:GetSteamId().id)
    self.operation_block = 0 -- Increment/decrement this to disable inventory operations

    self.backpack_slots = {}
    
    self.events = {}
    self.network_events = {}

    self.invsee_source = nil
    self.invsee = {}

    -- Save inventory to DB interval
    self.update_timer = Timer.SetInterval(1000 * 60, function()
        self:UpdateDB()
    end)

    table.insert(self.events, Events:Subscribe("Inventory.AddStack-" .. self.steamID, self, self.AddStackRemote))
    table.insert(self.events, Events:Subscribe("Inventory.AddItem-" .. self.steamID, self, self.AddItemRemote))
    table.insert(self.events, Events:Subscribe("Inventory.RemoveStack-" .. self.steamID, self, self.RemoveStackRemote))
    table.insert(self.events, Events:Subscribe("Inventory.RemoveItem-" .. self.steamID, self, self.RemoveItemRemote))
    table.insert(self.events, Events:Subscribe("Inventory.ModifyStack-" .. self.steamID, self, self.ModifyStackRemote))
    table.insert(self.events, Events:Subscribe("Inventory.ModifyDurability-" .. self.steamID, self, self.ModifyDurabilityRemote))
    table.insert(self.events, Events:Subscribe("Inventory.ModifyItemCustomData-" .. self.steamID, self, self.ModifyItemCustomDataRemote))
    table.insert(self.events, Events:Subscribe("Inventory.OperationBlock-" .. self.steamID, self, self.OperationBlockRemote))
    table.insert(self.events, Events:Subscribe("Inventory.SetItemEquipped-" .. self.steamID, self, self.SetItemEquippedRemote))

    table.insert(self.events, Events:Subscribe("Inventory.ToggleBackpackEquipped-" .. self.steamID, self, self.ToggleBackpackEquipped))

    table.insert(self.events, Events:Subscribe("PlayerKilled", self, self.PlayerKilled))
    table.insert(self.events, Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated))

    table.insert(self.network_events, Network:Subscribe("Inventory/Shift" .. self.steamID, self, self.ShiftStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/ToggleEquipped" .. self.steamID, self, self.ToggleEquipped))
    table.insert(self.network_events, Network:Subscribe("Inventory/Use" .. self.steamID, self, self.UseItem))
    table.insert(self.network_events, Network:Subscribe("Inventory/Drop" .. self.steamID, self, self.DropStacks))
    table.insert(self.network_events, Network:Subscribe("Inventory/Split" .. self.steamID, self, self.SplitStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/Swap" .. self.steamID, self, self.SwapStack))

    self:Load()

end

function sInventory:Load()

    if self.initial_sync then return end

    -- Initialize subtables of categories
    for index, cat_info in pairs(Inventory.config.categories) do
        self.contents[cat_info.name] = {}
        self.slots[cat_info.name] = {default = cat_info.slots, level = 0, backpack = 0}
    end

    if self.player:GetValue("Perks") then
        self:UpdateNumSlotsBasedOnPerks()
    end

	local query = SQL:Query("SELECT contents FROM inventory WHERE steamID = (?) LIMIT 1")
    query:Bind(1, self.steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        
        self:Deserialize(result[1].contents)

        -- If there is non-persistent custom data, remove it (like C4 id)
        for cat, data in pairs(self.contents) do
            for index, stack in pairs(data) do
                for item_index, item in pairs(stack.contents) do
                    if Items_indexed[item.name].non_persistent_custom_data then
                        item.custom_data = {}
                    end
                end
            end
        end
        
    else
        
		local command = SQL:Command("INSERT INTO inventory (steamID, contents) VALUES (?, ?)")
		command:Bind(1, self.steamID)
		command:Bind(2, "")
        command:Execute()
        
        -- Load default inventory
        for k,v in pairs(GenerateDefaultInventory()) do
            self:AddStack({stack = v})
        end

        self:UpdateDB()
        
	end

    self:Sync({sync_full = true})

    self.initial_sync = true

end

function sInventory:PlayerPerksUpdated(args)
    if args.player ~= self.player then return end

    local old_slots = deepcopy(self.slots)
    self:UpdateNumSlotsBasedOnPerks()
    self:Sync({sync_slots = true})

    for cat_name, slot_data in pairs(self.slots) do
        if slot_data.level ~= old_slots[cat_name].level then
            Chat:Send(self.player, string.format("Inventory space increased! You now have %d %s slots.", self:GetNumSlotsInCategory(cat_name), cat_name), Color(0, 255, 255))
        end
    end

end

-- Updates the number of slots in each category based on level
function sInventory:UpdateNumSlotsBasedOnPerks()

    local perks = self.player:GetValue("Perks")

    for cat_name, slot_data in pairs(self.slots) do
        self.slots[cat_name].level = GetNumSlotsInCategoryFromPerks(cat_name, perks.unlocked_perks)
    end

end

function sInventory:PlayerKilled(args)

    if not IsValid(args.player) then return end
    if args.player ~= self.player then return end

    -- Player died, so spawn dropbox
    local level = args.player:GetValue("Exp").level

    local sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()

    -- Within neutralzone, don't drop items
    if args.player:GetPosition():Distance(sz_config.neutralzone.position) < sz_config.neutralzone.radius then return end

    if args.player:GetValue("SecondLifeEquipped") then return end

    local num_slots_to_drop = GetNumSlotsDroppedOnDeath(level)

    if num_slots_to_drop == 0 then return end

    local stacks_to_drop = {}
    local categories = {"Weapons", "Explosives", "Supplies", "Survival"}

    while self:GetNumUsedSlots() > 0 and num_slots_to_drop > 0 do

        local cat = categories[math.random(#categories)]

        while count_table(self.contents[cat]) == 0 do
            cat = categories[math.random(#categories)]
        end

        local index_to_remove = math.random(#self.contents[cat])
        local stack = table.remove(self.contents[cat], index_to_remove)
        
        self:CheckIfStackHasOneEquippedThenUnequip(stack)

        table.insert(stacks_to_drop, stack)

        num_slots_to_drop = num_slots_to_drop - 1

    end

    -- If they overflowed, drop the items
    if #stacks_to_drop > 0 then

        -- Send the player a chat message
        local chat_msg = "Death drop: "
        for index, stack in pairs(stacks_to_drop) do
            chat_msg = chat_msg .. string.format("%s (%s)", tostring(stack:GetProperty("name")), tostring(stack:GetAmount()))
            if index < #stacks_to_drop then
                chat_msg = chat_msg .. ", "
            end
        end

        Chat:Send(self.player, chat_msg, Color.Red)

        Events:Fire("Discord", {
            channel = "Inventory",
            content = string.format("%s [%s] death drop: %s", self.player:GetName(), tostring(self.player:GetSteamId()), chat_msg)
        })

        self:SpawnDropbox(stacks_to_drop, true)

        -- Full sync in case they dropped from multiple categories
        self:Sync({sync_full = true})
    end
    

end

function sInventory:GetNumUsedSlots()
    local slots_used = 0
    for cat_name, data in pairs(self.contents) do
        slots_used = slots_used + count_table(data)
    end
    return slots_used
end

function sInventory:ToggleBackpackEquipped(args)

    self.backpack_equipped = args.equipped

    if not args.equipped then
        -- Unequipped backpack
        -- Delay in case they are equipping another backpack at the same time
        for cat, slots_to_add in pairs(args.slots) do
            self.slots[cat].backpack = self.slots[cat].backpack - slots_to_add
        end

        if not args.no_sync then
            self:Sync({sync_slots = true})
        end

        self.backpack_slots[args.name] = nil

    else

        -- If they already have it equipped, remove existing slots
        if self.backpack_slots[args.name] then
            for cat, slots_to_add in pairs(self.backpack_slots[args.name]) do
                self.slots[cat].backpack = self.slots[cat].backpack - slots_to_add
            end
        end

        self.backpack_slots[args.name] = args.slots

        for cat, slots_to_add in pairs(args.slots) do
            self.slots[cat].backpack = self.slots[cat].backpack + slots_to_add
        end

        self:Sync({sync_slots = true})

    end

end

function sInventory:ShiftStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index or not args.cat then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end

    self.contents[args.cat][args.index]:Shift()
    self:Sync({index = args.index, stack = self.contents[args.cat][args.index], sync_stack = true})

end

function sInventory:CanUseOrEquipItem(item)

    if not ITEM_UNLOCKS_ENABLED then return true end

    local perk_required = Item_Unlocks[item.name]
    local name = item.name

    if item.name == "EVAC" and count_table(item.custom_data) > 0 then
        name = "Secret EVAC"
        perk_required = Item_Unlocks[name]
    end

    if perk_required then

        local perks = self.player:GetValue("Perks")

        if not perks then return false end

        if perks.unlocked_perks[perk_required] then
            return true 
        else
            local perks_by_id = SharedObject.GetByName("ExpPerksById"):GetValue("Perks")
            Chat:Send(self.player, string.format("%s requires perk #%d. Hit F2 to open the perks menu.", 
            name, perks_by_id[perk_required].position), Color.Red)
            return false
        end

    end

    return true

end

function sInventory:ToggleEquipped(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index or not args.cat then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end
    if not self.contents[args.cat][args.index]:GetProperty("can_equip") then return end

    if not self:CanUseOrEquipItem(self.contents[args.cat][args.index].contents[1]) then return end

    local uid = self.contents[args.cat][args.index].uid
    local item_uid = self.contents[args.cat][args.index].contents[1].uid

    -- check for items of same equip type and unequip them
    local equip_type = self.contents[args.cat][args.index]:GetProperty("equip_type")

    for cat, _ in pairs(self.contents) do
        for stack_index, stack in pairs(self.contents[cat]) do
            for item_index, item in pairs(stack.contents) do

                if item.equipped and item.equip_type == equip_type
                and item.uid ~= item_uid then

                    item.equipped = false
                    Events:Fire("Inventory/ToggleEquipped", 
                        {index = stack_index, no_sync = true, player = self.player, item = item:Copy():GetSyncObject()})

                    --Timer.Sleep(1)
                end

            end
        end
    end
    
    local index = self:FindIndexFromUID(args.cat, uid)

    if not self.contents[args.cat]
    or not self.contents[args.cat][index]
    or not self.contents[args.cat][index].contents[1] then
        return
    end

    -- Equip/unequip the item
    self.contents[args.cat][index].contents[1].equipped = not self.contents[args.cat][index].contents[1].equipped

    Events:Fire("Inventory/ToggleEquipped", 
        {player = self.player, index = index, item = self.contents[args.cat][index].contents[1]:Copy():GetSyncObject()})

    self:CheckForOverflow()

    -- Sync it
    self:Sync({sync_full = true})

end

function sInventory:SpawnDropbox(contents, is_death_drop)

    -- Request ground data
    Network:Send(self.player, "Inventory/GetGroundData")

    -- Remove non persistent custom data, if any
    for index, stack in pairs(contents) do
        for item_index, item in pairs(stack.contents) do
            if Items_indexed[item.name].non_persistent_custom_data then
                 item.custom_data = {}
                 stack.contents[item_index] = item
            end
        end
    end

    if not self.dropping_contents then
        self.dropping_contents = contents
    else
        for _, stack in pairs(contents) do
            table.insert(self.dropping_contents, stack)
        end
    end

    if self.ground_data_sub then return end

    -- Receive ground data
    self.ground_data_sub = Network:Subscribe("Inventory/GroundData" .. self.steamID, function(args, player)
        if player ~= self.player then return end
        if not args.position or not args.angle then return end

        if self.last_dropbox and IsValid(self.last_dropbox) 
        and self.last_dropbox.position
        and count_table(self.last_dropbox.contents) > 0 
        and self.last_dropbox.position:Distance(args.position) < 0.1 then
            -- Add to existing dropbox
            for _, stack in pairs(self.dropping_contents) do
                self.last_dropbox:AddStack(stack)
            end

            return
        end

        self.last_dropbox = CreateLootbox({
            position = args.position,
            angle = args.angle,
            tier = Lootbox.Types.Dropbox,
            active = true,
            is_deathdrop = is_death_drop,
            contents = self.dropping_contents
        })
        self.last_dropbox:Sync()

        Network:Unsubscribe(self.ground_data_sub)
        self.ground_data_sub = nil

        self.dropping_contents = nil

        if is_death_drop then
            Events:Fire("Inventory/SetDeathDropPosition", {player = self.player, position = args.position})
        end

    end)

end

-- Checks for item overflow when a backpack is unequipped
function sInventory:CheckForOverflow()

    local stacks_to_drop = {}

    for cat, data in pairs(self.contents) do

        local max_slots = self:GetNumSlotsInCategory(cat)

        -- If there is an overflow
        while #self.contents[cat] > max_slots do

            local index_to_remove = math.random(#self.contents[cat])
            local stack = table.remove(self.contents[cat], index_to_remove)
            
            self:CheckIfStackHasOneEquippedThenUnequip(stack)

            table.insert(stacks_to_drop, stack)

        end

    end

    -- If they overflowed, drop the items
    if #stacks_to_drop > 0 then

        -- Send the player a chat message
        local chat_msg = "Inventory overflow! You dropped: "
        local items_dropped = ""
        for index, stack in pairs(stacks_to_drop) do
            items_dropped = items_dropped .. string.format("%s (%s)", tostring(stack:GetProperty("name")), tostring(stack:GetAmount()))
            if index < #stacks_to_drop then
                items_dropped = items_dropped .. ", "
            end
        end
        chat_msg = chat_msg .. items_dropped

        Events:Fire("Discord", {
            channel = "Inventory",
            content = string.format("%s [%s] inventory overflow and dropped: \n%s", 
                self.player:GetName(), tostring(self.player:GetSteamId()), items_dropped)
        })

        Chat:Send(self.player, chat_msg, Color.Red)

        self:SpawnDropbox(stacks_to_drop)

        -- Full sync in case they dropped from multiple categories
        self:Sync({sync_full = true})

        self:CheckForOverflow()
    end
    
end

function sInventory:UseItem(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index or not args.cat then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end
    if not self.contents[args.cat][args.index]:GetProperty("can_use") then return end

    if not self:CanUseOrEquipItem(self.contents[args.cat][args.index].contents[1]) then return end

    local copy = self.contents[args.cat][args.index].contents[1]:Copy()
    copy.amount = 1

    Events:Fire("Inventory/UseItem", 
        {player = self.player, item = copy:GetSyncObject(), cat = args.cat, index = args.index})

end

function sInventory:DropStacks(args, player)

    if player:InVehicle() then return end
    if not args.stacks then return end
    if count_table(args.stacks) == 0 then return end
    if count_table(args.stacks) > Lootbox.Max_Items_In_Dropbox then
        Chat:Send(player, string.format("You attempted to drop too many items at once! Please try again with less then %s items.",
            Lootbox.Max_Items_In_Dropbox), Color.Red)
        return
    end

    if player:GetValue("StuntingVehicle") then return end

    if not self:CanPlayerPerformOperations(player) then return end

    self.operation_block = self.operation_block + 1

    -- Store all uids in case the inventory contents shift and indices are no longer valid
    for index, data in pairs(args.stacks) do
        if data.cat and data.index and self.contents[data.cat] and self.contents[data.cat][data.index] then
            args.stacks[index].uid = self.contents[data.cat][data.index].uid
        end
    end

    -- Now remove items and add them to a lootbox (or stash)
    local contents = {}
    for _, data in pairs(args.stacks) do
        local stack = self:DropStack(data, player)
        if stack then
            table.insert(contents, stack)
        end
    end

    if count_table(contents) > 0 then
        self:SpawnDropbox(contents)
    end

    self.operation_block = self.operation_block - 1

end

function sInventory:FindIndexFromUID(cat, uid)
    
    for index, stack in pairs(self.contents[cat]) do
        if stack.uid == uid then
            return index
        end
    end

    return 0
end

function sInventory:DropStack(args, player)

    if player ~= self.player then return end

    args.index = self:FindIndexFromUID(args.cat, args.uid) -- Get new new index from UID

    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end
    if not args.amount or args.amount < 1 then return end

    if not tonumber(tostring(args.amount)) then
        args.amount = 1
    end

    local stack = self.contents[args.cat][args.index]

    if not stack then return end
    if args.amount > stack:GetAmount() then return end

    if player:InVehicle() then return end -- TODO drop in vehicle storage

    local dropping_in_stash = false
    local current_lootbox_data = player:GetValue("CurrentLootbox")
    local stash = nil

    if current_lootbox_data then

        local current_lootbox = LootCells.Loot[current_lootbox_data.cell.x][current_lootbox_data.cell.y][current_lootbox_data.uid]

        if current_lootbox and current_lootbox.active and current_lootbox.is_stash then

            stash = current_lootbox.stash
            
            if stash and stash:CanPlayerOpen(player) then
                dropping_in_stash = true
            end
        end
    end

    -- Not dropping the entire stack
    if args.amount < stack:GetAmount() then

        local split_stack = self.contents[args.cat][args.index]:Split(args.amount)
        self:Sync({index = args.index, stack = self.contents[args.cat][args.index], sync_stack = true})

        self:CheckIfStackHasOneEquippedThenUnequip(split_stack)

        if dropping_in_stash then
            -- Add to stash

            local return_stack = stash.lootbox:PlayerAddStack(split_stack, player)

            if return_stack then
                self:AddStack({stack = return_stack})
            end

        else

            Events:Fire("Discord", {
                channel = "Inventory",
                content = string.format("%s [%s] dropped stack: %s", self.player:GetName(), self.player:GetSteamId(), split_stack:ToString())
            })

            return split_stack

        end


    else -- Dropping the entire stack

        self:CheckIfStackHasOneEquippedThenUnequip(stack)

        self:RemoveStack({stack = stack:Copy(), index = args.index})

        if dropping_in_stash then

            local return_stack = stash.lootbox:PlayerAddStack(stack, player)

            if return_stack then
                self:AddStack({stack = return_stack})
            end

        else

            Events:Fire("Discord", {
                channel = "Inventory",
                content = string.format("%s [%s] dropped stack: %s", self.player:GetName(), self.player:GetSteamId(), stack:ToString())
            })

            return stack

        end

    end

end

function sInventory:SplitStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if player ~= self.player then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end
    if not args.amount or args.amount < 1 then return end

    if not tonumber(tostring(args.amount)) then
        args.amount = 1
    end

    if args.amount > self.contents[args.cat][args.index]:GetAmount() or args.amount < 1 then return end
    
    if self.contents[args.cat][args.index]:GetAmount() == args.amount then
        -- Trying to recombine a stack
        local stack = self.contents[args.cat][args.index]:Copy()
        self:RemoveStack({cat = args.cat, stack = stack:Copy(), index = args.index, amount = args.amount})
        
        self:AddStack({stack = stack})

    else

        local split_stack = self.contents[args.cat][args.index]:Split(args.amount)
        self:Sync({index = args.index, stack = self.contents[args.cat][args.index], sync_stack = true})

        local return_stack = self:AddStack({stack = split_stack, new_space = true})

        if return_stack then
            self:AddStack({stack = return_stack})
        end

    end


end

function sInventory:SwapStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.from or not args.to then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.from] or not self.contents[args.cat][args.to] then return end

    local stack = self.contents[args.cat][args.from]

    local stack_copy = self.contents[args.cat][args.from]:Copy()

    self.contents[args.cat][args.from] = self.contents[args.cat][args.to]
    self.contents[args.cat][args.to] = stack_copy

    self:Sync({cat = args.cat, sync_cat = true})

end

function sInventory:GetNumSlotsInCategory(cat)
    assert(self.slots[cat] ~= nil, "sInventory:GetNumSlotsInCategory failed: category was invalid (given: " .. cat .. ")")
    local total = 0

    for slot_type, amount in pairs(self.slots[cat]) do
        total = total + amount
    end

    return total
end

function sInventory:CanPlayerPerformOperations(player)

    -- eventually modify this so that admins can do stuff if they clone the inv
    return IsValid(player) and IsValid(self.player) and player == self.player and self.operation_block == 0
        and not player:GetValue("Loading") and player:GetEnabled() and player:GetValue("InventoryOperationBlock") == 0
        and player:GetHealth() > 0 and not player:GetValue("dead") and not self.invsee_source

end

function sInventory:OperationBlockRemote(args)

    if not IsValid(self.player) then return end

    if args.player ~= self.player then
        error(debug.traceback("sInventory:OperationBlockRemote failed: player does not match"))
        return
    end

    self.operation_block = self.operation_block + args.change

end

function sInventory:AddStackRemote(args)

    if args.player ~= self.player then
        error(debug.traceback("sInventory:AddStackRemote failed: player does not match"))
        return
    end

    args.stack = self:RecreateStack(args.stack)
    self:AddStack(args)

end

function sInventory:RemoveStackRemote(args)

    if args.player ~= self.player then
        error(debug.traceback("sInventory:RemoveStackRemote failed: player does not match"))
        return
    end

    self:RemoveStack({stack = self:RecreateStack(args.stack), index = args.index})

end

function sInventory:RemoveItemRemote(args)

    if args.player ~= self.player then
        error(debug.traceback("sInventory:RemoveItemRemote failed: player does not match"))
        return
    end

    self:RemoveItem({item = shItem(args.item), index = args.index})

end

function sInventory:AddItemRemote(args)

    if not IsValid(args.player) or not IsValid(self.player) then return end

    if args.player ~= self.player then
        error(debug.traceback("sInventory:AddItemRemote failed: player does not match"))
        return
    end

    self:AddStack({stack = shStack({contents = {shItem(args.item)}}), index = args.index})

end

function sInventory:RecreateStack(stackobj)

    local items = {}

    for i, j in ipairs(stackobj.contents) do
        items[i] = shItem(j)
    end

    return shStack({contents = items, uid = stackobj.uid})

end

function sInventory:ModifyStackRemote(args)

    if args.player ~= self.player then
        error(debug.traceback("sInventory:ModifyStackRemote failed: player does not match"))
        return
    end

    self:ModifyStack({stack = self:RecreateStack(args.stack), index = args.index})

end

function sInventory:SetItemEquippedRemote(args)

    if args.player ~= self.player then
        error(debug.traceback("sInventory:SetItemEquippedRemote failed: player does not match"))
        return
    end

    local cat = args.item.category
    local index = args.index

    local stack = self.contents[cat][index]
    if not stack then return end

    for item_index, item in pairs(stack.contents) do
        if item.uid == args.item.uid then
            stack.contents[item_index].equipped = args.equipped

            Events:Fire("Inventory/ToggleEquipped", {player = self.player, index = index, item = item:GetSyncObject()})
            self:Sync({index = index, stack = stack, sync_stack = true})
            
            break
        end
    end

end

function sInventory:ModifyItemCustomDataRemote(args)

    if args.player ~= self.player then
        error(debug.traceback("sInventory:ModifyItemCustomDataRemote failed: player does not match"))
        return
    end

    local cat = args.item.category

    for index, stack in pairs(self.contents[cat]) do

        for _, item in pairs(stack.contents) do

            if item.uid == args.item.uid then

                item.custom_data = args.custom_data
                self:Sync({index = index, stack = stack, sync_stack = true})

                return

            end

        end

    end


end

function sInventory:ModifyDurabilityRemote(args)

    local cat = args.item.category

    for index, stack in pairs(self.contents[cat]) do

        for _, item in pairs(stack.contents) do

            if item.uid == args.item.uid then

                if args.item.durability > 0 then
                    item.durability = args.item.durability
                    self:Sync({index = index, stack = stack, sync_stack = true})
                else
                    self:OnItemBreak(item:Copy())
                    self:RemoveItem({item = item, index = index, remove_by_uid = true})
                end

                return

            end

        end

    end

end

-- Called when an item runs out of durability and breaks
function sInventory:OnItemBreak(item)
    Chat:Send(self.player, string.format("%s ran out of durability and broke!", item.name), Color.Red)

    if item.name == "Parachute" then
        -- Special FX for when a parachute breaks
        Network:Send(self.player, "InventoryFX/ParachuteBreak", {
            player = self.player
        })

        Network:SendNearby(self.player, "InventoryFX/ParachuteBreak", {
            player = self.player
        })
    elseif item.name == "Grapplehook" or item.name == "RocketGrapple" then
        -- Special FX for when a parachute breaks
        Network:Send(self.player, "InventoryFX/GrapplehookBreak", {
            player = self.player
        })

        Network:SendNearby(self.player, "InventoryFX/GrapplehookBreak", {
            player = self.player
        })
    end
end

-- Adds a stack to the inventory, and will try to add it to specified index if possible
-- Will also try to add it to an empty inventory space if new_space is true
-- Syncs automatically
function sInventory:AddStack(args)

    local item_data = Items_indexed[args.stack:GetProperty("name")]

    if item_data.max_held then
        -- If you can only hold a certain amount of this item

        local num_of_this_item = Inventory.GetNumOfItem({player = self.player, item_name = args.stack:GetProperty("name")})

        if num_of_this_item >= item_data.max_held then
            Chat:Send(self.player, 
                string.format("You can only hold %d %s at a time!", item_data.max_held, args.stack:GetProperty("name")), Color.Red)
            return args.stack
        end

    end

    local cat = args.stack:GetProperty("category")

    -- Try to stack it in a specific place
    if args.index then

        local istack = self.contents[cat][args.index]

        if not istack
        or istack:GetProperty("name") ~= args.stack:GetProperty("name")
        or istack:GetAmount() == istack:GetProperty("name") then
            return args.stack
        end 

        local return_item = istack:AddItem(args.stack:RemoveItem(nil, 1))

        if return_item then
            args.stack:AddItem(return_item)
        end

        self:Sync({index = args.index, stack = istack, sync_stack = true})

        if args.stack:GetAmount() > 0 then
            Chat:Send(self.player, string.format("%s category is full!", cat), Color.Red)
            return args.stack
        else
            return
        end

    end

    -- Loop through stacks in category and see if we can stack the item(s)
    if not args.new_space then

        for i, istack in ipairs(self.contents[cat]) do

            if istack and i ~= args.avoid_index then

                -- First, try to stack it with existing stacks of the same item
                while args.stack:GetProperty("name") == istack:GetProperty("name")
                and istack:GetAmount() < istack:GetProperty("stacklimit")
                and args.stack:GetAmount() > 0 do

                    local return_item = istack:AddItem(args.stack:RemoveItem(nil, 1))

                    if return_item then
                        args.stack:AddItem(return_item)
                    end

                    self:Sync({index = i, stack = istack, sync_stack = true})

                end

            end

        end

    end

    -- Still have some left, so check empty spaces now
    while args.stack:GetAmount() > 0 and self:HaveEmptySpaces(cat) do

        local index = #self.contents[cat] + 1
        self.contents[cat][index] = args.stack:Copy()
        args.stack.contents = {} -- Clear stack contents
        self:Sync({index = index, stack = self.contents[cat][index], sync_stack = true})
    
    end

    if args.stack:GetAmount() > 0 then
        Chat:Send(self.player, string.format("%s category is full!", cat), Color.Red)
        return args.stack
    end

end

-- Returns whether or not a category has empty spaces in it
function sInventory:HaveEmptySpaces(category)
    return count_table(self.contents[category]) < self:GetNumSlotsInCategory(category)
end

function sInventory:RemoveStack(args)

    local cat = args.stack:GetProperty("category")

    if args.index and not self.contents[cat][args.index] then return end

    if args.index and self.contents[cat][args.index]:GetProperty("name") == args.stack:GetProperty("name") then

        -- If we are not removing the entire stack
        if args.stack:GetAmount() < self.contents[cat][args.index]:GetAmount() then

            local leftover_stack, removed_stack = self.contents[cat][args.index]:RemoveStack(args.stack)

            if leftover_stack and leftover_stack:GetAmount() > 0 then
                print("**Unable to remove some items!**")
                print(string.format("Player: %s [%s]", tostring(self.player:GetSteamId())))
                print(leftover_stack:ToString())
                print(debug.traceback())
            end

            self:Sync({index = args.index, stack = self.contents[cat][args.index], sync_stack = true})

            if removed_stack then
                self:CheckIfStackHasOneEquippedThenUnequip(removed_stack)
            end

        else

            self:CheckIfStackHasOneEquippedThenUnequip(self.contents[cat][args.index])

            -- If we are not removing the last item
            if args.index < #self.contents[cat] then
                self:ShiftItemsDown(cat, args.index)
                self:Sync({sync_cat = true, cat = cat}) -- Category sync for less network requests
            else
                self.contents[cat][args.index] = nil
                stack = nil
                self:Sync({index = args.index, cat = cat, sync_remove = true})
            end

        end

        self:CheckForOverflow()

    else

        -- Remove by stack uid
        for _index, _stack in pairs(self.contents[cat]) do

            if _stack.uid == args.stack.uid then
                
                self:CheckIfStackHasOneEquippedThenUnequip(self.contents[cat][_index])

                if _index < #self.contents[cat] then
                    self:ShiftItemsDown(cat, _index)
                    self:Sync({sync_cat = true, cat = cat})
                else
                    self.contents[cat][_index] = nil
                    args.stack = nil
                    self:Sync({index = _index, cat = cat, sync_remove = true})
                end

                break
            end

        end

        self:CheckForOverflow()

        if not args.stack then return end

        if args.stack:GetAmount() == 1 then
            -- Only removing one item, so look for uid
            local item = args.stack.contents[1]

            -- Check for matching item uids in stacks
            for index, stack in pairs(self.contents[cat]) do

                for item_index, _item in pairs(stack.contents) do

                    if item.uid == _item.uid then
                        
                        stack:RemoveItem(item)
                        args.stack:RemoveItem(item)

                        -- Removed entire stack
                        if stack:GetAmount() == 0 then

                            -- If we are not removing the last item
                            if index < #self.contents[cat] then
                                self:ShiftItemsDown(cat, index)
                                self:Sync({sync_cat = true, cat = cat}) -- Category sync for less network requests
                            else
                                self.contents[cat][index] = nil
                                stack = nil
                                self:Sync({index = index, cat = cat, sync_remove = true})
                            end

                            self:CheckForOverflow()

                            return

                        else

                            self.contents[cat][index] = stack
                            self:Sync({index = index, stack = self.contents[cat][index], sync_stack = true})

                            self:CheckForOverflow()

                        end

                    end

                end

            end
        end

        self:CheckForOverflow()

        if not args.stack then return end

        -- If we are just subtracting items, not by uid or index
        local name = args.stack:GetProperty("name")

        for i, check_stack in ipairs(self.contents[cat]) do
    
            if check_stack and check_stack:GetProperty("name") == name then

                local return_stack = check_stack:RemoveStack(args.stack)

                if check_stack:GetAmount() == 0 then
                    
                    self:CheckIfStackHasOneEquippedThenUnequip(self.contents[cat][i])

                    if i < #self.contents[cat] then
                        self:ShiftItemsDown(cat, i)
                        self:Sync({sync_cat = true, cat = cat})
                    else
                        self.contents[cat][i] = nil
                        self:Sync({index = i, cat = cat, sync_remove = true})
                    end

                end



                -- Got more items to remove, so keep going
                if return_stack and return_stack:GetAmount() > 0 then
                    args.stack = return_stack
                else -- Otherwise break, we are done

                    if self.contents[cat][i] and self.contents[cat][i]:GetAmount() > 0 then
                        self:Sync({index = i, sync_stack = true, stack = self.contents[cat][i]})
                    end

                    args.stack = nil
                    break
                end

                self:CheckForOverflow()

            end


        end

    end

end

-- Shifts items in a category down incase one in the middle was removed
-- This WILL remove the stack within index
function sInventory:ShiftItemsDown(cat, index)
    local temp_index = index
    local contents_amount = #self.contents[cat] - 1
    while temp_index <= contents_amount do
        self.contents[cat][temp_index] = self.contents[cat][temp_index + 1]:Copy() -- Copy items into new slot
        temp_index = temp_index + 1
    end
    self.contents[cat][contents_amount + 1] = nil -- Remove old top item
end

function sInventory:CheckIfStackHasOneEquippedThenUnequip(stack)

    if stack:GetEquipped() then
        for _, item in pairs(stack.contents) do
            if item.equipped then
                item.equipped = false
                Events:Fire("Inventory/ToggleEquipped", 
                    {player = self.player, index = _, item = item:GetSyncObject()})
            end
        end    
    end

end

function sInventory:RemoveItem(args)
    args.stack = shStack({contents = {args.item}})
    self:RemoveStack(args)
end

function sInventory:ModifyStack(stack, index)
    self.contents[stack:GetProperty("category")][index] = stack
    self:Sync({index = index, stack = stack, sync_stack = true})
end

-- Syncs inventory to player and all modules
function sInventory:Sync(args)

    if not IsValid(self.player) then return end

    if not self.initial_sync and not args.sync_full then return end -- Don't sync anything until we do the initial sync

    self.player:SetValue("Inventory", self:GetSyncObject())

    -- Initial sync, so also equip all things that were equipped before
    if not self.initial_sync then
        for cat, _ in pairs(self.contents) do
            for _, stack in pairs(self.contents[cat]) do
                if stack:GetOneEquipped() then
                    for _, item in pairs(stack.contents) do
                        if item.equipped then
                            Events:Fire("Inventory/ToggleEquipped", {
                                player = self.player, 
                                index = _,
                                initial = true,
                                item = item:Copy():GetSyncObject()})
                        end
                    end
                end
            end
        end
    end

    if args.sync_full then -- Sync entire inventory
        Network:Send(self.player, "InventoryUpdated", 
            {action = "full", data = self:GetSyncObject()})
    elseif args.sync_stack then -- Sync a single stack
        Network:Send(self.player, "InventoryUpdated", 
            {action = "update", cat = args.stack:GetProperty("category"), stack = args.stack:GetSyncObject(), index = args.index})
    elseif args.sync_remove then -- Sync the removal of a stack (only used if it was the top stack)
        Network:Send(self.player, "InventoryUpdated", 
            {action = "remove", cat = args.cat, index = args.index})
    elseif args.sync_cat then -- Sync an entire category of items
        Network:Send(self.player, "InventoryUpdated", 
            {action = "cat", cat = args.cat, data = self:GetCategorySyncObject(args.cat)})
    elseif args.sync_slots then -- Sync ONLY slots
        Network:Send(self.player, "InventoryUpdated", 
            {action = "slots", slots = self.slots})
    end

    -- If initial sync was done already, then update the database with the new info
    if self.initial_sync and not self.invsee_source then
        --self:UpdateDB()
        Events:Fire("InventoryUpdated", {player = self.player})
    end

    for _, inventory in pairs(self.invsee) do

        if IsValid(inventory.player) and inventory.player ~= self.player then
            inventory.contents = self.contents
            inventory.slots = self.slots
            
            inventory:Sync(args)
        else
            self.invsee[_] = nil
        end
    end

end

function sInventory:UpdateDB()

    if not IsValid(self.player) then return end
    if self.invsee_source then return end

    local serialized = self:Serialize()

    local update = SQL:Command("UPDATE inventory SET contents = ? WHERE steamID = (?)")
	update:Bind(1, serialized)
	update:Bind(2, self.steamID)
	update:Execute()

end

function sInventory:Serialize()
    return Serialize(self.contents, true)
end

function sInventory:Deserialize(data)
    self.contents = Deserialize(data, true)
end

function sInventory:Unload()

    self:UpdateDB()

    for k,v in pairs(self.events) do
        Events:Unsubscribe(v)
    end

    for k,v in pairs(self.network_events) do
        Network:Unsubscribe(v)
    end

    Timer.Clear(self.update_timer)
    
    self.player = nil
    self.contents = nil
    self.initial_sync = nil
    self.steamID = nil
    self.events = nil
    self.network_events = nil
    self = nil

end

-- Use for initial sync AND player:GetValue("Inventory")
function sInventory:GetSyncObject()

    local data = {}

    for category, _ in pairs(self.contents) do
        data[category] = {}
        for k,v in pairs(self.contents[category]) do
            data[category][k] = {stack = v:GetSyncObject(), index = k}
        end
    end

    return {contents = data, slots = self.slots}

end

function sInventory:GetCategorySyncObject(cat)
    local contents = {}
    for k,v in pairs(self.contents[cat]) do
        contents[k] = {stack = v:GetSyncObject(), index = k}
    end
    return {contents = contents, slots = self.slots[cat]}
end

function splitstr2(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end