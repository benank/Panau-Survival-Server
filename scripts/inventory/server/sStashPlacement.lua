class 'sStashPlacement'

local StashNameToType = 
{
    ["Barrel Stash"] = Lootbox.Types.BarrelStash,
    ["Garbage Stash"] = Lootbox.Types.GarbageStash,
    ["Locked Stash"] = Lootbox.Types.LockedStash,
}

function sStashPlacement:__init()

    Events:Subscribe("Inventory/UseItem", self, self.UseItem)

    Network:Subscribe("items/CancelStashPlacement", self, self.CancelStashPlacement)
    Network:Subscribe("items/PlaceStash", self, self.PlaceStash)
    
end

function sStashPlacement:TryPlaceStash(args, player)

    local player_iu = player:GetValue("StashUsingItem")

    if player_iu.item and StashNameToType[player_iu.item.name] then

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        -- Now actually place the stash
        sStashes:PlaceStash(args.position, args.angle, player)

    end


end

function sStashPlacement:PlaceStash(args, player)
    if not args.position or not args.angle then return end

    if player:InVehicle() then
        Chat:Send(player, "Cannot place stashes while in a vehicle!", Color.Red)
        return
    end

    if args.position:Distance(player:GetPosition()) > 7 then
        Chat:Send(player, "Placing stash failed!", Color.Red)
        return
    end

    -- If they are within sz radius * 2, we don't let them place that close
    if player:GetPosition():Distance(self.sz_config.safezone.position) < self.sz_config.safezone.radius * 2 then
        Chat:Send(player, "Cannot place stashes while near the safezone!", Color.Red)
        return
    end

    self:TryPlaceStash(args, player)

end

function sStashPlacement:CancelStashPlacement(args, player)
    Inventory.OperationBlock({player = player, change = -1})
end

function sStashPlacement:UseItem(args)

    local stash_type = StashNameToType[args.item.name]
    if not stash_type then return end

    if args.player:GetValue("StuntingVehicle") then
        Chat:Send(args.player, "You cannot use this item while stunting on a vehicle!", Color.Red)
        return
    end

    Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
    args.player:SetValue("StashUsingItem", args)

    Network:Send(args.player, "items/StartStashPlacement", {
        model_data = Lootbox.Models[stash_type]
    })

end


sStashPlacement = sStashPlacement()