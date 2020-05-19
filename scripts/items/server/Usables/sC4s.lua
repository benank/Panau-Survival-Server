class 'sC4s'

function sC4s:__init()

    self.wnos = {}

    Network:Subscribe("items/CancelC4Placement", self, self.CancelC4Placement)
    Network:Subscribe("items/PlaceC4", self, self.FinishC4Placement)
    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)

    
    -- Update attached C4s every second so they are at least nearby the entity
    local func = coroutine.wrap(function()
        while true do
            Timer.Sleep(1000)

            for id, wno in pairs(self.wnos) do

                local attach_entity = wno:GetValue("AttachEntity")
                if IsValid(attach_entity) then
                    wno:SetPosition(wno:GetValue("AttachEntity"):GetPosition())
                elseif attach_entity then
                    -- Attach entity not valid, remove C4
                    self:RemoveC4(id)
                end

            end

        end
    end)()

end

function sC4s:RemoveC4(id)
    
    local c4 = self.wnos[id]

    if not c4 then return end

    c4:Remove()
    self.wnos[id] = nil

    -- TODO: restore customer data c4 in player inventory if they are online

end

function sC4s:ItemExplode(args)

    for id, wno in pairs(self.wnos) do
        if wno.position:Distance(args.position) < args.radius then
            self:DestroyC4({id = wno:GetId()}, args.player)
        end
    end

end

function sC4s:DestroyC4(args, player)
    if not args.id or not self.wnos[args.id] then return end

    local c4 = self.wnos[args.id]

    if c4:GetValue("Exploded") then return end

    local pos = c4:GetPosition()

    Network:Send(player, "items/C4Explode", {position = pos, id = c4.id, owner_id = c4.owner_id})
    Network:SendNearby(player, "items/C4Explode", {position = pos, id = c4.id, owner_id = c4.owner_id})

    self:RemoveC4(args.id)

    Events:Fire("items/ItemExplode", {
        position = pos,
        radius = 50,
        player = player
    })

end

function sC4s:UseItem(args)

    if args.item.name ~= "C4" then return end

    -- TOOD: check if already placed. If placed, then explode

    Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
    args.player:SetValue("C4UsingItem", args)

    Network:Send(args.player, "items/StartC4Placement")

end


function sC4s:CancelC4Placement(args, player)
    Inventory.OperationBlock({player = player, change = -1})
end

function sC4s:TryPlaceC4(args, player)

    local player_iu = player:GetValue("C4UsingItem")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name]
        and player_iu.item.name == "C4" then

        -- TODO: set custom data with WNO id

        -- Now actually place the claymore
        self:PlaceC4(args.position, args.angle, player)

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