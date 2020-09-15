class 'sBuildItems'

function sBuildItems:__init()

    Network:Subscribe("items/CancelObjectPlacement", self, self.CancelObjectPlacement)
    Network:Subscribe("items/PlaceBuildObject", self, self.FinishObjectPlacement)

    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
end

function sBuildItems:PlaceObject(name, position, angle, player)
    -- TODO: call event to have build handle the object placement, landclaim association, etc
end

function sBuildItems:UseItem(args)

    if not ItemsConfig.build[args.item.name] then return end
    if args.player:InVehicle() then return end

    if args.player:GetValue("StuntingVehicle") then
        Chat:Send(args.player, "You cannot use this item while stunting on a vehicle!", Color.Red)
        return
    end

    Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
    args.player:SetValue("ObjectUsingItem", args)

    Network:Send(args.player, "items/StartObjectPlacement", {name = args.item.name})

end

function sBuildItems:CancelObjectPlacement(args, player)
    Inventory.OperationBlock({player = player, change = -1})
end

function sBuildItems:FinishObjectPlacement(args, player)
    Inventory.OperationBlock({player = player, change = -1})

    local player_iu = player:GetValue("ObjectUsingItem")

    if not player_iu then return end

    player:SetValue("ObjectUsingItem", nil)

    if player:InVehicle() then
        Chat:Send(player, "Cannot place objects while in a vehicle!", Color.Red)
        return
    end

    if args.position:Distance(player:GetPosition()) > 7 then
        Chat:Send(player, "Placing object failed!", Color.Red)
        return
    end

    if args.collision and DisabledPlacementCollisions[args.collision] then
        Chat:Send(player, "Placing object failed!", Color.Red)
        return
    end

    -- Now actually place the object
    Events:Fire("items/PlaceObjectInLandclaim", {
        position = args.position,
        angle = args.angle,
        player = player,
        name = player_iu.item.name,
        player_iu = player_iu
    })

end

sBuildItems = sBuildItems()