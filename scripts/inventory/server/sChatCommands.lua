Events:Subscribe("PlayerChat", function(args)

    if not IsTest and not IsAdmin(args.player) then return end

    local split = args.text:split(" ")

    if args.text:sub(1, 5) == "/item" then

        local text = string.gsub(args.text, "/item ", "")
        if not GetLootAmount(text) then text = text .. " 1" end
        
        local name = GetLootName(text)
        local amount = GetLootAmount(text)

        if amount > 500 then
            Chat:Send(args.player, "Woah! Slow down there cowboy. You're trying to add TOO MUCH SAUCE.", Color.Red)
            return
        end

        local items = {}

        if not Items_indexed[name] then
            Chat:Send(args.player, "Failed to add " .. name .. " [x" .. amount .. "]", Color.Red)
            return
        end

        for i = 1, amount do

            Inventory.AddItem({
                player = args.player,
                item = CreateItem({
                    name = name,
                    amount = 1
                }):GetSyncObject()
            })

        end

        Chat:Send(args.player, "Added " .. name .. " [x" .. tostring(amount) .. "]", Color.Green)

    elseif args.text == "/box" then

        CreateLootbox({
            position = args.player:GetPosition(),
            angle = args.player:GetAngle(),
            tier = math.ceil(math.random() * 6),
            contents = {}
        })

    
    elseif split[1] == "/rem" and split[2] then

        local text = string.gsub(args.text, "/rem ", "")
        if not GetLootAmount(text) then text = text .. " 1" end
        
        local name = GetLootName(text)
        local amount = GetLootAmount(text)

        if amount > 100 then
            Chat:Send(args.player, "Woah! Slow down there cowboy. You're trying to remove TOO MUCH SAUCE.", Color.Red)
            return
        end

        local items = {}

        if not Items_indexed[name] then
            Chat:Send(args.player, "Failed to remove " .. name .. " [x" .. amount .. "]", Color.Red)
            return
        end

        --for i = 1, amount do

            Inventory.RemoveItem({
                player = args.player,
                item = CreateItem({
                    name = name,
                    amount = amount
                }):GetSyncObject()
            })

        --end

        Chat:Send(args.player, "Removed " .. name .. " [x" .. tostring(amount) .. "]", Color.Green)

    elseif split[1] == "/loot" and tonumber(split[2]) then

        local tier = tonumber(split[2])

        local loot = ItemGenerator:GetLoot(tier)
        print("Level " .. tostring(tier) .. " Loot")
    
        CreateLootbox({
            position = args.player:GetPosition(),
            angle = args.player:GetAngle(),
            tier = tier,
            contents = loot
        })

    end
    


end)