Events:Subscribe("PlayerJoin", function(args)
    args.player:SetNetworkValue("EquippedItems", {})
    args.player:SetNetworkValue("EquippedVisuals", {})
end)

function Unload()

    for player in Server:GetPlayers() do
        player:SetNetworkValue("EquippedItems", {})
        player:SetNetworkValue("EquippedVisuals", {})
    end

end

Events:Subscribe("InventoryUnload", Unload)
Events:Subscribe("ModuleUnload", Unload)

function UpdateEquippedItem(player, name, value)

    if not IsValid(player) then return end
    local equipped_items = player:GetValue("EquippedItems")
    equipped_items[name] = (value.equipped == true and value.durability > 0) and value or nil
    player:SetNetworkValue("EquippedItems", equipped_items)

end

function GetEquippedItem(name, player)
    if not IsValid(player) then return end
    return player:GetValue("EquippedItems")[name]

end
