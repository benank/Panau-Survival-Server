Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not args.item.name:find("Grapplehook Upgrade") then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    local equipped_upgrades = args.player:GetValue("EquippedGrappleUpgrades")
    local upgrade_name = GetGrappleUpgradeName(args.item.name)

    equipped_upgrades[upgrade_name] = args.item.equipped 
        and math.min(4, equipped_upgrades[upgrade_name] + 1) or math.max(0, equipped_upgrades[upgrade_name] - 1)
    
    args.player:SetValue("EquippedGrappleUpgrades", equipped_upgrades)

    Network:Send(args.player, "items/ToggleEquippedGrappleUpgrade", {upgrades = equipped_upgrades})

end)

Network:Subscribe("items/SpeedGrapplehookDecreaseDura", function(args, player)

    args.name = "Grapplehook Upgrade - Speed"
    DecreaseGrappleUpgradeDurability(args, player)

end)

Network:Subscribe("items/RangeGrapplehookDecreaseDura", function(args, player)

    args.name = "Grapplehook Upgrade - Range"
    DecreaseGrappleUpgradeDurability(args, player)

end)

Network:Subscribe("items/DecreaseRechargeGrappleDura", function(args, player)

    args.name = "Grapplehook Upgrade - Recharge"
    DecreaseGrappleUpgradeDurability(args, player)

end)

function DecreaseGrappleUpgradeDurability(args, player)

    local inv = Inventory.Get({player = player})
    local upgrade_name = args.name
    local cat = Items_indexed[upgrade_name].category
    local change = 1
    
    if ItemsConfig.equippables[upgrade_name].dura_per_use then
        change = ItemsConfig.equippables[upgrade_name].dura_per_use
    else
        
        args.change = math.ceil(args.change)
        if args.change < 1 then
            args.change = 1
        end

        change = ItemsConfig.equippables[upgrade_name].dura_per_sec * args.change
    end
    
    for index, stack in pairs(inv[cat]) do
        if stack:GetProperty("name") == upgrade_name and stack:GetOneEquipped() then
            for item_index, item in pairs(stack.contents) do

                if item.equipped then
                    item.durability = item.durability + change
                    Inventory.ModifyDurability({
                        player = player,
                        item = item:GetSyncObject()
                    })
                end

            end
        end
    end

end

Network:Subscribe("items/DecreaseSmartGrappleDura", function(args, player)

    local item = GetEquippedItem("Grapplehook Upgrade - Smart", player)
    if not item then return end
    item.durability = item.durability + ItemsConfig.equippables["Grapplehook Upgrade - Smart"].dura_per_use
    Inventory.ModifyDurability({
        player = player,
        item = item
    })
    UpdateEquippedItem(player, "Grapplehook Upgrade - Smart", item)

end)

function GetGrappleUpgradeName(name)

    local upgrade_name_split = name:split(" ")
    return upgrade_name_split[#upgrade_name_split]

end