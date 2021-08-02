class "sHacker"

function sHacker:__init()
    self.difficulties = {
        [22] = 5, -- LockboxX
        [21] = 4, -- Lockbox
        [13] = 3, -- Locked stash
        [14] = 2 -- Prox alarm
    }

    self.perks = {
        [102] = {[1] = 1, [2] = 0.1},
        [169] = {[1] = 1, [2] = 0.1},
        [205] = {[1] = 1, [2] = 0.1}
    }

    Network:Subscribe("items/CompleteItemUsage", self, self.UseItem)

    Network:Subscribe("items/HackComplete", self, self.HackComplete)
    Network:Subscribe("items/FailHack", self, self.FailHack)
    
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function sHacker:ModuleUnload()
    Events:Fire("Drones/RemoveDronesInGroup", {group = "secret"}) 
end

function sHacker:GetPerkMods(player)
    local perks = player:GetValue("Perks")

    if not perks then
        return
    end

    local perk_mods = {[1] = 0, [2] = 0}

    for perk_id, perk_mod_data in pairs(self.perks) do
        local choice = perks.unlocked_perks[perk_id]
        if choice and perk_mod_data[choice] then
            perk_mods[choice] = perk_mods[choice] + perk_mod_data[choice]
        end
    end

    return perk_mods
end

function sHacker:FailHack(args, player)
    if not player:GetValue("CurrentlyHacking") then
        return
    end
    
    if player:GetValue("CurrentlyHackingSAM") then
        -- Spawn drone on failed hack
        local sub
        sub =
            Events:Subscribe(
            "sams/GetSAMInfo_" .. tostring(player:GetValue("CurrentlyHackingSAM")),
            function(sam)
                local pos = sam.position + Vector3.Up * 4 + Vector3.Up * 4 * math.random()
                Events:Fire("Drones/SpawnDrone", {
                    level = sam.level,
                    static = true,
                    position = pos,
                    tether_position = pos,
                    tether_range = 100,
                    config = {
                        attack_on_sight = true
                    },
                    group = "sam"
                })
                Events:Unsubscribe(sub)
            end)
            
        Events:Fire("sams/GetSAMInfo", {id = player:GetValue("CurrentlyHackingSAM")})
    end
    
    -- Spawn drone if failed hack on a lockbox
    if player:GetValue("CurrentLootbox") then
        local current_box = player:GetValue("CurrentLootbox")
        if not current_box.stash then -- Secret box if not stash
            if math.random() < 0.5 then
                Events:Fire("Drones/SpawnDrone", {
                    level = math.random(25, 75),
                    static = true,
                    position = player:GetPosition() + Vector3.Up * 1,
                    tether_position = player:GetPosition(),
                    tether_range = 200,
                    config = {
                        attack_on_sight = true
                    },
                    group = "secret"
                }) 
            end
        end
    end
        
    player:SetValue("CurrentlyHackingSAM", nil)
    player:SetValue("CurrentlyHacking", false)
    
    Events:Fire("items/FailHack", {
        player = player
    })

    Inventory.OperationBlock({player = player, change = -1})
end

function sHacker:HackComplete(args, player)
    if not player:GetValue("CurrentlyHacking") then
        return
    end
    if player:GetValue("CurrentLootbox") then
        local current_box = player:GetValue("CurrentLootbox")
        if current_box.stash then
            Events:Fire(
                "items/HackComplete",
                {
                    player = player,
                    stash_id = current_box.stash.id,
                    tier = current_box.tier
                }
            )
        else
            Events:Fire(
                "items/LockboxHackComplete",
                {
                    player = player,
                    lootbox_id = current_box.uid,
                    tier = current_box.tier
                }
            )
        end
    elseif player:GetValue("CurrentlyHackingSAM") then
        Events:Fire(
            "items/SAMHackComplete",
            {
                player = player,
                sam_id = player:GetValue("CurrentlyHackingSAM"),
                tier = "SAM"
            }
        )
        player:SetValue("CurrentlyHackingSAM", nil)
    elseif player:GetValue("CurrentlyHackingVehicle") then
        Events:Fire(
            "items/VehicleHackComplete",
            {
                player = player,
                vehicle_id = player:GetValue("CurrentlyHackingVehicle"),
                tier = "Vehicle"
            }
        )
        player:SetValue("CurrentlyHackingVehicle", nil)
    end

    player:SetValue("CurrentlyHacking", false)

    Chat:Send(player, "Hack successful!", Color.Yellow)

    Inventory.OperationBlock({player = player, change = -1})
end

local hackable_tiers = {
    [13] = true, -- Locked stash
    [14] = true -- Prox alarm
}

function sHacker:UseItem(args, player)
    local player_iu = player:GetValue("ItemUse")
    if
        player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed and
            (player_iu.item.name == "Hacker" or player_iu.item.name == "Master Hacker") and
            not player:GetValue("CurrentlyHacking")
     then
        if args.forward_ray.sam_id then
            self:HackSAM(args, player)
        elseif args.forward_ray.vehicle_id then
            self:HackVehicle(args, player)
        else
            self:HackStash(args, player)
        end
    end
end

