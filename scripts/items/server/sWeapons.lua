Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.weapons[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)
    RefreshEquippedWeapons(args.player)

end)


--[[function FireWeapon(args, player)

    local weapon = player:GetEquippedWeapon()
    if not weapon then return end

    local weapon_name = GetWeaponNameFromId(weapon.id)
    if not weapon_name then return end

    local ammo_name = Items_ammo_types[args.weapon_name]
    local ammo_amount = GetWeaponAmmo({weapon_name = weapon_name, player = player})

    if ammo_amount == 0 then
        -- They are firing a gun they do not have ammo for
        -- ban

    else
        -- Remove ammo from inventory and decrease weapon durability
        local item_data = Items_indexed[ammo_name]
        item_data.amount = 1
        local ammo_item = shItem(item_data)

        Inventory.RemoveItem({player = player, item = ammo_item:GetSyncObject()})

        -- Now decrease equipped weapon durability
        local equipped_item = GetEquippedItem(weapon_name, player)

        if not equipped_item then
            -- Shooting a weapon that they do not have equipped
            -- ban

            return
        end

        equipped_item.durability = equipped_item.durability - ItemsConfig.equippables[weapon_name].dura_per_use
        Inventory.ModifyDurability({player = player, item = equipped_item, index = equipped_item.index})


    end


end

Network:Subscribe("Items/FireWeapon", FireWeapon)--]]

function GetWeaponNameFromId(weapon_id)
    for k,v in pairs(ItemsConfig.equippables) do
        if v.weapon_id == weapon_id then return v.name end
    end
end

function RefreshEquippedWeapons(player)

    local player_equipped = player:GetValue("EquippedItems")

    player:ClearInventory()

    for k,v in pairs(player_equipped) do

        local item_equipped_config = ItemsConfig.equippables.weapons[v.name]

        if v.equip_type == "weapon" and item_equipped_config and item_equipped_config.weapon_id then

            player:GiveWeapon(item_equipped_config.equip_slot, Weapon(
                item_equipped_config.weapon_id,
                0,
                GetWeaponAmmo({weapon_name = v.name, player = player})
            ))

            Network:Send(player, "items/ForceWeaponSwitch", {slot = item_equipped_config.equip_slot})
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