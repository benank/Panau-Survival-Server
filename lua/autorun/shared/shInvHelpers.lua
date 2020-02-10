if Client then

    Inventory.contents = {}

    Inventory.Update = function(args)

        if args.action == "full" then

            local contents = {}

            -- Create new shItem and shStack instances for the client
            for k,v in ipairs(args.contents) do

                local items = {}

                for i, j in ipairs(v.stack.contents) do
                    items[i] = shItem(j)
                end

                contents[k] = shStack({contents = items, uid = v.stack.uid})

            end

            Inventory.contents = contents

        elseif args.action == "update" then

            local items = {}

            for i, j in ipairs(args.stack.contents) do
                items[i] = shItem(j)
            end

            Inventory.contents[args.index] = shStack({contents = items, uid = args.stack.uid})

        elseif args.action == "remove" then

            Inventory.contents[args.index] = nil

        end

    end

    Events:Subscribe("InventoryUpdated", function(args)

        Inventory.Update(args)

    end)

    Inventory.print = function()

        print("Printing Inventory contents")

        for k, stack in pairs(Inventory.contents) do

            print("stack " .. k)
            for i, item in pairs(stack.contents) do

                print("item " .. i .. " " .. item:ToString())

            end

        end

    end

    Inventory.GetNumLockpicks = function()

        local count = 0
        for index, stack in pairs(Inventory.contents) do
            if stack:GetProperty("name") == "LockPick" then
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
        
        local contents_array = args.player:GetValue("Inventory")
        local contents = {}
        
        -- Create new shItem and shStack instances for the client
        for k,v in pairs(contents_array) do

            local items = {}

            for i, j in ipairs(v.stack.contents) do
                items[i] = shItem(j)
            end

            contents[k] = shStack({contents = items, uid = v.stack.uid})

        end

        return contents
    
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

        if args.check_uid then
            for k, stack in pairs(contents) do
                for i, _item in pairs(stack.contents) do
                    if _item.uid == item.uid then
                        return true
                    end
                end
            end
        else
            for k, stack in pairs(contents) do
                for i, _item in pairs(stack.contents) do
                    if _item.name == item.name then
                        return true
                    end
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
        for index, stack in pairs(inv) do
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

        print("Inventory contents of " .. args.player)

        for k, stack in pairs(contents) do

            print("stack " .. k)
            for i, item in pairs(stack.contents) do

                print("item " .. i .. " " .. item:ToString())

            end

        end

    end

end
