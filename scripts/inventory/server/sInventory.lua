class 'sInventory'

function sInventory:__init(player)

    self.player = player
    self.contents = {}
    self.hotbar = {}
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
    table.insert(self.network_events, Network:Subscribe("Inventory/Drop" .. self.steamID, self, self.DropStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/Split" .. self.steamID, self, self.SplitStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/Swap" .. self.steamID, self, self.SwapStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/Combine" .. self.steamID, self, self.CombineStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/Hotbar" .. self.steamID, self, self.HotbarStack))
    table.insert(self.network_events, Network:Subscribe("Inventory/HotbarUse" .. self.steamID, self, self.HotbarUse))

end

function sInventory:Load()

	local query = SQL:Query("SELECT contents, hotbar FROM inventory WHERE steamID = (?) LIMIT 1")
    query:Bind(1, self.steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        
        self:Deserialize(result[1].contents)
        self:DeserializeHotbar(result[1].hotbar)
        
    else
        
		local command = SQL:Command("INSERT INTO inventory (steamID, contents, hotbar) VALUES (?, ?, ?)")
		command:Bind(1, self.steamID)
		command:Bind(2, "")
		command:Bind(3, "")
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
    if not args.index then return end
    if not self.contents[args.index] then return end

    self.contents[args.index]:Shift()
    self:Sync({index = args.index, stack = self.contents[args.index], sync_stack = true})

end

function sInventory:ToggleEquipped(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index then return end
    if not self.contents[args.index] then return end
    if not self.contents[args.index]:GetProperty("can_equip") then return end

    -- check for items of same equip type and unequip them
    local equip_type = self.contents[args.index]:GetProperty("equip_type")
    local can_equip = true

    if equip_type ~= "grapple_upgrade" then
        for stack_index, stack in pairs(self.contents) do
            if stack then
                for item_index, item in pairs(stack.contents) do

                    if item.equipped and item.equip_type == equip_type
                    and item.uid ~= self.contents[args.index].contents[1].uid then

                        item.equipped = false
                        self:Sync({index = stack_index, stack = self.contents[stack_index], sync_stack = true})
                        Events:Fire("Inventory/ToggleEquipped", 
                            {player = self.player, item = self.contents[stack_index].contents[1]:Copy():GetSyncObject()})

                    end

                end
            end
        end
    else -- Trying to equip a grapple upgrade
        
        local num_upgrades = 0

        for stack_index, stack in pairs(self.contents) do
            if stack then
                for item_index, item in pairs(stack.contents) do

                    if item.equipped and item.equip_type == equip_type
                    and item.uid ~= self.contents[args.index].contents[1].uid then

                        num_upgrades = num_upgrades + 1
                        
                    end

                end
            end
        end
        can_equip = num_upgrades < Inventory.config.max_grapple_upgrades
    end

    -- Toggle equipped if it's not a grapple upgrade OR if we can equip a grapple upgrade OR if we are unequipping an upgrade
    if equip_type ~= "grapple_upgrade" or can_equip or self.contents[args.index].contents[1].equipped then
        self.contents[args.index].contents[1].equipped = not self.contents[args.index].contents[1].equipped
    else
        Chat:Send(self.player, "you must unequip first", Color.Red)
        -- tell player they have to unequip a grapple upgrade before equipping another one
    end

    self:Sync({index = args.index, stack = self.contents[args.index], sync_stack = true})

    Events:Fire("Inventory/ToggleEquipped", 
        {player = self.player, item = self.contents[args.index].contents[1]:Copy():GetSyncObject()})

end

function sInventory:UseItem(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index then return end
    if not self.contents[args.index] then return end
    if not self.contents[args.index]:GetProperty("can_use") then return end

    local copy = self.contents[args.index].contents[1]:Copy()
    copy.amount = 1

    Events:Fire("Inventory/UseItem", 
        {player = self.player, item = copy:GetSyncObject(), index = args.index})

end

function sInventory:DropStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if player ~= self.player then return end
    if not self.contents[args.index] then return end
    if not args.amount or args.amount < 1 then return end

    if not tonumber(tostring(args.amount)) then
        args.amount = 1
    end

    if args.amount < 1 then return end

    local stack = self.contents[args.index]

    if not stack then return end
    if args.amount > stack:GetAmount() then return end

    if player:InVehicle() then return end -- TODO drop in vehicle storage

    if args.amount < stack:GetAmount() then

        local split_stack = self.contents[args.index]:Split(args.amount)
        self:Sync({index = args.index, stack = self.contents[args.index], sync_stack = true})

        self:CheckIfStackHasOneEquippedThenUnequip(split_stack)

        CreateLootbox({
            position = player:GetPosition(),
            angle = player:GetAngle(),
            tier = Lootbox.Types.Dropbox,
            contents = {[1] = split_stack}
        })

    else

        self:CheckIfStackHasOneEquippedThenUnequip(stack)

        CreateLootbox({
            position = player:GetPosition(),
            angle = player:GetAngle(),
            tier = Lootbox.Types.Dropbox,
            contents = {[1] = stack}
        })

        self:RemoveStack({stack = stack})

    end

end

function sInventory:SplitStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if player ~= self.player then return end
    if not self.contents[args.index] then return end
    if not args.amount or args.amount < 1 then return end

    if not tonumber(tostring(args.amount)) then
        args.amount = 1
    end

    if args.amount >= self.contents[args.index]:GetAmount() or args.amount < 1 then return end
    
    -- TODO regenerate uids of items in new split stack
    -- not really an issue right now because we use stack indexes then look inside those for uids
    local split_stack = self.contents[args.index]:Split(args.amount)
    self:Sync({index = args.index, stack = self.contents[args.index], sync_stack = true})

    local return_stack = self:AddStack({stack = split_stack, new_space = true})

    if return_stack then
        self:AddStack({stack = return_stack})
    end

end

function sInventory:SwapStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.from or not args.to then return end
    if not self.contents[args.from] then return end

    local stack = self.contents[args.from]

    -- Cannot make it go in a separate category
    if stack:GetProperty("category") ~= self:GetCategoryFromIndex(args.to) then return end

    -- TODO regenerate uids of items in new split stack
    -- not really an issue right now because we use stack indexes then look inside those for uids
    local stack_copy = self.contents[args.from]:Copy()

    local swap_with_empty = not self.contents[args.to]

    -- Swap hotbar indices
    for hotbar_index, inventory_index in pairs(self.hotbar) do

        if inventory_index == args.to then

            self.hotbar[hotbar_index] = args.from

        elseif inventory_index == args.from then

            self.hotbar[hotbar_index] = args.to

        end

    end

    self:UpdateHotbar()

    self.contents[args.from] = self.contents[args.to]
    self.contents[args.to] = stack_copy

    -- Place we moved item was empty
    if swap_with_empty then
        self:Sync({index = args.from, sync_remove = true})
    else
        self:Sync({index = args.from, stack = self.contents[args.from], sync_stack = true})
    end


    self:Sync({index = args.to, stack = self.contents[args.to], sync_stack = true})


end

function sInventory:CombineStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index then return end
    if not self.contents[args.index] then return end

    local stack = self.contents[args.index]
    local name = stack:GetProperty("name")

    if not stack or stack:GetAmount() >= stack:GetProperty("stacklimit") then return end

    local cat_info = self:GetCategoryInfo(stack:GetProperty("category"))
    
    for i = cat_info.start_index, cat_info.end_index do

        local check_stack = self.contents[i]

        if check_stack and check_stack:GetProperty("name") == name 
        and check_stack:GetAmount() < check_stack:GetProperty("stacklimit")
        and args.index ~= i then

            local return_stack = stack:AddStack(check_stack)

            if return_stack then
                self.contents[i] = return_stack
                self:Sync({index = i, stack = return_stack, sync_stack = true})
            else
                self.contents[i] = nil
                self:Sync({index = i, sync_remove = true})
                
                self:RemoveHotbarIndex(i)
                self:UpdateHotbar()
            end

        end

    end

    self:Sync({index = args.index, stack = self.contents[args.index], sync_stack = true})

end

function sInventory:HotbarStack(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index or not args.hotbar_index then return end
    if not self.contents[args.index] then return end
    if args.hotbar_index < 1 or args.hotbar_index > 10 then return end
    if not self.contents[args.index]:GetProperty("can_equip") and not self.contents[args.index]:GetProperty("can_use") then return end


    if self.hotbar[tonumber(args.hotbar_index)] == tonumber(args.index) then
        self.hotbar[tonumber(args.hotbar_index)] = nil
    else
        self.hotbar[tonumber(args.hotbar_index)] = tonumber(args.index)
    end

    -- If this item is already assigned to a space, remove it from the old one
    for hotbar_index, inventory_index in pairs(self.hotbar) do
        if inventory_index == args.index and args.hotbar_index ~= hotbar_index then
            self.hotbar[hotbar_index] = nil
        end
    end


    self:UpdateHotbar()

end

function sInventory:HotbarUse(args, player)

    if not self:CanPlayerPerformOperations(player) then return end
    if not args.index then return end

    local hotbar_link = self.hotbar[args.index]
    if not hotbar_link then return end

    local stack = self.contents[hotbar_link]

    if not stack then return end

    if stack:GetProperty("can_equip") then
        self:ToggleEquipped({index = hotbar_link}, player)
    elseif stack:GetProperty("can_use") then
        self:UseItem({index = hotbar_link}, player)
    end

end

-- Syncs to player and also updates to DB
function sInventory:UpdateHotbar()

    Network:Send(self.player, "InventoryHotbarUpdated", self.hotbar)

    local serialized = self:SerializeHotbar()

    local update = SQL:Command("UPDATE inventory SET hotbar = ? WHERE steamID = (?)")
	update:Bind(1, serialized)
	update:Bind(2, self.steamID)
	update:Execute()


end

function sInventory:CanPlayerPerformOperations(player)

    -- eventually modify this so that admins can do stuff if they clone the inv
    return IsValid(player) and IsValid(self.player) and player == self.player and self.operation_block == 0
        and not player:GetValue("Loading") and player:GetEnabled()

end

-- Returns a table with start_index and end_index so you can loop through lol
function sInventory:GetCategoryInfo(cat)

    local data = {start_index = 1, end_index = 0}

    local slots = 0

    for k,v in ipairs(Inventory.config.categories) do

        data.end_index = data.end_index + v.slots

        if v.name == cat then return data end

        data.start_index = data.start_index + v.slots

    end

end

function sInventory:GetCategoryFromIndex(index)

    local slots = 0
    
    for k,v in ipairs(Inventory.config.categories) do

        slots = slots + v.slots

        if index <= slots and index > 0 then return v.name end

    end

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

    for index, stack in pairs(self.contents) do

        for _, item in pairs(stack.contents) do

            if item.uid == args.item.uid then

                if args.item.durability > 0 then
                    item.durability = args.item.durability
                    self:Sync({index = index, stack = stack, sync_stack = true})
                else
                    self:RemoveItem({item = item, index = index})
                    self:RemoveHotbarIndex(index)
                    self:UpdateHotbar()
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
    local cat_info = self:GetCategoryInfo(cat)

    -- Try to stack it in a specific place
    if args.index then

        local istack = self.contents[args.index]

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

        for i = cat_info.start_index, cat_info.end_index do

            local istack = self.contents[i]

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

        for i = cat_info.start_index, cat_info.end_index do

            local istack = self.contents[i]

            if not istack then
                self.contents[i] = args.stack:Copy()
                args.stack.contents = {} -- Clear stack contents
                self:Sync({index = i, stack = self.contents[i], sync_stack = true})
                break;
            end

        end
    
    end

    if args.stack:GetAmount() > 0 then
        return args.stack
        --error("sInventory:AddStack failed: there were some items left over")
    end

end

-- Not particularly optimized but maybe I'll rewrite this later. Doesn't really matter
function sInventory:HaveEmptySpaces(category)

    local cat = category
    local cat_info = self:GetCategoryInfo(cat)

    for i = cat_info.start_index, cat_info.end_index do

        local istack = self.contents[i]

        if not istack then
            return true
        end

    end

    return false

end

function sInventory:RemoveStack(args)

    if args.index and not self.contents[args.index] then return end

    if args.index then

        -- If we are not removing the entire stack
        if args.stack:GetAmount() < self.contents[args.index]:GetAmount() then

            local split_stack = self.contents[args.index]:Split(args.stack:GetAmount())
            self:Sync({index = args.index, stack = self.contents[args.index], sync_stack = true})

            self:CheckIfStackHasOneEquippedThenUnequip(split_stack)

        else

            self:CheckIfStackHasOneEquippedThenUnequip(self.contents[args.index])

            self.contents[args.index] = nil
            stack = nil
            self:Sync({index = args.index, sync_remove = true})
            self:RemoveHotbarIndex(args.index)
            self:UpdateHotbar()

        end

    else

        for _index, _stack in pairs(self.contents) do

            if _stack.uid == args.stack.uid then
                
                self:CheckIfStackHasOneEquippedThenUnequip(self.contents[_index])

                self.contents[_index] = nil
                args.stack = nil
                self:RemoveHotbarIndex(_index)
                self:UpdateHotbar()
                self:Sync({index = _index, sync_remove = true})
                break
            end

        end

        -- If we are just subtracting items, not by uid or index
        if args.stack then


            local cat_info = self:GetCategoryInfo(args.stack:GetProperty("category"))
            local name = args.stack:GetProperty("name")
    
            for i = cat_info.start_index, cat_info.end_index do
        
                local check_stack = self.contents[i]

                if check_stack and check_stack:GetProperty("name") == name then

                    local return_stack = check_stack:RemoveStack(args.stack)

                    if check_stack:GetAmount() == 0 then
                        
                        self:CheckIfStackHasOneEquippedThenUnequip(self.contents[i])

                        self.contents[i] = nil
                        self:RemoveHotbarIndex(i)
                        self:Sync({index = i, sync_remove = true})
                    end

                    -- Got more items to remove, so keep going
                    if return_stack then
                        args.stack = return_stack
                    else -- Otherwise break, we are done

                        if self.contents[i] and self.contents[i]:GetAmount() > 0 then
                            self:Sync({index = i, sync_stack = true, stack = self.contents[i]})
                        end

                        args.stack = nil
                        break
                    end


                end
        
            end

            self:UpdateHotbar()

        end

    end

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

-- Checks to see if an inventory index is being used by the hotbar, and if so, stops using it
function sInventory:RemoveHotbarIndex(index)

    if self.contents[index] then return end

    -- Swap hotbar indices
    for hotbar_index, inventory_index in pairs(self.hotbar) do
        if inventory_index == index then
            self.hotbar[hotbar_index] = nil
        end
    end

end

function sInventory:RemoveItem(args)
    self:RemoveStack({stack = shStack({contents = {args.item}}), index = args.index})
end

function sInventory:ModifyStack(stack, index)

    self.contents[index] = stack
    self:Sync({index = index, stack = stack, sync_stack = true})

end

-- Syncs inventory to player and all modules
function sInventory:Sync(args)

    if not self.initial_sync and not args.sync_full then return end -- Don't sync anything until we do the initial sync

    self.player:SetValue("Inventory", self:GetSyncObject())

    -- Initial sync, so also equip all things that were equipped before
    if not self.initial_sync then
        for _, stack in pairs(self.contents) do
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

    if args.sync_full then
        Network:Send(self.player, "InventoryUpdated", 
            {action = "full", contents = self:GetSyncObject()})
        Network:Send(self.player, "InventoryHotbarUpdated", self.hotbar)
    elseif args.sync_stack then
        Network:Send(self.player, "InventoryUpdated", 
            {action = "update", stack = args.stack:GetSyncObject(), index = args.index})
    elseif args.sync_remove then
        Network:Send(self.player, "InventoryUpdated", 
            {action = "remove", index = args.index})
    end

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
    for i = 1, GetInventoryNumSlots() do

        local stack = self.contents[i]

        if stack then

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

        end

        str = str .. "|";
    end

    return str;

end

function sInventory:Deserialize(data)

    data = tostring(data)

    local split = splitstr2(data, "|")
    local inventory = {}

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
            inventory[index] = stack
        end


    end

    self.contents = inventory

end

function sInventory:SerializeHotbar()

    local str = ""

    for k,v in pairs(self.hotbar) do

        str = str .. tostring(k) .. "-" .. tostring(v) .. ","

    end

    return str

end

function sInventory:DeserializeHotbar(str)

    -- 1-12,2-9,3-50 // is how the hotbar is set up. First number is hotbar index, second is inventory index
    str = tostring(str)

    local split = splitstr2(str, ",")

    for k,v in pairs(split) do

        if v then

            local entry = splitstr2(v, "-")

            if entry and #entry == 2 then

                self.hotbar[tonumber(entry[1])] = tonumber(entry[2])

            end

        end

    end

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
    self.hotbar = nil
    self.initial_sync = nil
    self.steamID = nil
    self.events = nil
    self.network_events = nil
    self = nil

end

-- Only used for initial sync
function sInventory:GetSyncObject()

    local data = {}

    for k,v in pairs(self.contents) do
        data[k] = {stack = v:GetSyncObject(), index = k}
    end

    return data

end

function splitstr2(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end