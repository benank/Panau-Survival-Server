class 'SAM'

function SAM:__init(args)
    self.id = args.id
    self.base_level = args.base_level
    self.level = math.ceil(self.base_level * (1 + math.random() * 0.25))
    self.position = args.position
    self.cell = args.cell
    self.config = GetSAMConfiguration(self.level)
    self.health = self.config.MaxHealth
    self.hacked_owner = args.hacked_owner or ""
    self.destroyed = false
    self.drone_spawned = false
    self.fire_timer = Timer()
end

function SAM:IsSAMKeyEffective(level)
    if self.hacked_owner:len() > 1 then return false end
    if not level then return false end
    return self.level <= level
end

function SAM:IsFriendlyTowardsPlayer(player)
    local steam_id = tostring(player:GetSteamId())
    return AreFriends(player, self.hacked_owner) or steam_id == self.hacked_owner
end

function SAM:Hacked(player)
    local steam_id = tostring(player:GetSteamId())
    if self.hacked_owner == steam_id or AreFriends(player, self.hacked_owner) then return end
    
    if self.hacked_owner:len() > 1 then
        -- Old owner, so notify them
        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = self.hacked_owner,
            message = string.format("%s hacked your SAM %s", player:GetName(), WorldToMapString(self.position)),
            color = Color(200, 0, 0)
        })
    end
    
    self.hacked_owner = steam_id
    local exp = player:GetValue("Exp")
    if self.level < exp.level then
        self.level = exp.level
        
        local health_percent = self.health / self.config.MaxHealth
        
        self.config = GetSAMConfiguration(self.level)
        self.health = self.config.MaxHealth * health_percent
        
        self:SyncNearby(player)
        self:Sync(player)
    else
        self:SyncNearby(player, "hacked_owner")
        self:Sync(player, "hacked_owner")
    end
    
    -- First delete SAM from db if it exists
    self:DeleteFromDB()
    
    -- Sync hacked SAM to DB
    local command = SQL:Command("INSERT INTO hacked_sams (steamID, sam_id) VALUES (?, ?)")
    command:Bind(1, self.hacked_owner)
    command:Bind(2, self.id)
    command:Execute()
    
end

function SAM:CanFire()
    return self.fire_timer:GetSeconds() > self.config.FireInterval
end

function SAM:Fire(player, vehicle)
    local data = {
        sam_id = self.id,
        player_id = player:GetId(),
        vehicle_id = vehicle:GetId()
    }
    Network:Send(player, "sams/SAMFire", data)
    Network:SendNearby(player, "sams/SAMFire", data)
    self.fire_timer:Restart()
end

function SAM:Damage(amount, player)
    if self.destroyed then return end
    self.health = math.max(0, self.health - amount) 
    if self.health == 0 then
        self:Destroyed(player)
    else
        Network:Broadcast("sams/SyncSAM", self:GetSyncData("health"))
        
        if not self.drone_spawned and not self:IsFriendlyTowardsPlayer(player) then
            self.drone_spawned = true
            Timer.SetTimeout(1000 * 30 + 1 * math.random(), function()
                if not self.destroyed then
                    -- Spawn drone after taking damage
                    local pos = self.position + Vector3.Up * 4 + Vector3.Up * 4 * math.random()
                    Events:Fire("Drones/SpawnDrone", {
                        level = self.level,
                        static = true,
                        position = pos,
                        tether_position = pos,
                        tether_range = 100,
                        config = {
                            attack_on_sight = true
                        },
                        group = "sam"
                    })
                end
            end)
        end
    end
end

function SAM:Destroyed(player)
    -- Called when the SAM is destroyed by a player
    self.destroyed = true
    
    Network:Broadcast("sams/SyncSAM", self:GetSyncData("destroyed")) 
    
    if IsValid(player) then
        Events:Fire("sams/SamDestroyed", {
            sam_level = self.level,
            owner_id = self.hacked_owner,
            player = player
        })
    end
    
    if self.hacked_owner:len() > 1 then
        -- Old owner, so notify them
        if IsValid(player) then
            Events:Fire("SendPlayerPersistentMessage", {
                steam_id = self.hacked_owner,
                message = string.format("%s destroyed your SAM %s", player:GetName(), WorldToMapString(self.position)),
                color = Color(200, 0, 0)
            })
        else
            Events:Fire("SendPlayerPersistentMessage", {
                steam_id = self.hacked_owner,
                message = string.format("Your SAM was destroyed %s", WorldToMapString(self.position)),
                color = Color(200, 0, 0)
            })
        end
    end
    
    self.hacked_owner = ""
    self.drone_spawned = false
    
    if not self:IsFriendlyTowardsPlayer(player) and math.random() < self.config.LootChance then
        -- Spawn SAM lootbox
        Events:Fire("inventory/CreateLootboxExternal", {
            tier = 19,
            position = self.position,
            angle = Angle(),
            sam_level = self.level
        }) 
    end
    
    self:DeleteFromDB()
    
    Thread(function()
        Timer.Sleep(1000 * 60 * 60 * math.ceil(self.level / 10))
        self:Respawn()
    end)
end

function SAM:DeleteFromDB()
    local command = SQL:Command("DELETE FROM hacked_sams WHERE sam_id = (?)")
    command:Bind(1, self.id)
    command:Execute()
end

function SAM:Respawn()
    self.level = math.ceil(self.base_level * (1 + math.random() * 0.25))
    self.config = GetSAMConfiguration(self.level)
    self.health = self.config.MaxHealth
    self.hacked_owner = ""
    self.destroyed = false
    
    Network:Broadcast("sams/SyncSAM", self:GetSyncData(field)) 
end

function SAM:GetSyncData(field)
    
    if field then
        return {
            id = self.id,
            [field] = self[field]
        }
    else
        return {
            id = self.id,
            position = self.position,
            health = self.health,
            level = self.level,
            destroyed = self.destroyed,
            cell = self.cell,
            config = self.config,
            hacked_owner = self.hacked_owner
        }
    end
end

function SAM:SyncNearby(player, field)
    Network:SendNearby(player, "sams/SyncSAM", self:GetSyncData(field)) 
end

function SAM:Sync(player, field)
    Network:Send(player, "sams/SyncSAM", self:GetSyncData(field)) 
end