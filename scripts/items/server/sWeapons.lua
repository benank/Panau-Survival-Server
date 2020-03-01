Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.weapons[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)
    RefreshEquippedWeapons(args.player)

    Network:Send(args.player, "items/ToggleWeaponEquipped", {equipped = args.item.equipped == true})
end)

Events:Subscribe("InventoryUpdated", function(args)
    local weapon = args.player:GetEquippedWeapon()
    if not weapon then return end

    local weapon_name = GetWeaponNameFromId(weapon.id)
    if not weapon_name then return end

    if args.player:GetValue("WeaponAmmo") ~= GetWeaponAmmo({weapon_name = weapon_name, player = args.player}) then
        -- Dropped or gained ammo, so refresh their gun
        RefreshEquippedWeapons(args.player)
    end
end)

function FireWeapon(args, player)

    local weapon = player:GetEquippedWeapon()
    if not weapon then return end

    local weapon_name = GetWeaponNameFromId(weapon.id)
    if not weapon_name then return end

    local ammo_name = Items_ammo_types[weapon_name]
    local ammo_amount = GetWeaponAmmo({weapon_name = weapon_name, player = player})

    if not args.ammo or ammo_amount ~= args.ammo then
        Events:Fire("KickPlayer", {
            player = player,
            reason = string.format("Ammo mismatch. Current ammo %s, last known ammo: %s", 
                tostring(args.ammo), tostring(ammo_amount)),
            p_reason = "Ammo mismatch"
        })
        return
    end

    if ammo_amount == 0 then
        -- They are firing a gun they do not have ammo for
        -- ban
        Events:Fire("KickPlayer", {
            player = player,
            reason = string.format("Weapon mismatch. No ammo found for weapon: %s", 
                tostring(weapon_name)),
            p_reason = "Weapon mismatch"
        })

    else
        player:SetValue("InventoryOperationBlock", player:GetValue("InventoryOperationBlock") + 1)
        -- Remove ammo from inventory and decrease weapon durability
        local item_data = Items_indexed[ammo_name]
        item_data.amount = 1
        local ammo_item = shItem(item_data)

        player:SetValue("WeaponAmmo", ammo_amount - 1)
        Inventory.RemoveItem({player = player, item = ammo_item:GetSyncObject()})

        -- Now decrease equipped weapon durability
        local equipped_item = GetEquippedItem(weapon_name, player)

        if not equipped_item then
            -- Shooting a weapon that they do not have equipped
            -- ban
            Events:Fire("KickPlayer", {
                player = player,
                reason = string.format("Weapon mismatch. Not equipped: %s", 
                    tostring(weapon_name)),
                p_reason = "Weapon mismatch"
            })

            return
        end

        equipped_item.durability = equipped_item.durability - ItemsConfig.equippables.weapons[weapon_name].dura_per_use
        Inventory.ModifyDurability({player = player, item = equipped_item})
        UpdateEquippedItem(player, equipped_item.name, equipped_item)

        Timer.SetTimeout(500, function()
            if IsValid(player) then
                player:SetValue("InventoryOperationBlock", player:GetValue("InventoryOperationBlock") - 1)
            end
        end)

    end


end

Network:Subscribe("Items/FireWeapon", FireWeapon)

function GetWeaponNameFromId(weapon_id)
    for name,v in pairs(ItemsConfig.equippables.weapons) do
        if v.weapon_id == weapon_id then return name end
    end
end

function RefreshEquippedWeapons(player)

    local player_equipped = player:GetValue("EquippedItems")

    player:ClearInventory()

    for k,v in pairs(player_equipped) do

        local item_equipped_config = ItemsConfig.equippables.weapons[v.name]

        if v.equip_type == "weapon" and item_equipped_config and item_equipped_config.weapon_id then

            local ammo = GetWeaponAmmo({weapon_name = v.name, player = player})
            player:SetValue("WeaponAmmo", ammo)

            player:GiveWeapon(item_equipped_config.equip_slot, Weapon(
                item_equipped_config.weapon_id,
                0,
                ammo
            ))

            Network:Send(player, "items/ForceWeaponSwitch", 
            {
                slot = item_equipped_config.equip_slot,
                weapon = item_equipped_config.weapon_id,
                ammo = ammo
            })
            -- Force input on player so the guns appear correctly and not under their feet

            return

        end

    end

end

-- Needs weapon_name and player
function GetWeaponAmmo(args)

    if not args.weapon_name or not IsValid(args.player) then return 0 end

    local ammo_name = Items_ammo_types[args.weapon_name]
    if not ammo_name then return 0 end

    local player_inventory = Inventory.Get({player = args.player})
    if not player_inventory then return 0 end

    local cat = Items_indexed[ammo_name].category

    local total_ammo = 0
    
    for index, stack in pairs(player_inventory[cat]) do
        if stack and stack:GetProperty("name") == ammo_name then
            total_ammo = total_ammo + stack:GetAmount()
        end
    end

    return total_ammo

end

Events:Subscribe("ModuleUnload", function()
    for player in Server:GetPlayers() do
        player:ClearInventory()
    end
end)

Events:Subscribe("ClientModuleLoad", function(args)
    args.player:ClearInventory()
end)