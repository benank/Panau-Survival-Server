Events:Subscribe("PlayerChat", function(args)

    if not (IsTest or IsAdmin(args.player)) then return end

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

        Thread(function()
            if not Items_indexed[name].durable and not Items_indexed[name].can_equip then
                
                Inventory.AddItem({
                    player = args.player,
                    item = CreateItem({
                        name = name,
                        amount = amount
                    }):GetSyncObject()
                })

            else
                for i = 1, amount do

                    Inventory.AddItem({
                        player = args.player,
                        item = CreateItem({
                            name = name,
                            amount = 1
                        }):GetSyncObject()
                    })

                    Timer.Sleep(20)

                end
            end
            Chat:Send(args.player, "Added " .. name .. " [x" .. tostring(amount) .. "]", Color.Green)
        end)


    elseif args.text == "/box" then

        CreateLootbox({
            position = args.player:GetPosition(),
            angle = args.player:GetAngle(),
            tier = math.ceil(math.random() * 6),
            contents = {}
        })

    elseif args.text == "/badstash" and IsAdmin(args.player) then

        local current_box = args.player:GetValue("CurrentLootbox")

        if not current_box or not current_box.stash then return end
        if current_box.stash.owner_id == "SERVER" then return end

        local contents_string = ""

        for index, _stack in pairs(current_box.contents) do
            local items = {}
            for _, item in pairs(_stack.contents) do
                items[_] = shItem(item)
            end
            local stack = shStack({contents = items})
            contents_string = contents_string .. stack:ToString() .. "\n"
        end

        Events:Fire("Discord", {
            channel = "Stashes",
            content = string.format("%s [%s] removed [%s]'s stash. ID: %d\nContents: %s", 
                args.player:GetName(), tostring(args.player:GetSteamId()), current_box.stash.owner_id, current_box.stash.id, contents_string)
        })
    
        sStashes:DeleteStash({id = current_box.stash.id})

        Chat:Send(args.player, "Stash removed.", Color.Red)

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