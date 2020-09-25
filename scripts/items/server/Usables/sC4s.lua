class 'sC4s'

function sC4s:__init()

    self.wnos = {}

    self.network_subs = {}

    Network:Subscribe("items/CancelC4Placement", self, self.CancelC4Placement)
    Network:Subscribe("items/PlaceC4", self, self.FinishC4Placement)
    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("InventoryUpdated", self, self.InventoryUpdated)
    Events:Subscribe("ItemUse/CancelUsage", self, self.ItemUseCancelUsage)

    
    -- Update attached C4s every second so they are at least nearby the entity
    Timer.SetInterval(1000, function()
        for id, wno in pairs(self.wnos) do

            local attach_entity = wno:GetValue("AttachEntity")
            if IsValid(attach_entity) then
                wno:SetPosition(wno:GetValue("AttachEntity"):GetPosition())

                if attach_entity:GetHealth() <= 0 then
                    self:DestroyC4({id = id})
                end

            elseif attach_entity and not IsValid(attach_entity) then
                -- Attach entity not valid, remove C4

                if IsValid(wno:GetValue("Owner")) then

                    -- Set custom data with wno id
                    Inventory.ModifyItemCustomData({
                        player = wno:GetValue("Owner"),
                        item = wno:GetValue("Item"),
                        custom_data = {}
                    })

                end

                self:RemoveC4(id)
                
            end
        end

    end)

end

function sC4s:ItemUseCancelUsage(args)

    if self.network_subs[tostring(args.player:GetSteamId())] then
        Network:Unsubscribe(self.network_subs[tostring(args.player:GetSteamId())])
        self.network_subs[tostring(args.player:GetSteamId())] = nil
    end

    local player_iu = args.player:GetValue("ItemUse")

    if not player_iu or player_iu.item.name ~= "C4" then return end

    Chat:Send(args.player, "Placing C4 failed!", Color.Red)

end

function sC4s:InventoryUpdated(args)

    -- Check if they dropped a placed c4 and remove it if so

    if not IsValid(args.player) then return end

    local player_placed_c4s = {}
    local player_id = tostring(args.player:GetSteamId())

    for id, wno in pairs(self.wnos) do
        if wno:GetValue("owner_id") == player_id then
            player_placed_c4s[id] = true
        end
    end

    -- Did not place any c4, so return
    if count_table(player_placed_c4s) == 0 then return end

    local inv = Inventory.Get({player = args.player})

    local cat = Items_indexed["C4"].category

    for index, stack in pairs(inv[cat]) do
        for item_index, item in pairs(stack.contents) do
            if item.name == "C4" and item.custom_data.id and player_placed_c4s[item.custom_data.id] then
                -- Player still has C4 so don't remove
                player_placed_c4s[item.custom_data.id] = nil
            end
        end
    end

    for id, _ in pairs(player_placed_c4s) do
        self:RemoveC4(id)
    end

end

function sC4s:ModuleUnload(args)
    
    for id, wno in pairs(self.wnos) do
        wno:Remove()
    end

end

function sC4s:PlayerQuit(args)

    -- Remove all active c4s if player disconnects
    local steamid = tostring(args.player:GetSteamId())

    for id, wno in pairs(self.wnos) do
        if wno:GetValue("owner_id") == steamid then
            wno:Remove()
            self.wnos[id] = nil
        end
    end

end

function sC4s:RemoveC4(id)
    
    local c4 = self.wnos[id]

    if not c4 then return end

    c4:Remove()
    self.wnos[id] = nil

end

function sC4s:ItemExplode(args)

    for id, wno in pairs(self.wnos) do
        if wno:GetPosition():Distance(args.position) < args.radius then
            self:DestroyC4({id = wno:GetId(), detonation_source_id = args.player and tostring(args.player:GetSteamId()) or nil})
        end
    end

end

function sC4s:DestroyC4(args, player)
    if not args.id or not self.wnos[args.id] then return end

    sItemExplodeManager:Add(function()
    
    local c4 = self.wnos[args.id]

    if not c4 then return end

    local pos = c4:GetPosition()

    local owner_id = c4:GetValue("owner_id")

    if not self.sz_config then
        self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()
    end

    -- If they are within sz radius * 2, we don't let them detonate that close
    if pos:Distance(self.sz_config.safezone.position) > self.sz_config.safezone.radius * 2 then
        Network:Broadcast("items/C4Explode", {position = pos, id = c4:GetId(), owner_id = owner_id})
    end

    local lootbox_id = c4:GetValue("LootboxId")
    if lootbox_id then
        Events:Fire("items/C4DetonateOnStash", {
            lootbox_uid = lootbox_id,
            player = IsValid(c4:GetValue("Owner")) and c4:GetValue("Owner") or player
        })
    end

    Inventory.RemoveItem({
        item = c4:GetValue("Item"),
        player = c4:GetValue("Owner")
    })

    self:RemoveC4(args.id)

    Events:Fire("items/ItemExplode", {
        position = pos,
        radius = 30,
        player = player,
        owner_id = owner_id,
        type = DamageEntity.C4,
        detonation_source_id = args.detonation_source_id or (IsValid(player) and tostring(player:GetSteamId() or nil))
    })

    end)

