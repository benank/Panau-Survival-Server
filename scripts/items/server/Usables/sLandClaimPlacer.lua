class 'sLandClaimPlacer'

function sLandClaimPlacer:__init()

    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Network:Subscribe("items/CancelLandclaimPlacement", self, self.CancelLandclaimPlacement)

end

function sLandClaimPlacer:CancelLandclaimPlacement(args, player)

    if not player:GetValue("LandclaimUsingItem") then return end

    player:SetValue("LandclaimUsingItem", nil)
    Inventory.OperationBlock({player = player, change = -1})

end

function sLandClaimPlacer:UseItem(args)

    if args.item.name ~= "LandClaim" then return end
    if args.player:InVehicle() then return end

    if not args.item.custom_data.size then return end

    if args.player:GetValue("StuntingVehicle") then
        Chat:Send(args.player, "You cannot use this item while stunting on a vehicle!", Color.Red)
        return
    end

    Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
    args.player:SetValue("LandclaimUsingItem", args)

    Network:Send(args.player, "items/StartLandclaimPlacement", {size = tonumber(args.item.custom_data.size)})

end

sLandClaimPlacer = sLandClaimPlacer()