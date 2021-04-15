class 'SAM'

function SAM:__init(args)
    self.id = args.id
    self.base_level = args.base_level
    self.level = math.ceil(self.base_level * (1 + math.random() * 0.25))
    self.position = args.position
    self.cell = args.cell
    self.config = GetSAMConfiguration(self.level)
    self.health = self.config.MaxHealth
    self.hacked_owner = ""
    self.destroyed = false
    self.fire_timer = Server:GetElapsedSeconds()
end

function SAM:CanFire()
     return Server:GetElapsedSeconds() - self.fire_timer > self.config.FireInterval
end

function SAM:Fire(player, vehicle)
    local data = {
        sam_id = self.id,
        player_id = player:GetId(),
        vehicle_id = vehicle:GetId()
    }
    Network:Send(player, "sams/SAMFire", data)
    Network:SendNearby(player, "sams/SAMFire", data)
    self.fire_timer = Server:GetElapsedSeconds()
end

function SAM:Damage(amount, player)
    if self.destroyed then return end
    self.health = math.max(0, self.health - amount) 
    if self.health == 0 then
        self:Destroyed(player)
    else
        Network:Broadcast("sams/SyncSAM", self:GetSyncData("health"))
    end
end

function SAM:Destroyed(player)
    -- Called when the SAM is destroyed by a player
    self.destroyed = true
    
    Network:Broadcast("sams/SyncSAM", self:GetSyncData("destroyed")) 
    
    if IsValid(player) then
        Events:Fire("sams/SamDestroyed", {
            sam_level = self.level,
            player = player
        })
    end
    
    -- TODO: respawn SAM later
    Thread(function()
        Timer.Sleep(1000 * 60 * 60)
        self:Respawn()
    end)
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