end

function sC4s:UseItem(args)

    if args.item.name ~= "C4" then return end

    if args.item.custom_data.id then
        -- Already placed, trigger it

        self:DestroyC4({
            id = args.item.custom_data.id
        }, args.player)

        Network:Send(args.player, "items/PlayC4TriggerAnimation")

    elseif not args.player:InVehicle() then

        Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
        args.player:SetValue("C4UsingItem", args)

        Network:Send(args.player, "items/StartC4Placement")

    end

end


function sC4s:CancelC4Placement(args, player)
    Inventory.OperationBlock({player = player, change = -1})
end

function sC4s:PlaceC4(args, item)

    local c4 = WorldNetworkObject.Create(args.position, {
        enabled = false
    })
    c4:SetAngle(args.angle)

    c4:SetNetworkValue("owner_id", tostring(args.player:GetSteamId()))
    c4:SetNetworkValue("AttachEntity", args.forward_ray.entity)
    c4:SetNetworkValue("Angle", args.angle)
    c4:SetNetworkValue("Values", args.values)
    c4:SetValue("Owner", args.player)
    c4:SetValue("Item", item)
    c4:SetValue("LootboxId", args.lootbox_uid)

    self.wnos[c4:GetId()] = c4

    c4:SetEnabled(true)

    return c4:GetId()

end

function sC4s:TryPlaceC4(args, player)

    if not IsValid(player) then return end

    local c4_using = player:GetValue("C4UsingItem")
    
    if c4_using then

        c4_using.delayed = true
        sItemUse:InventoryUseItem(c4_using)

        player:SetValue("C4UsingItem", nil)

        if self.network_subs[tostring(args.player:GetSteamId())] then
            Network:Unsubscribe(self.network_subs[tostring(args.player:GetSteamId())])
            self.network_subs[tostring(args.player:GetSteamId())] = nil
        end
        
        local sub
        sub = Network:Subscribe("items/CompleteItemUsage", function(_, _player)
        
            if not IsValid(player) or not IsValid(_player) or player ~= _player then return end

            local player_iu = player:GetValue("ItemUse")

            if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed and 
            player_iu.item.name == "C4" then

                local player_pos = player:GetPosition()
                
                if player:GetPosition():Distance(args.position) > 7 then
                    Chat:Send(player, "Placing C4 failed!", Color.Red)
                    return
                end

                if IsValid(args.forward_ray.entity) and args.forward_ray.entity:GetPosition():Distance(player_pos) > 7 then
                    Chat:Send(player, "Placing C4 failed!", Color.Red)
                    return
                end

                args.player = player

                -- Now actually place the claymore
                local id = self:PlaceC4(args, c4_using.item)

                -- Set custom data with wno id
                Inventory.ModifyItemCustomData({
                    player = player,
                    item = c4_using.item,
                    custom_data = {
                        id = id
                    }
                })

            end

            Network:Unsubscribe(sub)
            self.network_subs[tostring(player:GetSteamId())] = nil

        end)
    
        self.network_subs[tostring(player:GetSteamId())] = sub

    end


end

function sC4s:FinishC4Placement(args, player)
    Inventory.OperationBlock({player = player, change = -1})

    if player:InVehicle() then
        Chat:Send(player, "Cannot place C4 while in a vehicle!", Color.Red)
        return
    end

    if args.position:Distance(player:GetPosition()) > 7 then
        Chat:Send(player, "Placing C4 failed!", Color.Red)
        return
    end

    local BlacklistedAreas = SharedObject.GetByName("BlacklistedAreas"):GetValues().blacklist

    for _, area in pairs(BlacklistedAreas) do
        if player:GetPosition():Distance(area.pos) < area.size then
            Chat:Send(player, "You cannot place C4 here!", Color.Red)
            return
        end
    end

    local ModelChangeAreas = SharedObject.GetByName("ModelLocations"):GetValues()

    for _, area in pairs(ModelChangeAreas) do
        if player:GetPosition():Distance(area.pos) < 10 then
            Chat:Send(player, "You cannot place C4 here!", Color.Red)
            return
        end
    end

    local sub = nil
    sub = Events:Subscribe("IsTooCloseToLootCheck"..tostring(player:GetSteamId()), function(args)
    
        Events:Unsubscribe(sub)
        sub = nil

        if args.too_close then

            Chat:Send(player, "Cannot place C4 too close to loot!", Color.Red)
            return

        end

        self:TryPlaceC4(args, args.player)
        
    end)
    
    args.player = player
    Events:Fire("CheckIsTooCloseToLoot", args)

end


sC4s = sC4s()