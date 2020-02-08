Events:Subscribe("PlayerJoin", function(args)
    args.player:SetValue("EquippedItems", {})
    args.player:SetValue("EquippedGrappleUpgrades", {
		["Recharge"] = 0,
		["Speed"] = 0,
		["Range"] = 0,
		["Underwater"] = 0,
		["Gun"] = 0,
		["Impulse"] = 0,
		["Smart"] = 0
    })
end)

function Unload()

    for player in Server:GetPlayers() do

        player:SetValue("EquippedItems", {})
        player:SetValue("EquippedGrappleUpgrades", {
            ["Recharge"] = 0,
            ["Speed"] = 0,
            ["Range"] = 0,
            ["Underwater"] = 0,
            ["Gun"] = 0,
            ["Impulse"] = 0,
            ["Smart"] = 0
        })

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
