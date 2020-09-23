class 'sWeaponManager'

function sWeaponManager:__init()

    self.pending_fire = {}
    self.pending_refreshes = {} -- Pending equipped weapon refreshes to batch them

    self:CheckPendingShots()
    self:CheckPendingRefreshes()

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
    self.pending_refreshes[tostring(args.player:GetSteamId())] = args.player

    Network:Send(args.player, "items/ToggleWeaponEquipped", {equipped = args.item.equipped == true})

    local item_equipped_config = ItemsConfig.equippables.weapons[args.item.name]

end

function sWeaponManager:InventoryUpdated(args)

    local equipped_weapons = args.player:GetValue("EquippedWeapons")
    for weapon_name, data in pairs(args.player:GetValue("EquippedWeapons")) do

        if not GetEquippedItem(weapon_name, args.player) then
            equipped_weapons[weapon_name] = nil
            args.player:SetValue("EquippedWeapons", equipped_weapons)
        elseif data.ammo ~= self:GetWeaponAmmo({weapon_name = weapon_name, player = args.player}) then
            -- Dropped or gained ammo, so refresh their gun

            -- TODO: fix it always going back to right hand weapon instead of back to old equipped slot
            self.pending_refreshes[tostring(args.player:GetSteamId())] = args.player
            break
        end
        
    end
end

function sWeaponManager:CheckPendingRefreshes()
    Timer.SetInterval(100, function()
        if count_table(self.pending_refreshes) > 0 then
            for steamid, player in pairs(self.pending_refreshes) do
                self:RefreshEquippedWeapons(player)
            end
            self.pending_refreshes = {}
        end
    end)
end

function sWeaponManager:CheckPendingShots()
    
    Timer.SetInterval(100, function()
        if count_table(self.pending_fire) > 0 then

            for steam_id, data in pairs(self.pending_fire) do
                for weapon_id, ammo_data in pairs(data) do
                    self:ProcessWeaponShot(ammo_data)
                    self.pending_fire[steam_id][weapon_id] = nil
                end

                if count_table(self.pending_fire[steam_id]) == 0 then
                    self.pending_fire[steam_id] = nil
                end
            end
        end
    end)

end

-- Called when a player fires a weapon
function sWeaponManager:FireWeapon(args, player)

    local steam_id = tostring(player:GetSteamId())

    if not self.pending_fire[steam_id] then
        self.pending_fire[steam_id] = {}
    end

    local weapon = player:GetEquippedWeapon()
    if not weapon then return end

    local weapon_name = self:GetWeaponNameFromId(weapon.id)
    if not weapon_name then return end

    local equipped_weapons = player:GetValue("EquippedWeapons")

    if not self.pending_fire[steam_id][weapon.id] then

        local weapon_ammo = weapon.ammo_clip + weapon.ammo_reserve

        local ammo_name = Items_ammo_types[weapon_name]
        local ammo_amount = self:GetWeaponAmmo({weapon_name = weapon_name, player = player})

        if args.ammo > ammo_amount + 2 then
            Events:Fire("KickPlayer", {
                player = player,
                reason = string.format("Ammo mismatch. Client sent more ammo than in inventory. Client: %d Ammo: %d", args.ammo, ammo_amount),
                p_reason = "Ammo mismatch"
            })
            return
        end

        local weapon_ammo = weapon.ammo_clip + weapon.ammo_reserve

        if weapon_ammo > ammo_amount + 2 then
            Events:Fire("KickPlayer", {
                player = player,
                reason = string.format("Ammo mismatch. Player has more ammo in gun than in inventory. Gun: %d Ammo: %d", weapon_ammo, ammo_amount),
                p_reason = "Ammo mismatch"
            })
            return
        end
    
        self.pending_fire[steam_id][weapon.id] = {
            ammo = args.ammo,
            initial_ammo = ammo_amount,
            adjusted_ammo = ammo_amount - 1,
            player = player
        }

        if not weapon_name then return end

        equipped_weapons[weapon_name].ammo = ammo_amount - 1
    else
        self.pending_fire[steam_id][weapon.id].ammo = args.ammo
        self.pending_fire[steam_id][weapon.id].adjusted_ammo = self.pending_fire[steam_id][weapon.id].adjusted_ammo - 1
        if equipped_weapons and weapon_name and equipped_weapons[weapon_name] then
            equipped_weapons[weapon_name].ammo = self.pending_fire[steam_id][weapon.id].adjusted_ammo - 1
        end
    end

end

function sWeaponManager:ProcessWeaponShot(args)

    if not IsValid(args.player) then return end

    local weapon = args.player:GetEquippedWeapon()
    if not weapon then return end

    local weapon_name = self:GetWeaponNameFromId(weapon.id)
    if not weapon_name then return end

    local ammo_name = Items_ammo_types[weapon_name]
    local ammo_amount = self:GetWeaponAmmo({weapon_name = weapon_name, player = args.player})

    local ammo_used = math.max(0, args.initial_ammo - args.adjusted_ammo)

    -- Remove ammo from inventory and decrease weapon durability
    local item_data = Items_indexed[ammo_name]
    item_data.amount = ammo_used
    local ammo_item = shItem(item_data)

    local player_weapons = args.player:GetValue("EquippedWeapons")

    if not weapon_name or not player_weapons or not player_weapons[weapon_name] then return end

    player_weapons[weapon_name].ammo = player_weapons[weapon_name].ammo - ammo_used
    args.player:SetValue("EquippedWeapons", player_weapons)
    
    Inventory.RemoveItem({player = args.player, item = ammo_item:GetSyncObject()})

    -- Now decrease equipped weapon durability
    local equipped_item = GetEquippedItem(weapon_name, args.player)

    if not equipped_item then
        -- Shooting a weapon that they do not have equipped
        Events:Fire("KickPlayer", {
            player = args.player,
            reason = string.format("Weapon mismatch. Not equipped: %s", 
                tostring(weapon_name)),
            p_reason = "Weapon mismatch"
        })
        return
    end

    equipped_item.durability = equipped_item.durability - ItemsConfig.equippables.weapons[weapon_name].dura_per_use * ammo_used
    Inventory.ModifyDurability({player = args.player, item = equipped_item})
    UpdateEquippedItem(args.player, equipped_item.name, equipped_item)

end

function sWeaponManager:GetWeaponNameFromId(weapon_id)
    for name,v in pairs(ItemsConfig.equippables.weapons) do
        if v.weapon_id == weapon_id then return name end
    end
end

function sWeaponManager:RefreshEquippedWeapons(player)

    if not IsValid(player) then return end

    local player_equipped = player:GetValue("EquippedItems")
    local equipped_weapons = player:GetValue("EquippedWeapons")

    local equipped_weapon = player:GetEquippedWeapon()
    local equipped_weapon_slot = player:GetEquippedSlot()

    Thread(function()
        Network:Send(player, "items/ForceWeaponZoomout")
        Timer.Sleep(player:GetPing() * 2 + 100)

        if not IsValid(player) then return end
        player:ClearInventory()

        for name,v in pairs(player_equipped) do

            local item_equipped_config = ItemsConfig.equippables.weapons[name]

            if (v.equip_type == "weapon_1h" or v.equip_type == "weapon_2h")
            and item_equipped_config and item_equipped_config.weapon_id then

                local ammo = self:GetWeaponAmmo({weapon_name = name, player = player})
                player:SetValue("WeaponAmmo", ammo)

                player:GiveWeapon(item_equipped_config.equip_slot, Weapon(
                    item_equipped_config.weapon_id,
                    0,
                    ammo
                ))

                equipped_weapons[name] = {
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

    end)

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