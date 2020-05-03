class 'sWeaponManager'

function sWeaponManager:__init()

    self.pending_fire = {}

    self:CheckPendingShots()

    Events:Subscribe("Inventory/ToggleEquipped", self, self.ToggleEquipped)
    Events:Subscribe("InventoryUpdated", self, self.InventoryUpdated)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("PlayerJoin", self, self.PlayerJoin)

    Network:Subscribe("Items/FireWeapon", self, self.FireWeapon)
end

function sWeaponManager:PlayerJoin(args)
    args.player:ClearInventory()
    args.player:SetValue("EquippedWeapons", {})
end

function sWeaponManager:ModuleUnload()
    for player in Server:GetPlayers() do
        player:ClearInventory()
    end
end

function sWeaponManager:ToggleEquipped(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.weapons[args.item.name] then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)
    self:RefreshEquippedWeapons(args.player)

    Network:Send(args.player, "items/ToggleWeaponEquipped", {equipped = args.item.equipped == true})

    local item_equipped_config = ItemsConfig.equippables.weapons[args.item.name]

end

function sWeaponManager:InventoryUpdated(args)

    for weapon_name, data in pairs(args.player:GetValue("EquippedWeapons")) do

        if data.ammo ~= self:GetWeaponAmmo({weapon_name = weapon_name, player = args.player}) then
            -- Dropped or gained ammo, so refresh their gun

            -- TODO: fix it always going back to right hand weapon instead of back to old equipped slot
            self:RefreshEquippedWeapons(args.player)
            break
        end
        
    end
end

function sWeaponManager:CheckPendingShots()
    
    local func = coroutine.wrap(function()
        while true do

            if count_table(self.pending_fire) > 0 then
                local data = table.remove(self.pending_fire)
                self:ProcessWeaponShot(data.args, data.player)
            end

            Timer.Sleep(5)
        end
    end)()

end

-- Called when a player fires a weapon
function sWeaponManager:FireWeapon(args, player)
    table.insert(self.pending_fire, {args = args, player = player})
    -- Important to sort by timestamp so ammo matches
    table.sort(self.pending_fire, function(a,b) return a.args.ts > b.args.ts end)
end

function sWeaponManager:ProcessWeaponShot(args, player)

    if not IsValid(player) or player:GetValue("dead") or player:GetHealth() <= 0 then return end

    local weapon = player:GetEquippedWeapon()
    if not weapon then return end

    local weapon_name = self:GetWeaponNameFromId(weapon.id)
    if not weapon_name then return end

    local ammo_name = Items_ammo_types[weapon_name]
    local ammo_amount = self:GetWeaponAmmo({weapon_name = weapon_name, player = player})

    local player_weapons = player:GetValue("EquippedWeapons")
    
    if not player_weapons[weapon_name] then
        Events:Fire("KickPlayer", {
            player = player,
            reason = string.format("Weapon mismatch. Player has does not have weapon %s equipped", weapon_name),
            p_reason = "Weapon mismatch"
        })
        return
    end

    local still_pending = count_table(self.pending_fire) > 0

    if (not args.ammo or args.ammo > ammo_amount) and not still_pending then
        Events:Fire("KickPlayer", {
            player = player,
            reason = string.format("Ammo mismatch. Current ammo %s, last known ammo: %s", 
                tostring(args.ammo), tostring(ammo_amount)),
            p_reason = "Ammo mismatch"
        })
        return
    end

    if ammo_amount == 0 and not still_pending then
        -- They are firing a gun they do not have ammo for
        Events:Fire("KickPlayer", {
            player = player,
            reason = string.format("Ammo mismatch. No ammo found for weapon: %s", 
                tostring(weapon_name)),
            p_reason = "Ammo mismatch"
        })

    else

        -- Remove ammo from inventory and decrease weapon durability
        local item_data = Items_indexed[ammo_name]
        item_data.amount = 1
        local ammo_item = shItem(item_data)

        player_weapons[weapon_name].ammo = player_weapons[weapon_name].ammo - 1
        player:SetValue("EquippedWeapons", player_weapons)
        
        Inventory.RemoveItem({player = player, item = ammo_item:GetSyncObject()})

        -- Now decrease equipped weapon durability
        local equipped_item = GetEquippedItem(weapon_name, player)

        if not equipped_item then
            -- Shooting a weapon that they do not have equipped
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

    end

end

function sWeaponManager:GetWeaponNameFromId(weapon_id)
    for name,v in pairs(ItemsConfig.equippables.weapons) do
        if v.weapon_id == weapon_id then return name end
    end
end

function sWeaponManager:RefreshEquippedWeapons(player)
    
    local player_equipped = player:GetValue("EquippedItems")
    local equipped_weapons = player:GetValue("EquippedWeapons")

    player:ClearInventory()

    for k,v in pairs(player_equipped) do

        local item_equipped_config = ItemsConfig.equippables.weapons[v.name]

        if (v.equip_type == "weapon_1h" or v.equip_type == "weapon_2h")
         and item_equipped_config and item_equipped_config.weapon_id then

            local ammo = self:GetWeaponAmmo({weapon_name = v.name, player = player})
            player:SetValue("WeaponAmmo", ammo)

            player:GiveWeapon(item_equipped_config.equip_slot, Weapon(
                item_equipped_config.weapon_id,
                0,
                ammo
            ))

            equipped_weapons[v.name] = {
                id = item_equipped_config.weapon_id,
                ammo = ammo
            }

            Network:Send(player, "items/ForceWeaponSwitch", 
            {
                slot = item_equipped_config.equip_slot,
                weapon = item_equipped_config.weapon_id,
                ammo = ammo
            })

        end

    end

    player:SetValue("EquippedWeapons", equipped_weapons)

end

-- Needs weapon_name and player
function sWeaponManager:GetWeaponAmmo(args)

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

sWeaponManager = sWeaponManager()