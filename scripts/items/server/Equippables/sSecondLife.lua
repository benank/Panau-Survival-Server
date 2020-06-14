Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Second Life" then return end

    args.player:SetValue("SecondLifeEquipped", args.item.equipped == true)

end)

Events:Subscribe("PlayerDeath", function(args)

    if args.reason == DamageEntity.Suicide or args.reason == DamageEntity.AdminKill then return end

    local player = args.player
    local death_pos = args.player:GetPosition()

    -- If they have a second life, don't let them die
    if player:GetValue("SecondLifeEquipped") then

        Network:Broadcast("Hitdetection/SecondLifeActivate", {position = player:GetPosition(), id = tostring(player:GetSteamId())})
        player:SetNetworkValue("Invincible", true)
        player:SetValue("StreamDistance", player:GetStreamDistance())
        player:SetStreamDistance(0)

        player:SetValue("SecondLifeActive", true)

        local item_cost = CreateItem({
            name = "Second Life",
            amount = 1
        })
        
        Inventory.RemoveItem({
            item = item_cost:GetSyncObject(),
            player = player
        })
    
        Chat:Send(player, "Second Life just prevented you from dying and has been consumed!", Color.Yellow)

        player:SetValue("RecentHealTime", Server:GetElapsedSeconds())
        player:SetValue("SecondLifeEquipped", false)

        
        Thread(function()
            while IsValid(player) and (player:GetValue("Loading") or not player:GetValue("SecondLifeSpawned")) do
                Timer.Sleep(1000)
            end

            Timer.Sleep(4000)

            if not IsValid(player) then return end

            player:SetValue("SecondLifeSpawned", false)

            Network:Broadcast("Hitdetection/SecondLifeDectivate", {position = player:GetPosition(), id = tostring(player:GetSteamId())})
            player:SetHealth(1)
            player:SetStreamDistance(player:GetValue("StreamDistance"))

            -- Give a grace period
            Timer.Sleep(5000)
            if IsValid(player) then
                player:SetNetworkValue("Invincible", false)
            end
        end)

        -- Make sure they respawn back at where they died
        local sub
        sub = Events:Subscribe("PlayerSpawn", function(args)
        
            if args.player == player then
                
                args.player:SetValue("SecondLifeSpawned", true)
                args.player:SetPosition(death_pos)

                Events:Unsubscribe(sub)
                player:SetValue("SecondLifeActive", false)
                
                return false
            end

        end)

    end

end)