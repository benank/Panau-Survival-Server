class 'sHitDetection'

function sHitDetection:__init()

    self.pending_hits = {}
    self.last_damage_timeout = 15 -- 15 seconds to clear last damaged kill attribution

    self.players = {}

    self.pending_armor_aggregation = {}

    self:CheckPendingHits()

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)

    Network:Subscribe("HitDetectionSyncHit", self, self.SyncHit)
    Network:Subscribe("HitDetectionSyncExplosion", self, self.HitDetectionSyncExplosion)

    Events:Subscribe("HitDetection/PlayerInToxicArea", self, self.PlayerInsideToxicArea)
    Events:Subscribe("HitDetection/PlayerSurvivalDamage", self, self.PlayerSurvivalDamage)

    Events:Subscribe("HitDetection/VehicleGuardActivate", self, self.VehicleGuardActivate)
    Events:Subscribe("HitDetection/WarpGrenade", self, self.WarpGrenade)

    Events:Subscribe("Hitdetection/AdminKill", self, self.AdminKill)

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("PlayerDeath", self, self.PlayerDeath)

    Events:Subscribe("PlayerChat", self, self.PlayerChat)
end

function sHitDetection:ClientModuleLoad(args)
    self.players[tostring(args.player:GetSteamId())] = args.player
end

function sHitDetection:PlayerQuit(args)
    self.players[tostring(args.player:GetSteamId())] = nil
end

function sHitDetection:ApplyDamage(player, damage, source, attacker_id)

    if player:GetValue("Loading") then return end
    if player:GetValue("Invincible") then return end
    if player:GetValue("InSafezone") 
    and source ~= DamageEntity.Suicide 
    and source ~= DamageEntity.AdminKill then return end

    local old_hp = player:GetHealth()

    if old_hp <= 0 then return end

    if old_hp - damage <= 0 and source ~= DamageEntity.Suicide and source ~= DamageEntity.AdminKill then
        -- If this damage is going to kill them

        -- If they have a second life, don't let them die
        if player:GetValue("SecondLifeEquipped") then

            player:SetNetworkValue("Invincible", true)
            player:SetHealth(0.1)

            local item_cost = CreateItem({
                name = "Second Life",
                amount = 1
            })
            
            Inventory.RemoveItem({
                item = item_cost:GetSyncObject(),
                player = player
            })
        
            Chat:Send(player, "Second Life just prevented you from dying and has been consumed!", Color.Yellow)

            player:SetValue("RecentHealTime", Server:GetElapsedSeconds())
            player:SetValue("SecondLifeEquipped", false)

            Timer.SetTimeout(1000, function()
                if IsValid(player) then
                    player:SetHealth(1)
                    player:SetNetworkValue("Invincible", false)
                end
            end)
        end

    end

    attacker = self.players[attacker_id]

    local msg = ""
    
    if not IsValid(attacker) and not attacker_id then
        player:Damage(damage, source)

        msg = string.format("%s [%s] damaged by %s for %.0f damage",
            player:GetName(), 
            tostring(player:GetSteamId()),
            DamageEntityNames[source],
            damage * 100)

    elseif not IsValid(attacker) and attacker_id then

        player:Damage(damage, source)
            
        msg = string.format("%s [%s] damaged by %s from [%s] for %.0f damage",
            player:GetName(), 
            tostring(player:GetSteamId()),
            DamageEntityNames[source],
            attacker_id,
            damage * 100)

        self:SetPlayerLastDamaged(player, DamageEntityNames[source], attacker_id)

    else

        player:Damage(damage, source, attacker)
            
        msg = string.format("%s [%s] damaged by %s from %s [%s] for %.0f damage",
            player:GetName(), 
            tostring(player:GetSteamId()),
            DamageEntityNames[source],
            attacker:GetName(),
            tostring(attacker:GetSteamId()),
            damage * 100)

        if source == DamageEntity.Explosion or source == DamageEntity.Bullet then
            -- Append weapon name too

            local weapon = attacker:GetEquippedWeapon()
            local weapon_name = GetWeaponName(weapon.id)

            msg = msg .. string.format(" [Weapon: %s]", weapon_name)

        end

        if attacker:InVehicle() then

            msg = msg .. string.format(" [Vehicle: %s]", attacker:GetVehicle():GetName())

        end

        Network:Send(attacker, "HitDetection/DealDamage")

        self:SetPlayerLastDamaged(player, DamageEntityNames[source], tostring(attacker:GetSteamId()))

    end

    print(msg)
    Events:Fire("Discord", {
        channel = "Hitdetection",
        content = msg
    })

    player:SetValue("Health", math.min(1, math.max(0, old_hp - damage)))
    self:CheckHealth(player, old_hp, damage)

