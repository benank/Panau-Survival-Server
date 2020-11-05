class 'sAirdropManager'

function sAirdropManager:__init()
    
    -- Only one airdrop active at a time
    self.airdrop = {active = false}

    Timer.SetInterval(1000 * 60 * 10, function()
        self:CheckIfShouldCreateAirdrop()
    end)

    Events:Subscribe("PlayerChat", self, self.PlayerChat)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
    Events:Subscribe("PlayerOpenLootbox", self, self.PlayerOpenLootbox)

end

function sAirdropManager:RemoveAirdrop()
    if not self.airdrop.active then return end
    self.airdrop = {active = false}

    Network:Broadcast("airdrops/RemoveAirdrop")
    Events:Fire("airdrops/RemoveAirdrop")
end

function sAirdropManager:PlayerOpenLootbox(args)
    
    if args.has_been_opened or args.in_sz then return end
    if not self.airdrop.active or self.airdrop.remove_timer then return end

    if args.tier == 16 or args.tier == 17 or args.tier == 18 then
        self.airdrop.remove_timer = Timer.SetTimeout(AirdropConfig.RemoveTime, function()
            self:RemoveAirdrop()
        end)
    end

end

function sAirdropManager:ItemExplode(args)
    if not self.airdrop.active then return end
    if not self.airdrop.landed then return end
    if self.airdrop.doors_destroyed then return end

    if self.airdrop.type == AirdropType.Low then
        -- Any explosive can blow up Level 1 airdrops - takes 3 explosives of any kind
        if args.position:Distance(self.airdrop.position) < args.radius then
            self.airdrop.health = math.max(0, self.airdrop.health - 1)
        end

    elseif args.type == DamageEntity.C4 then
        -- Only C4 and blow up Level 2 and 3 airdrops
        if args.position:Distance(self.airdrop.position) < args.radius then
            self.airdrop.health = math.max(0, self.airdrop.health - 1)
        end
    end

    if self.airdrop.health == 0 then
        self:DoorsDestroyed(args)
    end
end

-- Called when the doors of the airdrop are destroyed
function sAirdropManager:DoorsDestroyed(args)
    if self.airdrop.doors_destroyed then return end
    if IsValid(args.player) then
        -- Give player who blew up the doors some exp
    end
    self.airdrop.doors_destroyed = true
    self:SendActiveAirdropData()
end

function sAirdropManager:PlayerChat(args)
    if not IsAdmin(args.player) then return end

    local words = args.text:split(" ")
    if words[1] == "/airdrop" and words[2] and not self.airdrop.active then
        self:BeginSpawningAirdrop(tonumber(words[2]))
    elseif words[1] == "/airdrophere" and words[2] and not self.airdrop.active then
        self:BeginSpawningAirdrop(tonumber(words[2]), args.player:GetPosition())
    end
end

function sAirdropManager:CanCreateAirdropOfType(type)

    -- Airdrop is already active
    if self.airdrop.active then
        return false
    end

    -- Not enough time has passed since the last time an airdrop of this type was dropped
    if self.airdrop.timer 
    and self.airdrop.timer:GetMinutes() < self.airdrop.interval then
        return false
    end

    if math.random() > AirdropConfig.Spawn[type].chance then
        return false
    end

    return true
end

-- Called every 10 minutes. Check player counts and in progress drops
function sAirdropManager:CheckIfShouldCreateAirdrop()

    local num_players_online = Server:GetPlayerCount()

    local spawn_type = 0 -- Airdrop type that we are going to spawn, 0 means that we are not going to spawn
    for type, data in pairs(AirdropConfig.Spawn) do
        if self:CanCreateAirdropOfType(type) then
            spawn_type = math.max(spawn_type, type) -- Max to get the highest level airdrop possible
        end
    end

    if spawn_type > 0 then
        self:BeginSpawningAirdrop(spawn_type)
    end

end

function sAirdropManager:GetTimeUntilDrop()
    return AirdropConfig.Spawn[self.airdrop.type].map_preview.time - self.airdrop.timer:GetMinutes()
end

