Events:Subscribe("PlayerJoin", function(args)
    args.player:SetValue("EquippedItems", {})
    args.player:SetNetworkValue("EquippedVisuals", {})
end)

function Unload()

    for player in Server:GetPlayers() do
        player:SetValue("EquippedItems", {})
        player:SetNetworkValue("EquippedVisuals", {})
    end

end

Events:Subscribe("InventoryUnload", Unload)
Events:Subscribe("ModuleUnload", Unload)

function UpdateEquippedItem(player, name, value)

    local equipped_items = player:GetValue("EquippedItems")
    equipped_items[name] = (value.equipped == true and value.durability > 0) and value or nil
    player:SetValue("EquippedItems", equipped_items)

end

function GetEquippedItem(name, player)

    return player:GetValue("EquippedItems")[name]

end
