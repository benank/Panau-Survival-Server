class 'sStashPlacement'

local StashNameToType = 
{
    ["Barrel Stash"] = Lootbox.Types.BarrelStash,
    ["Garbage Stash"] = Lootbox.Types.GarbageStash,
    ["Locked Stash"] = Lootbox.Types.LockedStash
}

function sStashPlacement:__init()
    
    Events:Subscribe("Inventory/UseItem", self, self.UseItem)

    Network:Subscribe("items/CancelStashPlacement", self, self.CancelStashPlacement)
    Network:Subscribe("items/PlaceStash", self, self.PlaceStash)
    
end

function sStashPlacement:GetStashTypeFromName(name)
    for stash_type, data in pairs(Lootbox.Stashes) do
        if data.name == name then return stash_type end
    end
end

function sStashPlacement:TryPlaceStash(args, player)

    local player_iu = player:GetValue("StashUsingItem")
    local type = self:GetStashTypeFromName(player_iu.item.name)

    if player_iu.item and type then

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        -- Now actually place the stash
        sStashes:PlaceStash(args.position, args.angle, type, player)

    end

end

function sStashPlacement:PlaceStash(args, player)
    Inventory.OperationBlock({player = player, change = -1})
    if not args.position or not args.angle then return end

    if player:InVehicle() then
        Chat:Send(player, "Cannot place stashes while in a vehicle!", Color.Red)
        return
    end

    if player:GetValue("Stunting") then
        Chat:Send(player, "Cannot place stashes while stunting!", Color.Red)
        return
    end

    if args.position:Distance(player:GetPosition()) > 7 then
        Chat:Send(player, "Placing stash failed!", Color.Red)
        return
    end

    if args.position.y < 200 then
        Chat:Send(player, "You cannot place this stash underwater!", Color.Red)
        return
    end

    if args.model and DisabledPlacementModels[args.model] then
        Chat:Send(player, "Placing stash failed!", Color.Red)
        return
    end

    self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()

    -- If they are within nz, we don't let them place that close
    if player:GetPosition():Distance(self.sz_config.neutralzone.position) < self.sz_config.neutralzone.radius then
        Chat:Send(player, "Cannot place stashes while near the neutral zone!", Color.Red)
        return
    end


    local pitch = math.abs(args.angle.pitch)
    local roll = math.abs(args.angle.roll)

    -- Trying to place on a wall or something
    if pitch > math.pi / 6 or roll > math.pi / 6 then
        Chat:Send(player, "Cannot place stash here!", Color.Red)
        return
    end

    if count_table(player:GetValue("Stashes")) >= player:GetValue("MaxStashes") then
        Chat:Send(player, "You already have the maximum amount of stashes!", Color.Red)
        return
    end


    local sub = nil
    sub = Events:Subscribe("IsTooCloseToLootCheck"..tostring(player:GetSteamId()), function(args)
    
        Events:Unsubscribe(sub)
        sub = nil

        if args.too_close then

            Chat:Send(player, "Cannot place stashes too close to loot!", Color.Red)
            return

        end

        self:TryPlaceStash(args, args.player)

    end)

    args.player = player
    Events:Fire("CheckIsTooCloseToLoot", args)

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


DisabledPlacementModels = 
{
    ["geo.cbb.eez/go152-a.lod"] = true
}