end

function sHitDetection:AdminKill(args)

    if not IsValid(args.player) then return end

    self:ApplyDamage(args.player, 9999, DamageEntity.AdminKill, tostring(args.attacker:GetSteamId()))

end

function sHitDetection:PlayerChat(args)
    if args.text == "/respawn" then

        if args.player:GetValue("Loading") then return end

        self:ApplyDamage(args.player, SuicideDamage, DamageEntity.Suicide)

        local last_damaged = args.player:GetValue("LastDamaged")

        if last_damaged then
            if Server:GetElapsedSeconds() - last_damaged.timer > self.last_damage_timeout then
                args.player:SetValue("Suicided", true)
            else
                args.player:SetValue("Suicided", nil)
            end
        else
            args.player:SetValue("Suicided", true)
        end

    end
end

function sHitDetection:CheckPendingHits()
    
    local func = coroutine.wrap(function()
        while true do

            if count_table(self.pending_hits) > 0 then
                local data = table.remove(self.pending_hits)

                for _, v in pairs(data.pending) do

                    if v.type == WeaponHitType.Explosive then
                        self:ExplosionHit(v, data.player)
                    else
                        self:BulletHit(v, data.player)
                    end

                    Timer.Sleep(3)

                end
            end

            Timer.Sleep(10)
        end
    end)()

    
    local func = coroutine.wrap(function()
        while true do
            if count_table(self.pending_armor_aggregation) > 0 then

                for steam_id, data in pairs(self.pending_armor_aggregation) do
                    for armor_name, hit_data in pairs(data) do
                        Events:Fire("HitDetection/ArmorDamaged", hit_data)
                        Timer.Sleep(300)
                        self.pending_armor_aggregation[steam_id][armor_name] = nil
                    end

                    if count_table(self.pending_armor_aggregation[steam_id]) == 0 then
                        self.pending_armor_aggregation[steam_id] = nil
                    end
                end
            end

            Timer.Sleep(1000)

        end
    end)()

end

function sHitDetection:WarpGrenade(args)

    if not IsValid(args.player) then return end

    self:ApplyDamage(args.player, WarpGrenadeDamage, DamageEntity.WarpGrenade)

end

function sHitDetection:VehicleGuardActivate(args)

    if not IsValid(args.player) then return end

    self:ApplyDamage(args.player, VehicleGuardDamage, DamageEntity.VehicleGuard, args.attacker_id)

end

function sHitDetection:PlayerSurvivalDamage(args)

    if not IsValid(args.player) then return end

    self:ApplyDamage(args.player, args.amount, args.type)
    
end

