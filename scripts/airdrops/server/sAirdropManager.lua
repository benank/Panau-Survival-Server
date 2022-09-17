class 'sAirdropManager'

function sAirdropManager:__init()
    
    -- Only one airdrop active at a time
    self.airdrop_timer = Timer()
    self.airdrop = {active = false}

    Timer.SetInterval(1000 * 60 * 10, function()
        self:CheckIfShouldCreateAirdrop()
    end)

    Events:Subscribe("PlayerChat", self, self.PlayerChat)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("items/ItemExplode", self, self.ItemExplode)
    Events:Subscribe("PlayerOpenLootbox", self, self.PlayerOpenLootbox)
    Events:Subscribe("items/UseAirdrop", self, self.UseAirdrop)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function sAirdropManager:UseAirdrop(args)

    if self.airdrop.active then
        Chat:Send(args.player, "Cannot call an airdrop while another airdrop is still active.", Color.Red)
        return
    end

    local airdrop_type = tonumber(args.player_iu.item.custom_data.level)
    if not AirdropConfig.Spawn[airdrop_type] then
        Chat:Send(args.player, "Something went terribly wrong. Please contact a Staff member.", Color.Red)
        return
    end

    self:BeginSpawningAirdrop(airdrop_type, args.position)

    Inventory.RemoveItem({
        item = args.player_iu.item,
        index = args.player_iu.index,
        player = args.player
    })

end

function sAirdropManager:ModuleUnload()
    self:RemoveAirdrop()
end

function sAirdropManager:RemoveAirdrop()
    if not self.airdrop.active then return end
    local interval = self.airdrop.interval
    self.airdrop = {active = false, interval = interval}

    Network:Broadcast("airdrops/RemoveAirdrop")
    Events:Fire("airdrops/RemoveAirdrop")
    Events:Fire("Drones/RemoveDronesInGroup", {group = "airdrop"})
end

function sAirdropManager:PlayerOpenLootbox(args)
    
    if args.has_been_opened or args.in_sz then return end
    if not self.airdrop.active or self.airdrop.remove_timer then return end

    if args.tier == 16 or args.tier == 17 or args.tier == 18 then

        if not self.airdrop.doors_destroyed then
            args.player:SetHealth(0)
            Events:Fire("Discord", {
                channel = "Hitdetection",
                content = string.format("%s [%s] opened an airdrop lootbox without blowing the doors first. Killed player.", 
                    args.player:GetName(), tostring(args.player:GetSteamId()))
            })
            return
        end

        self.airdrop.remove_timer = Timer.SetTimeout(AirdropConfig.RemoveTime, function()
            self:RemoveAirdrop()
        end)
    end

end

function sAirdropManager:ItemExplode(args)
    if not self.airdrop.active then return end
    if not self.airdrop.landed then return end
    if self.airdrop.doors_destroyed then return end
    
    -- Only C4 and blow up airdrops
    if args.type ~= DamageEntity.C4 then return end

    -- Announce airdrop coords when it is hit by an explosive
    if not self.airdrop.precise_announce and args.position:Distance(self.airdrop.position) < args.radius then
        self.airdrop.precise_announce = true
        self:SendActiveAirdropData()
        
        Chat:Broadcast("--------------------------------------------------------------", Color.Orange)
        Chat:Broadcast(" ", Color.Red)
        Chat:Broadcast("MAP UPDATED WITH PRECISE AIRDROP COORDS.", Color.Red)
        Chat:Broadcast(" ", Color.Red)
        Chat:Broadcast("--------------------------------------------------------------", Color.Orange)
        
        Timer.SetTimeout(3000 + 5000 * math.random(), function()
            self:CreateAirdropDrones()
        end)

    end

    if args.position:Distance(self.airdrop.position) < args.radius then
        self.airdrop.health = math.max(0, self.airdrop.health - 1)
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

    Chat:Broadcast("--------------------------------------------------------------", Color.Orange)
    Chat:Broadcast(" ", Color.Red)
    if IsValid(args.player) then
        Chat:Broadcast(string.format("AIRDROP DOORS HAVE BEEN DESTROYED BY %s!", args.player:GetName()), Color.Red)
    else
        Chat:Broadcast("AIRDROP DOORS HAVE BEEN DESTROYED!", Color.Red)
    end
    Chat:Broadcast(" ", Color.Red)
    Chat:Broadcast("--------------------------------------------------------------", Color.Orange)

    -- Spawn more drones when doors are blown on Level 3 airdrop
    if self.airdrop.type == AirdropType.High then
        self:CreateAirdropDrones(true)
        
        Events:Fire("items/CreateGrenade", {
            position = self.airdrop.position,
            grenade_type = "Molotov",
            fusetime = 0,
            velocity = Vector3.Zero,
            owner_id = "Airdrop"
        })
        
        Timer.SetTimeout(5000, function()
            Events:Fire("items/CreateGrenade", {
                position = self.airdrop.position,
                grenade_type = "Molotov",
                fusetime = 0,
                velocity = Vector3.Zero,
                owner_id = "Airdrop"
            })
        end)
        
        Timer.SetTimeout(15000, function()
            Events:Fire("drones/CreateAirstrike", {
                airstrike_name = "Area Bombing",
                position = self.airdrop.position,
                num_bombs = 100,
                radius = 750
            })
            
            Events:Fire("items/CreateGrenade", {
                position = self.airdrop.position,
                grenade_type = "Toxic Grenade",
                fusetime = 0,
                velocity = Vector3.Zero,
                owner_id = "Airdrop"
            })
        end)
        
        Timer.SetTimeout(60000, function()
            Events:Fire("drones/CreateAirstrike", {
                airstrike_name = "Area Bombing",
                position = self.airdrop.position,
                num_bombs = 250,
                radius = 500
            })
        end)
        
    elseif self.airdrop.type == AirdropType.Mid then
        
        Timer.SetTimeout(5000, function()
            Events:Fire("drones/CreateAirstrike", {
                airstrike_name = "Area Bombing",
                position = self.airdrop.position,
                num_bombs = 150,
                radius = 300
            })
        end)
    end
    
    Events:Fire("items/CreateGrenade", {
        position = self.airdrop.position,
        grenade_type = "Toxic Grenade",
        fusetime = 0,
        velocity = Vector3.Zero,
        owner_id = "Airdrop"
    })
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

    -- Not enough players online
    if Server:GetPlayerCount() < AirdropConfig.Spawn[type].min_players then
        return false
    end

    if math.random() > AirdropConfig.Spawn[type].chance then
        return false
    end

    return true
