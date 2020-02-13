class 'sInventory'

function sInventory:__init(player)

    self.player = player
    self.contents = {} -- Contents of the player's inventory
    self.slots = {} -- Number of slots that the player has for each inventory category (use self:GetSlots(cat))
    self.initial_sync = false
    self.steamID = tostring(player:GetSteamId().id)
    self.operation_block = 0 -- Increment/decrement this to disable inventory operations
    
    self:Load()

    self.events = {}
    self.network_events = {}

    table.insert(self.events, Events:Subscribe("Inventory.AddStack-" .. self.steamID, self, self.AddStackRemote))
    table.insert(self.events, Events:Subscribe("Inventory.AddItem-" .. self.steamID, self, self.AddItemRemote))
    table.insert(self.events, Events:Subscribe("Inventory.RemoveStack-" .. self.steamID, self, self.RemoveStackRemote))
    table.insert(self.events, Events:Subscribe("Inventory.RemoveItem-" .. self.steamID, self, self.RemoveItemRemote))
    table.insert(self.events, Events:Subscribe("Inventory.ModifyStack-" .. self.steamID, self, self.ModifyStackRemote))
    table.insert(self.events, Events:Subscribe("Inventory.ModifyDurability-" .. self.steamID, self, self.ModifyDurabilityRemote))
    table.insert(self.events, Events:Subscribe("Inventory.OperationBlock-" .. self.steamID, self, self.OperationBlockRemote))

    table.insert(self.network_events, Network:Subscribe("Inventory/Shift" .. self.steamID, self, self.ShiftStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/ToggleEquipped" .. self.steamID, self, self.ToggleEquipped))
    table.insert(self.network_events, Network:Subscribe("Inventory/Use" .. self.steamID, self, self.UseItem))
    table.insert(self.network_events, Network:Subscribe("Inventory/Drop" .. self.steamID, self, self.DropStacks))
    table.insert(self.network_events, Network:Subscribe("Inventory/Split" .. self.steamID, self, self.SplitStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/Swap" .. self.steamID, self, self.SwapStack))

end

function sInventory:Load()

    -- Initialize subtables of categories
    for index, cat_info in pairs(Inventory.config.categories) do
        self.contents[cat_info.name] = {}
        self.slots[cat_info.name] = {default = cat_info.slots, level = 0, backpack = 0}
    end

	local query = SQL:Query("SELECT contents FROM inventory WHERE steamID = (?) LIMIT 1")
    query:Bind(1, self.steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        
        self:Deserialize(result[1].contents)
        
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

function sInventory:ShiftStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index or not args.cat then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end

    self.contents[args.cat][args.index]:Shift()
    self:Sync({index = args.index, stack = self.contents[args.cat][args.index], sync_stack = true})

end

function sInventory:ToggleEquipped(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index or not args.cat then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end
    if not self.contents[args.cat][args.index]:GetProperty("can_equip") then return end

    -- check for items of same equip type and unequip them
    local equip_type = self.contents[args.cat][args.index]:GetProperty("equip_type")
    local can_equip = true

    if equip_type ~= "grapple_upgrade" then
        for cat, _ in pairs(self.contents) do
            for stack_index, stack in pairs(self.contents[cat]) do
                for item_index, item in pairs(stack.contents) do

                    if item.equipped and item.equip_type == equip_type
                    and item.uid ~= self.contents[args.cat][args.index].contents[1].uid then

                        item.equipped = false
                        self:Sync({index = stack_index, stack = self.contents[cat][stack_index], sync_stack = true})
                        Events:Fire("Inventory/ToggleEquipped", 
                            {player = self.player, item = self.contents[cat][stack_index].contents[1]:Copy():GetSyncObject()})

                    end

                end
            end
        end
    else -- Trying to equip a grapple upgrade
        
        local num_upgrades = 0

        for cat, _ in pairs(self.contents) do
            for index, stack in pairs(self.contents[cat]) do
                for item_index, item in pairs(stack.contents) do

                    if item.equipped and item.equip_type == equip_type
                    and item.uid ~= self.contents[args.cat][args.index].contents[1].uid then

                        num_upgrades = num_upgrades + 1
                        
                    end

                end
            end
        end
        can_equip = num_upgrades < Inventory.config.max_grapple_upgrades
    end

    -- Toggle equipped if it's not a grapple upgrade OR if we can equip a grapple upgrade OR if we are unequipping an upgrade
    if equip_type ~= "grapple_upgrade" or can_equip or self.contents[args.cat][args.index].contents[1].equipped then
        self.contents[args.cat][args.index].contents[1].equipped = not self.contents[args.cat][args.index].contents[1].equipped
    else
        Chat:Send(self.player, "you must unequip first", Color.Red)
        -- tell player they have to unequip a grapple upgrade before equipping another one
    end

    self:Sync({index = args.index, stack = self.contents[args.cat][args.index], sync_stack = true})

    Events:Fire("Inventory/ToggleEquipped", 
        {player = self.player, item = self.contents[args.cat][args.index].contents[1]:Copy():GetSyncObject()})

end

function sInventory:UseItem(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index or not args.cat then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end
    if not self.contents[args.cat][args.index]:GetProperty("can_use") then return end

    local copy = self.contents[args.cat][args.index].contents[1]:Copy()
    copy.amount = 1

    Events:Fire("Inventory/UseItem", 
        {player = self.player, item = copy:GetSyncObject(), cat = args.cat, index = args.index})

end

function sInventory:DropStacks(args, player)
    
    if not args.stacks then return end
    if count_table(args.stacks) == 0 then return end

    for _, data in pairs(args.stacks) do
        self:DropStack(data, player)
    end

end

function sInventory:DropStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if player ~= self.player then return end
    if not self.contents[args.cat] or not self.contents[args.cat][args.index] then return end
    if not args.amount or args.amount < 1 then return end

    if not tonumber(tostring(args.amount)) then
        args.amount = 1
    end

    local stack = self.contents[args.cat][args.index]

    if not stack then return end
    if args.amount > stack:GetAmount() then return end

    if player:InVehicle() then return end -- TODO drop in vehicle storage

    -- Not dropping the entire stack
    if args.amount < stack:GetAmount() then

        local split_stack = self.contents[args.cat][args.index]:Split(args.amount)
        self:Sync({index = args.index, stack = self.contents[args.cat][args.index], sync_stack = true})

        self:CheckIfStackHasOneEquippedThenUnequip(split_stack)

        CreateLootbox({
            position = player:GetPosition(),
            angle = player:GetAngle(),
            tier = Lootbox.Types.Dropbox,
            contents = {[1] = split_stack}
        })

    else -- Dropping the entire stack

        self:CheckIfStackHasOneEquippedThenUnequip(stack)

        CreateLootbox({
            position = player:GetPosition(),
            angle = player:GetAngle(),
            tier = Lootbox.Types.Dropbox,
            contents = {[1] = stack}
        })

        self:RemoveStack({stack = stack, index = args.index})

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
        and not player:GetValue("Loading") and player:GetEnabled()

end

function sInventory:OperationBlockRemote(args)

    if args.player ~= self.player then
        error("sInventory:OperationBlockRemote failed: player does not match")
        return
    end

    self.operation_block = self.operation_block + args.change

end

function sInventory:AddStackRemote(args)

    if args.player ~= self.player then
        error("sInventory:AddStackRemote failed: player does not match")
        return
    end

    args.stack = self:RecreateStack(args.stack)
    self:AddStack(args)

end

function sInventory:RemoveStackRemote(args)

    if args.player ~= self.player then
        error("sInventory:RemoveStackRemote failed: player does not match")
        return
    end

    self:RemoveStack({stack = self:RecreateStack(args.stack), index = args.index})

end

function sInventory:RemoveItemRemote(args)

    if args.player ~= self.player then
        error("sInventory:RemoveItemRemote failed: player does not match")
        return
    end

    self:RemoveItem({item = shItem(args.item), index = args.index})

end

function sInventory:AddItemRemote(args)

    if args.player ~= self.player then
        error("sInventory:AddItemRemote failed: player does not match")
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
        error("sInventory:ModifyStackRemote failed: player does not match")
        return
    end

    self:ModifyStack({stack = self:RecreateStack(args.stack), index = args.index})

end

function sInventory:ModifyDurabilityRemote(args)

    if args.player ~= self.player then
        error("sInventory:ModifyDurabilityRemote failed: player does not match")
        return
    end

    local cat = args.item.category

    for index, stack in pairs(self.contents[cat]) do

        for _, item in pairs(stack.contents) do

            if item.uid == args.item.uid then

                if args.item.durability > 0 then
                    item.durability = args.item.durability
                    self:Sync({index = index, stack = stack, sync_stack = true})
                else
                    self:RemoveItem({item = item, index = index})
                end

                return

            end

        end

    end

end

-- Adds a stack to the inventory, and will try to add it to specified index if possible
-- Will also try to add it to an empty inventory space if new_space is true
-- Syncs automatically
function sInventory:AddStack(args)

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

        if args.stack:GetAmount() > 0 then return args.stack else return end

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
        return args.stack
        --error("sInventory:AddStack failed: there were some items left over")
    end

end

-- Returns whether or not a category has empty spaces in it
function sInventory:HaveEmptySpaces(category)
    return count_table(self.contents[category]) < self:GetNumSlotsInCategory(category)
end

function sInventory:RemoveStack(args)

    local cat = args.stack:GetProperty("category")

    if args.index and not self.contents[cat][args.index] then return end

    if args.index then

        -- If we are not removing the entire stack
        if args.stack:GetAmount() < self.contents[cat][args.index]:GetAmount() then

            local split_stack = self.contents[cat][args.index]:Split(args.stack:GetAmount())
            self:Sync({index = args.index, stack = self.contents[cat][args.index], sync_stack = true})

            self:CheckIfStackHasOneEquippedThenUnequip(split_stack)

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

    else

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

        -- If we are just subtracting items, not by uid or index
        if args.stack then

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
                    if return_stack then
                        args.stack = return_stack
                    else -- Otherwise break, we are done

                        if self.contents[cat][i] and self.contents[cat][i]:GetAmount() > 0 then
                            self:Sync({index = i, sync_stack = true, stack = self.contents[cat][i]})
                        end

                        args.stack = nil
                        break
                    end


                end
        
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
                    {player = self.player, item = item:GetSyncObject()})
            end
        end    
    end

end

function sInventory:RemoveItem(args)
    self:RemoveStack({stack = shStack({contents = {args.item}}), index = args.index})
end

function sInventory:ModifyStack(stack, index)
    self.contents[stack:GetProperty("category")][index] = stack
    self:Sync({index = index, stack = stack, sync_stack = true})
end

-- Syncs inventory to player and all modules
function sInventory:Sync(args)

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
    if self.initial_sync then
        self:UpdateDB()
    end

end

function sInventory:UpdateDB()

    local serialized = self:Serialize()

    local update = SQL:Command("UPDATE inventory SET contents = ? WHERE steamID = (?)")
	update:Bind(1, serialized)
	update:Bind(2, self.steamID)
	update:Execute()

end

function sInventory:Serialize()

    local str = '';
    for cat_name, _ in pairs(self.contents) do

        for i, stack in ipairs(self.contents[cat_name]) do
            for j = 1, #stack.contents do
            
                local item = stack.contents[j]
                str = str .. tostring(i) .. "=" .. item.name .. "=" .. tostring(item.amount)

                str = (item.equipped) and str .. "=E" or str
                str = (item.durability and item.durability > 0) and str .. "=D" .. tostring(item.durability) or str

                -- If this item has at least 1 custom data
                for k,v in pairs(item.custom_data) do
                
                    str = str .. "=N" .. tostring(k) .. ">" .. tostring(v)

                end

                str = str .. "~";

            end

            str = str .. "|";

        end

    end

    return str;

end

function sInventory:Deserialize(data)

    data = tostring(data)

    local split = splitstr2(data, "|")
    local inventory = {}

    for _, cat_data in pairs(Inventory.config.categories) do
        inventory[cat_data.name] = {}
    end

    for i = 1, #split - 1 do -- Each stack
    
        local split2 = splitstr2(split[i], "~")
        local stack = nil
        local index = 0

        for j = 1, #split2 - 1 do -- Each item within the stack
        
            local split3 = splitstr2(split2[j], "=")
            local item_data = {}

            for k = 1, #split3 do -- Each property within the item

                if (k == 1) then -- Index
                
                    index = tonumber(split3[k])
                
                elseif (k == 2) then -- Name
                
                    item_data.name = split3[k]

                    if not CreateItem({name = item_data.name, amount = 1}) then -- Unable to find item, eg does not exist
                        error("Unable to find item with name " .. tostring(split3[k]) .. " in convert_string")
                    end
                
                elseif (k == 3) then -- Amount
                
                    item_data.amount = tonumber(split3[k])
                
                elseif (split3[k]:sub(1, 1) == "E" and k > 3) then -- Equipped
                
                    item_data.equipped = true
                
                elseif (split3[k]:sub(1, 1) == "D" and k > 3) then -- Durability
                
                    item_data.durability = tonumber(splitstr(split3[k], "D")[1])
                
                elseif (split3[k]:sub(1, 1) == "N" and k > 3) then -- Custom property/data
                
                    local replaced = split3[k]:gsub("N", "")
                    local replaced_split = splitstr(replaced, ">")
                    item_data.custom_data[replaced_split[0]] = replaced_split[1]
                end
                
            end

            local item = CreateItem(item_data) -- Create item

            if (not stack) then -- If this is the first item, create the stack
            
                stack = shStack({contents = {item}});
            
            else -- Otherwise, add it to the front of the stack
            
                stack:AddItem(item);

            end

            
        end

        -- .amount for the first item goes to 2 or something and then new items are not added to the stack

        if index > 0 then
            inventory[stack:GetProperty("category")][index] = stack
        end


    end

    self.contents = inventory

end

function sInventory:Unload()

    for k,v in pairs(self.events) do
        Events:Unsubscribe(v)
    end

    for k,v in pairs(self.network_events) do
        Network:Unsubscribe(v)
    end

    
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