-- Called when an airdrop is beginning to spawn. First puts out announcement ingame and on discord, 
-- adds the zone to the map, and then eventually drops it
function sAirdropManager:BeginSpawningAirdrop(type, position)

    local airdrop_data = AirdropConfig.Spawn[type]
    
    self.airdrop.type = type
    self.airdrop.active = true
    self.airdrop.landed = false
    self.airdrop.health = airdrop_data.health
    self.airdrop.timer = Timer()
    self.airdrop.interval = airdrop_data.interval
    self.airdrop.position = position or random_table_value(AirdropLocations[type])
    self.airdrop.angle = Angle(math.pi * math.random(), 0, 0)

    -- Create a "general location" of where to place the circle before the airdrop comes
    local dir = Vector3(math.random() - 0.5, 0, math.random() - 0.5):Normalized()
    self.airdrop.general_location = self.airdrop.position + dir * math.random() * airdrop_data.map_preview.size

    self:CreateMapPreview()
    self:SendActiveAirdropData()

    Timer.SetTimeout(1000 * 60 * airdrop_data.map_preview.time, function()
        self:CreateAirdrop()
    end)

end

function sAirdropManager:CreateAirdropPlane()

    local drop_position = self.airdrop.position + Vector3.Up * 500
    local direction = Vector3(math.random() - 0.5, 0, math.random() - 0.5):Normalized()
    local start_position = drop_position - direction * 500

    local plane_velo = 100

    local vehicle = Vehicle.Create({
        position = start_position,
        angle = Angle.FromVectors(Vector3.Forward, direction),
        model_id = 85,
        tone1 = Color.Black,
        tone2 = Color.Black,
        linear_velocity = direction * plane_velo,
        invulnerable = true
    })
    vehicle:SetStreamDistance(3000)
    vehicle:SetStreamPosition(start_position)

    local interval = Timer.SetInterval(1000, function()
        if IsValid(vehicle) then
            vehicle:SetLinearVelocity(direction * plane_velo)
        end
    end)

    Timer.SetTimeout(1000 * 20, function()
        Timer.Clear(interval)
        if IsValid(vehicle) then 
            vehicle:Remove()
        end
    end)

end

-- Start dropping the package on the location
function sAirdropManager:CreateAirdrop()

    self:CreateAirdropPlane()

    Events:Fire("Discord", {
        channel = "Airdrops",
        content = string.format(AirdropConfig.Messages.Delivered, self.airdrop.type)
    })

    -- Delay until the package reaches the ground
    Timer.SetTimeout(45000, function()
        self:OnAirdropLanded()
    end)

    -- Announce delivery
    self:SendActiveAirdropData()
end

function sAirdropManager:OnAirdropLanded()
    self.airdrop.landed = true
    self:SpawnLootboxes()
end

-- Spawn the lootboxes in the airdrop
function sAirdropManager:SpawnLootboxes()
    for key, object_data in pairs(AirdropObjectData) do
        if key:find("lootbox") then
            local pos = self.airdrop.position + self.airdrop.angle * object_data.offset
            local angle = self.airdrop.angle * object_data.angle_offset
            Events:Fire("inventory/CreateLootboxExternal", {
                tier = self.airdrop.type + 15,
                position = pos,
                angle = angle,
                airdrop_tier = self.airdrop.type
            })
        end
    end
end

function sAirdropManager:ClientModuleLoad(args)
    if self.airdrop.active then
        self:SendActiveAirdropData(args.player)
    end
end

function sAirdropManager:GetAirdropSyncData()
    return {
        type = self.airdrop.type,
        active = self.airdrop.active,
        time_elapsed = self.airdrop.timer:GetMinutes(),
        interval = self.airdrop.interval,
        doors_destroyed = self.airdrop.doors_destroyed,
        position = self.airdrop.position,
        angle = self.airdrop.angle,
        preview_time = AirdropConfig.Spawn[self.airdrop.type].map_preview.time,
        preview_size = AirdropConfig.Spawn[self.airdrop.type].map_preview.size,
        general_location = self.airdrop.general_location
    }
end

function sAirdropManager:SendActiveAirdropData(player)
    local data = self:GetAirdropSyncData()
    if IsValid(player) then
        Network:Send(player, "airdrops/SendSyncData", data)
    else
        Network:Broadcast("airdrops/SendSyncData", data)
    end
end

-- Create a map preview on the map and announcement for those ingame of an incoming airdrop
function sAirdropManager:CreateMapPreview()

    Events:Fire("Discord", {
        channel = "Airdrops",
        content = string.format(AirdropConfig.Messages.Incoming, self.airdrop.type, AirdropConfig.Spawn[self.airdrop.type].map_preview.time)
    })

end

sAirdropManager = sAirdropManager()