end

-- Called every 10 minutes. Check player counts and in progress drops
function sAirdropManager:CheckIfShouldCreateAirdrop()

    -- Not enough time has passed since the last time an airdrop was dropped
    if self.airdrop.interval 
    and self.airdrop_timer:GetMinutes() < self.airdrop.interval then
        return
    end

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
    self.airdrop_timer = Timer()
    self.airdrop.interval = airdrop_data.interval
    self.airdrop.position = position or random_table_value(AirdropLocations[type]) or random_table_value(AirdropLocations[type])
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

    -- Delay until the package reaches the ground
    Timer.SetTimeout(45000 + 6000, function()
        self:OnAirdropLanded()
        -- Announce delivery
        self:SendActiveAirdropData()

        Events:Fire("Discord", {
            channel = "Airdrops",
            content = string.format(AirdropConfig.Messages.Delivered, self.airdrop.type)
        })
        
        -- Clear airdrops if it has been more than 2 hours since drop without action or players
        Timer.SetTimeout(1000 * 60 * 60 * 2, function()
            if Server:GetPlayerCount() == 0 and self.airdrop.active and not self.airdrop.doors_destroyed then
                self:RemoveAirdrop()
            end
        end)

    end)

end

function sAirdropManager:CreateAirdropDrones(second_wave)
    local drone_data = AirdropConfig.Spawn[self.airdrop.type].drones
    local num_drones = math.random(drone_data.amount.min, drone_data.amount.max)
    
    for i = 1, num_drones do
        local drone_level = math.random(drone_data.level.min, drone_data.level.max)
        local height = math.random() * 15 + 4
        if second_wave then
            height = math.random() * 6
        end

        local position = self.airdrop.position + Vector3(math.random() * 20 - 10, height, math.random() * 20 - 10)

        Timer.SetTimeout(3000 + 15000 * math.random(), function()
            Events:Fire("Drones/SpawnDrone", {
                level = drone_level,
                static = true,
                position = position,
                tether_position = position,
                tether_range = 300,
                config = {
                    attack_on_sight = true
                },
                group = "airdrop"
            })
        end)
    end
end

function sAirdropManager:OnAirdropLanded()
    self.airdrop.landed = true
    self:SpawnLootboxes()

    Chat:Broadcast("--------------------------------------------------------------", Color.Orange)
    Chat:Broadcast(" ", Color.Red)
    Chat:Broadcast("AIRDROP HAS LANDED.", Color.Red)
    Chat:Broadcast(" ", Color.Red)
    Chat:Broadcast("--------------------------------------------------------------", Color.Orange)
end

-- Spawn the lootboxes in the airdrop
function sAirdropManager:SpawnLootboxes()
    for key, object_data in pairs(AirdropObjectData) do
        if key:find("lootbox") then
            local pos = self.airdrop.position + self.airdrop.angle * object_data.offset
            local angle = self.airdrop.angle * object_data.angle_offset
            local locked = self.airdrop.type == 3
            
            if self.airdrop.type == 2 then
                locked = math.random() < 0.25
            end
            
            Events:Fire("inventory/CreateLootboxExternal", {
                tier = self.airdrop.type + 15,
                position = pos,
                angle = angle,
                airdrop_tier = self.airdrop.type,
                locked = locked
            })
        end
    end
end

function sAirdropManager:ClientModuleLoad(args)
    if self.airdrop.active then
        self:SendActiveAirdropData(args.player)

        Chat:Send(args.player, "--------------------------------------------------------------", Color.Orange)
        Chat:Send(args.player, " ", Color.Red)
        Chat:Send(args.player, "AIRDROP IN PROGRESS. SEE MAP FOR DETAILS.", Color.Red)
        Chat:Send(args.player, " ", Color.Red)
        Chat:Send(args.player, "--------------------------------------------------------------", Color.Orange)
    end
end

function sAirdropManager:GetAirdropSyncData()
    return {
        type = self.airdrop.type,
        active = self.airdrop.active,
        time_elapsed = self.airdrop.timer:GetMinutes() - 0.1,
        interval = self.airdrop.interval,
        doors_destroyed = self.airdrop.doors_destroyed,
        position = self.airdrop.position,
        angle = self.airdrop.angle,
        preview_time = AirdropConfig.Spawn[self.airdrop.type].map_preview.time,
        preview_size = AirdropConfig.Spawn[self.airdrop.type].map_preview.size,
        general_location = self.airdrop.general_location,
        precise_announce = self.airdrop.precise_announce
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