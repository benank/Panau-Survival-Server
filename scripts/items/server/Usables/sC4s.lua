class 'sC4s'

function sC4s:__init()

    self.wnos = {}

    Network:Subscribe("items/CancelC4Placement", self, self.CancelC4Placement)
    Network:Subscribe("items/PlaceC4", self, self.FinishC4Placement)
    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

    
    -- Update attached C4s every second so they are at least nearby the entity
    local func = coroutine.wrap(function()
        while true do
            Timer.Sleep(1000)

            for id, wno in pairs(self.wnos) do

                local attach_entity = wno:GetValue("AttachEntity")
                if IsValid(attach_entity) then
                    wno:SetPosition(wno:GetValue("AttachEntity"):GetPosition())

                    if attach_entity:GetHealth() <= 0 then
                        self:DestroyC4({id = id})
                    end

                elseif not IsValid(attach_entity) then
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

        end
    end)()

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
            self:DestroyC4({id = wno:GetId()})
        end
    end

end

function sC4s:DestroyC4(args, player)
    if not args.id or not self.wnos[args.id] then return end

    local c4 = self.wnos[args.id]

    if not c4 then return end

    local pos = c4:GetPosition()

    Network:Broadcast("items/C4Explode", {position = pos, id = c4.id})

    Inventory.RemoveItem({
        item = c4:GetValue("Item"),
        player = c4:GetValue("Owner")
    })

    self:RemoveC4(args.id)

    Events:Fire("items/ItemExplode", {
        position = pos,
        radius = 30,
        player = player
    })

end

function sC4s:UseItem(args)

    if args.item.name ~= "C4" then return end

    -- TOOD: check if already placed. If placed, then explode
    if args.item.custom_data.id then
        -- Already placed, trigger it

        self:DestroyC4({
            id = args.item.custom_data.id
        }, args.player)

    else

        Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
        args.player:SetValue("C4UsingItem", args)

        Network:Send(args.player, "items/StartC4Placement")

    end

end


function sC4s:CancelC4Placement(args, player)
    Inventory.OperationBlock({player = player, change = -1})
end

function sC4s:PlaceC4(position, angle, player, entity, values, item)

    local c4 = WorldNetworkObject.Create(position, {
        enabled = false
    })
    c4:SetAngle(angle)

    c4:SetNetworkValue("owner_id", tostring(player:GetSteamId()))
    c4:SetNetworkValue("AttachEntity", entity)
    c4:SetNetworkValue("Angle", angle)
    c4:SetNetworkValue("Values", values)
    c4:SetValue("Owner", player)
    c4:SetValue("Item", item)

    self.wnos[c4:GetId()] = c4

    c4:SetEnabled(true)

    return c4:GetId()

end

function sC4s:TryPlaceC4(args, player)

    if not IsValid(player) then return end

    local c4_using = player:GetValue("C4UsingItem")

    if c4_using then

        -- Now actually place the claymore
        local id = self:PlaceC4(args.position, args.angle, player, args.forward_ray.entity, args.values, c4_using.item)

        -- Set custom data with wno id
        Inventory.ModifyItemCustomData({
            player = player,
            item = c4_using.item,
            custom_data = {
                id = id
            }
        })

        player:SetValue("C4UsingItem", nil)

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

    if not self.sz_config then
        self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()
    end

    -- If they are within sz radius * 2, we don't let them place that close
    if player:GetPosition():Distance(self.sz_config.safezone.position) < self.sz_config.safezone.radius * 2 then
        Chat:Send(player, "Cannot place C4 while near the safezone!", Color.Red)
        return
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