function sHacker:CanHackBox(player, current_box)
    
    if not current_box then return false end
    if not current_box.tier then return false end
    
    if current_box.locked then return true end
    if not hackable_tiers[current_box.tier] then return false end
    if not self.difficulties[current_box.tier] then return false end
    
    if current_box.stash then
                   
        if current_box.stash.access_mode == 1 or
        current_box.stash.owner_id == tostring(player:GetSteamId()) or
        AreFriends(player, current_box.stash.owner_id) then
            return false 
        end
            
    end
    
end

function sHacker:HackStash(args, player)
    local player_iu = player:GetValue("ItemUse")
    local current_box = player:GetValue("CurrentLootbox")
    
    if not self:CanHackBox(player, current_box) then
        Chat:Send(player, "You must open a hackable object first!", Color.Red)
        return
    end

    if not current_box.tier or not self.difficulties[current_box.tier] then
        Chat:Send(player, "This object cannot be hacked.", Color.Red)
        return
    end

    local perk_mods = self:GetPerkMods(player)

    local chance_to_keep = math.random()

    if chance_to_keep <= perk_mods[2] then
        Chat:Send(player, "Your Hacker was kept after using it, thanks to your perks!", Color(0, 220, 0))
    else
        Inventory.RemoveItem(
            {
                item = player_iu.item,
                index = player_iu.index,
                player = player
            }
        )
    end

    Inventory.OperationBlock({player = player, change = 1})
    player:SetValue("CurrentlyHacking", true)

    local send_data = {difficulty = self.difficulties[current_box.tier]}

    if player_iu.item.name == "Master Hacker" then
        send_data.time = 20 -- Double time for Master Hacker
    else
        send_data.time = 10
    end

    send_data.time = send_data.time + perk_mods[1]

    Network:Send(player, "items/StartHack", send_data)
end

function sHacker:HackVehicle(args, player)
     
    local player_iu = player:GetValue("ItemUse")
    local steam_id = tostring(player:GetSteamId())
    local player = player
    local vehicle = Vehicle.GetById(args.forward_ray.vehicle_id)
    
    if not IsValid(vehicle) then return end
    if vehicle:GetHealth() <= 0.2 then return end
    if vehicle:GetPosition():Distance(player:GetPosition()) > 15 then return end
    
    local vehicle_data = vehicle:GetValue("VehicleData")
    
    -- if steam_id == vehicle_data.owner_steamid then
    --     Chat:Send(player, "Hacking failed: You own this vehicle.", Color.Red)
    --     return
    -- end
    
    -- if AreFriends(player, vehicle_data.owner_steamid) then
    --     Chat:Send(player, "Hacking failed: You are friends with this vehicle\'s owner.", Color.Red)
    --     return
    -- end
    
    local perk_mods = self:GetPerkMods(player)

    local chance_to_keep = math.random()

    if chance_to_keep <= perk_mods[2] then
        Chat:Send(player, "Your Hacker was kept after using it, thanks to your perks!", Color(0, 220, 0))
    else
        Inventory.RemoveItem(
            {
                item = player_iu.item,
                index = player_iu.index,
                player = player
            }
        )
    end

    Inventory.OperationBlock({player = player, change = 1})
    player:SetValue("CurrentlyHacking", true)
    player:SetValue("CurrentlyHackingVehicle", vehicle:GetId())
    local difficulty = self.difficulties[13]

    local send_data = {difficulty = difficulty}

    if player_iu.item.name == "Master Hacker" then
        send_data.time = 20 -- Double time for Master Hacker
    else
        send_data.time = 10
    end

    send_data.time = send_data.time + perk_mods[1]

    Network:Send(player, "items/StartHack", send_data)
    
end

function sHacker:HackSAM(args, player)
    -- forward_ray.sam_id
    local player_iu = player:GetValue("ItemUse")
    local steam_id = tostring(player:GetSteamId())
    local player = player

    local sub
    sub =
        Events:Subscribe(
        "sams/GetSAMInfo_" .. tostring(args.forward_ray.sam_id),
        function(sam)
            
            if not sam.position then return end -- Invalid SAM
            if not IsValid(player) then return end
            
            if AreFriends(player, sam.hacked_owner) then
                Chat:Send(player, "This SAM is already friendly to you.", Color.Red)
                return
            end
            
            local perk_mods = self:GetPerkMods(player)

            local chance_to_keep = math.random()

            if chance_to_keep <= perk_mods[2] then
                Chat:Send(player, "Your Hacker was kept after using it, thanks to your perks!", Color(0, 220, 0))
            else
                Inventory.RemoveItem(
                    {
                        item = player_iu.item,
                        index = player_iu.index,
                        player = player
                    }
                )
            end

            Inventory.OperationBlock({player = player, change = 1})
            player:SetValue("CurrentlyHacking", true)
            player:SetValue("CurrentlyHackingSAM", sam.id)
            local difficulty = self.difficulties[13]

            local send_data = {difficulty = difficulty}

            if player_iu.item.name == "Master Hacker" then
                send_data.time = 20 -- Double time for Master Hacker
            else
                send_data.time = 10
            end

            send_data.time = send_data.time + perk_mods[1]

            Network:Send(player, "items/StartHack", send_data)
            Events:Unsubscribe(sub)
            
        end
    )
    
    Events:Fire("sams/GetSAMInfo", {id = args.forward_ray.sam_id})

end

sHacker = sHacker()