function sHitDetection:PlayerDeath(args)

    args.player:SetNetworkValue("OnFire", false)

    local last_damaged = args.player:GetValue("LastDamaged")

    if last_damaged and Server:GetElapsedSeconds() - last_damaged.timer < self.last_damage_timeout then
        -- Kill attribution
        local query = SQL:Query("SELECT name FROM player_names WHERE steam_id = (?) LIMIT 1")
        query:Bind(1, last_damaged.steam_id)
        local killer_name = query:Execute()

        if killer_name and killer_name[1] and killer_name[1].name then
            killer_name = killer_name[1].name
        else
            killer_name = "???"
        end

        local msg = string.format("%s [%s] was killed by %s [%s] [%s]", 
            args.player:GetName(),
            tostring(args.player:GetSteamId()),
            killer_name,
            last_damaged.steam_id,
            DamageEntityNames[args.reason])

        Chat:Send(args.player, string.format("You were killed by %s [%s]", 
            killer_name, last_damaged.damage_type), Color.Red)
        
        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = last_damaged.steam_id,
            message = string.format("You killed %s [%s]", args.player:GetName(), last_damaged.damage_type),
            color = Color.Red
        })

        print(msg)
        Events:Fire("Discord", {
            channel = "Hitdetection",
            content = msg
        })

        local killer = self.players[last_damaged.steam_id]

        if IsValid(killer) then
            Network:Send(killer, "HitDetection/DealDamage", {red = true})
        end

    else
        -- Player died on their own without anyone else, like drowning or falling from too high

        local msg = string.format("%s [%s] died [%s]", 
            args.player:GetName(),
            tostring(args.player:GetSteamId()),
            DamageEntityNames[args.reason])

        Chat:Send(args.player, string.format("You died [Reason: %s]", DamageEntityNames[args.reason]), Color.Red)
        
        print(msg)
        Events:Fire("Discord", {
            channel = "Hitdetection",
            content = msg
        })
    end

    if not args.player:GetValue("Suicided") and not args.player:GetValue("Invisible") and not args.player:GetValue("Invincible") then
        Events:Fire("PlayerKilled", {player = args.player, killer = last_damaged and last_damaged.steam_id, reason = args.reason})
    end

    args.player:SetValue("Suicided", nil)
    args.player:SetValue("LastDamaged", nil)
end

function sHitDetection:PlayerInsideToxicArea(args)
    
    if not IsValid(args.player) then return end

    self:ApplyDamage(args.player, ToxicDamagePerSecond, DamageEntity.ToxicGrenade, args.attacker_id)

end

function sHitDetection:SecondTick()

    for p in Server:GetPlayers() do
        if p:GetValue("OnFire") and 
        ( p:GetPosition().y < 199.5 or p:GetValue("InSafezone") 
            or Server:GetElapsedSeconds() - p:GetValue("OnFireTime") >= FireEffectTime
            or p:GetHealth() <= 0 ) then

            p:SetNetworkValue("OnFire", false)

        elseif p:GetValue("OnFire") then

            local attacker_id = p:GetValue("FireAttackerId")

            self:ApplyDamage(p, FireDamagePerSecond, DamageEntity.Molotov, attacker_id)

        end
    end

end

function sHitDetection:HitDetectionSyncExplosion(args, player)
    
    if not IsValid(player) then return end

    local explosive_data = ExplosiveBaseDamage[args.type]

    if not explosive_data then return end

    local dist = args.position:Distance(args.local_position)
    local percent_modifier = math.max(0, 1 - dist / explosive_data.radius)

    if percent_modifier == 0 then return end

    local hit_type = WeaponHitType.Explosive
    local original_damage = explosive_data.damage * percent_modifier
    local damage = original_damage

    if not args.in_fov then
        damage = damage * FOVDamageModifier
    end
    
    damage = self:GetArmorMod(player, hit_type, damage, original_damage)

    self:ApplyDamage(player, damage / 100, args.type, args.attacker_id)

    Events:Fire("HitDetection/PlayerExplosionItemHit", {
        player = player,
        damage = damage,
        type = args.type
    })

    if player:InVehicle() then
        player:GetVehicle():SetHealth(player:GetVehicle():GetHealth() - original_damage / explosive_data.damage * 0.5)
        player:GetVehicle():SetLinearVelocity(player:GetVehicle():GetLinearVelocity() + ((player:GetVehicle():GetPosition() - args.position):Normalized() * explosive_data.radius * explosive_data.knockback))
    end

end

function sHitDetection:SyncHit(args, player)
    table.insert(self.pending_hits, {pending = args.pending, player = player})
end

