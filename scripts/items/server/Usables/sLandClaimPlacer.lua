class 'sLandClaimPlacer'

function sLandClaimPlacer:__init()

    self.network_subs = {}

    self.use_perk_req = 34
    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Network:Subscribe("items/CancelLandclaimPlacement", self, self.CancelLandclaimPlacement)
    Network:Subscribe("items/PlaceLandclaim", self, self.PlaceLandclaim)
    Events:Subscribe("ItemUse/CancelUsage", self, self.ItemUseCancelUsage)

end

function sLandClaimPlacer:ItemUseCancelUsage(args)

    if self.network_subs[tostring(args.player:GetSteamId())] then
        Network:Unsubscribe(self.network_subs[tostring(args.player:GetSteamId())])
        self.network_subs[tostring(args.player:GetSteamId())] = nil
    end

    local player_iu = args.player:GetValue("ItemUse")

    if not player_iu or player_iu.item.name ~= "LandClaim" then return end

    Chat:Send(args.player, "Placing LandClaim failed!", Color.Red)

end

function sLandClaimPlacer:PlaceLandclaim(args, player)

    args = {
        player = player,
        position = player:GetPosition()
    }
    Inventory.OperationBlock({player = player, change = -1})
    local player_iu = player:GetValue("LandclaimUsingItem")

    if not player_iu then return end

    player_iu.delayed = true
    sItemUse:InventoryUseItem(player_iu)
    player:SetValue("LandclaimUsingItem", nil)

    if self.network_subs[tostring(args.player:GetSteamId())] then
        Network:Unsubscribe(self.network_subs[tostring(args.player:GetSteamId())])
        self.network_subs[tostring(args.player:GetSteamId())] = nil
    end
    
    local sub
    sub = Network:Subscribe("items/CompleteItemUsage", function(_, _player)
    
        if player ~= _player then return end

        local player_iu = player:GetValue("ItemUse")

        if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed and 
        player_iu.item.name == "LandClaim" then

            if player:GetPosition():Distance(args.position) > 10 then
                Chat:Send(player, "Placing LandClaim failed!", Color.Red)
                return
            end

            -- Now actually place the claymore
            Events:Fire("items/PlaceLandclaim", {
                player = player,
                position = args.position,
                player_iu = player_iu
            })

        end

        Network:Unsubscribe(sub)
        self.network_subs[tostring(player:GetSteamId())] = nil

    end)

    self.network_subs[tostring(player:GetSteamId())] = sub

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

    local perks = args.player:GetValue("Perks")

    if not perks.unlocked_perks[self.use_perk_req] then
        local perks_by_id = SharedObject.GetByName("ExpPerksById"):GetValue("Perks")
        Chat:Send(args.player, 
            string.format("You must unlock the LandClaim perk (#%d) in order to use this. Hit F2 to open the perks menu.", 
            perks_by_id[self.use_perk_req].position), Color.Red)
        return
    end

    if args.player:GetValue("StuntingVehicle") then
        Chat:Send(args.player, "You cannot use this item while stunting on a vehicle!", Color.Red)
        return
    end

    Inventory.OperationBlock({player = args.player, change = 1}) -- Block inventory operations until they finish placing or cancel
    args.player:SetValue("LandclaimUsingItem", args)

    Network:Send(args.player, "items/StartLandclaimPlacement", {size = tonumber(args.item.custom_data.size)})

end

sLandClaimPlacer = sLandClaimPlacer()