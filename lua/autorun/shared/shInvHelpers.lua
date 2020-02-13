if Client then

    Inventory.contents = {}

    Inventory.Update = function(args)

        if args.action == "full" then

            local contents = {}

            -- Create new shItem and shStack instances for the client (each module does this)
            for category, _ in pairs(args.data.contents) do
                contents[category] = {}
                for index, v in pairs(args.data.contents[category]) do
                    local items = {}

                    for i, j in ipairs(v.stack.contents) do
                        items[i] = shItem(j)
                    end

                    contents[category][index] = shStack({contents = items, uid = v.stack.uid})
                end

            end

            Inventory.contents = contents
            Inventory.slots = args.data.slots

        elseif args.action == "update" then

            local items = {}

            for i, j in ipairs(args.stack.contents) do
                items[i] = shItem(j)
            end

            Inventory.contents[args.cat][args.index] = shStack({contents = items, uid = args.stack.uid})

        elseif args.action == "remove" then

            Inventory.contents[args.cat][args.index] = nil

        elseif args.action == "cat" then

            local contents = {}

            -- Create new shItem and shStack instances for the client (each module does this)
            for index, v in pairs(args.data.contents) do
                local items = {}

                for i, j in ipairs(v.stack.contents) do
                    items[i] = shItem(j)
                end

                contents[index] = shStack({contents = items, uid = v.stack.uid})
            end

            Inventory.contents[args.cat] = contents
            Inventory.slots[args.cat] = args.data.slots

        elseif args.action == "slots" then

            Inventory.slots = args.slots

        end

    end

    Events:Subscribe("InventoryUpdated", function(args)
        Inventory.Update(args)
    end)

    Inventory.print = function()

        print("Printing Inventory contents")

        for cat, _ in pairs(Inventory.contents) do
            print("cat " .. cat)
            for _, stack in pairs(Inventory.contents[cat]) do
                print("stack " .. k)
                for i, item in pairs(stack.contents) do

                    print("item " .. i .. " " .. item:ToString())

                end
            end

        end

    end

    Inventory.GetNumLockpicks = function()

        local count = 0
        for _, stack in pairs(Inventory.contents["Supplies"]) do
            if stack:GetProperty("name") == "Lockpick" then
                count = count + stack:GetAmount()
            end
        end
    
        return count
        
    end


elseif Server then

    Inventory.Get = function(args)
    
        if not IsValid(args.player) then
            error("Failed to Inventory.Get because args.player was invalid")
            return
        end
        
        local contents_array = args.player:GetValue("Inventory").contents
        local contents = {}

        -- Create new shItem and shStack instances for the client
        for category, _ in pairs(contents_array) do
            contents[category] = {}
            for index, v in pairs(contents_array[category]) do
                local items = {}

                for i, j in ipairs(v.stack.contents) do
                    items[i] = shItem(j)
                end

                contents[category][index] = shStack({contents = items, uid = v.stack.uid})
            end

        end

        return contents
    
    end

    Inventory.GetSlotsInCategory = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.GetSlotsInCategory because args.player was invalid")
            return
        end

        local slots = args.player:GetValue("Inventory").slots

        assert(args.cat ~= nil, "Failed to Inventory.GetSlotsInCategory because args.cat was invalid")
        assert(slots[args.cat] ~= nil, "Failed to Inventory.GetSlotsInCategory because slots[args.cat] was invalid")

        return slots[args.cat]

    end

    Inventory.AddStack = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.AddStack because args.player was invalid")
            return
        end

        if not args.stack then
            error("Failed to Inventory.AddStack because args.stack was invalid")
            return
        end

        Events:Fire("Inventory.AddStack-"..tostring(args.player:GetSteamId().id), args)

    end

    Inventory.RemoveStack = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.RemoveStack because args.player was invalid")
            return
        end

        if not args.stack then
            error("Failed to Inventory.RemoveStack because args.stack was invalid")
            return
        end

        Events:Fire("Inventory.RemoveStack-"..tostring(args.player:GetSteamId().id), args)

    end

    Inventory.RemoveItem = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.RemoveItem because args.player was invalid")
            return
        end

        if not args.item then
            error("Failed to Inventory.RemoveItem because args.item was invalid")
            return
        end

        Events:Fire("Inventory.RemoveItem-"..tostring(args.player:GetSteamId().id), args)

    end

    Inventory.AddItem = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.AddItem because args.player was invalid")
            return
        end

        if not args.item then
            error("Failed to Inventory.AddItem because args.item was invalid")
            return
        end

        Events:Fire("Inventory.AddItem-"..tostring(args.player:GetSteamId().id), args)

    end

    -- ONLY USED FOR SINGULAR ITEMS
    Inventory.HasItem = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.HasItem because args.player was invalid")
            return
        end

        if not args.item then
            error("Failed to Inventory.HasItem because args.item was invalid")
            return
        end

        local item = shItem(args.item)
        local contents = Inventory.Get({player = args.player})

        for index, stack in pairs(contents[item.category]) do
            for i, _item in pairs(stack.contents) do
                if (args.check_uid and _item.uid == item.uid) -- If we are checking for a SPECIFIC item
                or (not args.check_uid and _item.name == item.name) then -- If we are checking for any item of a type
                    return true
                end
            end
        end

        return false

    end

    Inventory.ModifyStack = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.ModifyStack because args.player was invalid")
            return
        end

        if not args.stack then
            error("Failed to Inventory.ModifyStack because args.stack was invalid")
            return
        end

        if not args.index then
            error("Failed to Inventory.ModifyStack because args.index was invalid")
            return
        end

        Events:Fire("Inventory.ModifyStack-"..tostring(args.player:GetSteamId().id), args)

    end

    Inventory.ModifyDurability = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.ModifyDurability because args.player was invalid")
            return
        end

        if not args.item then
            error("Failed to Inventory.ModifyDurability because args.item was invalid")
            return
        end

        Events:Fire("Inventory.ModifyDurability-"..tostring(args.player:GetSteamId().id), args)

    end

    Inventory.OperationBlock = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.OperationBlock because args.player was invalid")
            return
        end

        if not args.change then
            error("Failed to Inventory.OperationBlock because args.change was invalid")
            return
        end

        Events:Fire("Inventory.OperationBlock-"..tostring(args.player:GetSteamId().id), args)

    end

    Inventory.GetNumLockpicks = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.GetNumLockpicks because args.player was invalid")
            return
        end

        local inv = Inventory.Get({player = args.player})
        if not inv then return end
    
        local count = 0
        for index, stack in pairs(inv["Supplies"]) do
            if stack:GetProperty("name") == "Lockpick" then
                count = count + stack:GetAmount()
            end
        end
    
        return count
        
    end

    Inventory.print = function(args)

        if not IsValid(args.player) then
            error("Failed to Inventory.print because args.player was invalid")
            return
        end

        local contents = Inventory.Get(args)

        print("Inventory contents of " .. args.player:GetName())

        for cat, _ in pairs(contents) do
            print("cat " .. cat)
            for _, stack in pairs(contents[cat]) do
                print("stack " .. _)
                for i, item in pairs(stack.contents) do

                    print("item " .. i .. " " .. item:ToString())

                end
            end

        end

    end

end