function sHitDetection:ExplosionHit(args, player)

    if not IsValid(player) then return end
    if not IsValid(args.attacker) then return end

    if args.attacker:GetValue("InSafezone") then return end

    local weapon = args.attacker:GetEquippedWeapon()
    if not weapon then return end

    local percent = 1
    if not args.damage then args.damage = 100 end

    if weapon.id == Weapon.GrenadeLauncher then
        percent = args.damage / 350
    elseif weapon.id == Weapon.RocketLauncher then
        percent = args.damage / 1000
    else
        percent = args.damage / 1000
    end

    percent = math.clamp(percent, 0, 1)

    if not WeaponBaseDamage[weapon.id] then return end
    
    local hit_type = WeaponHitType.Explosive
    local original_damage = WeaponBaseDamage[weapon.id] * percent
    local damage = original_damage
    damage = self:GetArmorMod(player, hit_type, damage, original_damage)

    self:ApplyDamage(player, damage / 100, DamageEntity.Explosion, tostring(args.attacker:GetSteamId()))

    Events:Fire("HitDetection/PlayerExplosionHit", {
        player = player,
        attacker = args.attacker,
        damage = damage
    })

end

function sHitDetection:BulletHit(args, player)
    
    if not IsValid(player) then return end
    if not args.bone or not BoneModifiers[args.bone.name] then return end
    if not IsValid(args.attacker) then return end

    if args.attacker:GetValue("InSafezone") then return end

    local weapon = args.attacker:GetEquippedWeapon()
    local base_damage = WeaponBaseDamage[weapon.id] or 0

    if base_damage == 0 then return end

    local hit_type = BoneModifiers[args.bone.name].type
    local original_damage = WeaponBaseDamage[weapon.id] * BoneModifiers[args.bone.name].mod
    local damage = original_damage
    damage = self:GetArmorMod(player, hit_type, damage, original_damage)

    self:ApplyDamage(player, damage / 100, DamageEntity.Bullet, tostring(args.attacker:GetSteamId()))

    Events:Fire("HitDetection/PlayerBulletHit", {
        player = player,
        attacker = args.attacker,
        damage = damage
    })

end

function sHitDetection:CheckHealth(player, old_hp, damage)

    Timer.SetTimeout(10 * player:GetPing() + 500, function()
        -- If they healed recently, disregard
        if not IsValid(player) then return end 

        if player:GetValue("RecentHealTime") and Server:GetElapsedSeconds() - player:GetValue("RecentHealTime") < 15 then
            return
        end
        
        if player:GetHealth() >= old_hp and player:GetHealth() > 0 then
            -- Health did not change, ban
            Events:Fire("KickPlayer", {
                player = player,
                reason = string.format("Health hacking detected. Expected: %.3f Actual: %.3f", old_hp - damage, player:GetHealth()),
                p_reason = "Error"
            })
        end
    end)

end

function sHitDetection:GetArmorMod(player, hit_type, damage, original_damage)

    local equipped_items = player:GetValue("EquippedItems")

    for armor_name, mods in pairs(ArmorModifiers) do
        if equipped_items[armor_name] and ArmorModifiers[armor_name][hit_type] > 0 then

            damage = damage * (1 - ArmorModifiers[armor_name][hit_type])

            -- If the armor prevented some damage, then modify its durability
            if ArmorModifiers[armor_name][hit_type] > 0 then
                
                local steam_id = tostring(player:GetSteamId())

                if not self.pending_armor_aggregation[steam_id] then
                    self.pending_armor_aggregation[steam_id] = {}
                end

                if not self.pending_armor_aggregation[steam_id][armor_name] then
                    self.pending_armor_aggregation[steam_id][armor_name] = 
                    {
                        player = player,
                        armor_name = armor_name,
                        damage_diff = original_damage - original_damage * (1 - ArmorModifiers[armor_name][hit_type])
                    }
                else
                    self.pending_armor_aggregation[steam_id][armor_name].damage_diff = 
                        self.pending_armor_aggregation[steam_id][armor_name].damage_diff +
                        original_damage - original_damage * (1 - ArmorModifiers[armor_name][hit_type])
                end
            end

        end
    end

    return damage

end

function sHitDetection:SetPlayerLastDamaged(player, damage_type, steam_id)
    player:SetValue("LastDamaged", {
        damage_type = damage_type, -- Name of damage type
        steam_id = steam_id,
        timer = Server:GetElapsedSeconds()
    })
end

sHitDetection = sHitDetection()