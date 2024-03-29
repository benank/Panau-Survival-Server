class 'sDrone'

local DRONE_ID = 0
local function GetDroneId()
    DRONE_ID = DRONE_ID + 1
    return DRONE_ID
end

function sDrone:__init(args)

    self.id = GetDroneId()
    self.position = args.position -- Approximate position of the drone in the world
    self.region = args.region or GetClosestRegion(self.position)
    self.level = args.level or GetLevelFromRegion(self.region)

    self.tether_position = args.tether_position or DroneRegions[self.region].center -- Position used for tether checks
    self.tether_range = args.tether_range or DroneRegions[self.region].radius + 1000 -- Max distance travelled from initial spawn position

    self.current_path = {} -- Table of points that the drone is currently pathing through
    self.current_path_index = 1 -- Current index of the path the drone is on

    self.config = GetDroneConfiguration(self.level)

    if args.config then
        for key, value in pairs(args.config) do
            self.config[key] = value
        end
    end

    self.target = nil -- Current active target that the drone is pursuing
    self.target_offset = GetRandomFollowOffset(self.config.sight_range) -- Offset from the target the drone flies at

    self.max_health = self.config.health
    self.health = self.max_health

    self.state = args.state or DroneState.Wandering

    self.host = nil -- Player who currently "controls" the drone and dictates its pathfinding
    self.players_who_damaged = {} -- List of players who have damaged this drone

    self.has_update = true
    self.updates = {}
    self.static = args.static
    self.airstrike_timer = Timer()
    self.grenade_timer = Timer()
    self.hp_remove_timer = Timer()

    if self.static then
        self.state = DroneState.Static
    end
    
    self.group = args.group

    -- Remove drone after time period
    if self.timeout then
        Thread(function()
            Timer.Sleep(self.timeout)
            if not self.removed then
                self:Remove()
            end
        end)
    end

    self.network_subs = 
    {
        Network:Subscribe("drones/DespawnDrone" .. tostring(self.id), self, self.DespawnDrone),
        Network:Subscribe("drones/AttackOnSightTarget" .. tostring(self.id), self, self.AttackOnSightTarget),
        Network:Subscribe("drones/sync/one" .. tostring(self.id), self, self.OneHostSync)
    }

    if self.region then
        sDroneManager.drone_counts_by_region[self.region] = sDroneManager.drone_counts_by_region[self.region] + 1
    end
    sDroneManager.drones_by_id[self.id] = self
    self:UpdateCell()

    Network:Broadcast("Drones/SingleSync", self:GetSyncData())

end

function sDrone:ReconsiderLoop()
    local updated = self:ReconsiderHost()
    updated = self:ReconsiderTarget() or updated
    if updated then
        self:Sync({
            state = self.state
        })
    end
    
    self:DamageOwnedDroneLoop()
end

function sDrone:DamageOwnedDroneLoop()
    if not self.config.player_owned then return end
    if self.hp_remove_timer:GetSeconds() < 60 then return end
    
    self.hp_remove_timer:Restart()
    self.health = math.max(0, self.health - DRONE_DAMAGE_PER_MINUTE_OWNED)
    if self.health == 0 then
        self:Destroyed()
    end

    self:Sync({
        state = self.state,
        health = self.health,
        target = self.target
    })

end

function sDrone:PursueTarget(target, new_attacker)
    self.target = self:IsPlayerAValidTarget(target) and target or nil

    if not IsValid(self.target) then
        if self.static then
            self.state = DroneState.Static
            self.position = self.tether_position
        else
            self.state = DroneState.Wandering
        end
    else
        self.state = DroneState.Pursuing
    end

    self.current_path = {}
    self.current_path_index = 1

    self:Sync({
        state = self.state,
        target = self.target,
        position = self.position,
        current_path = self.current_path,
        current_path_index = self.current_path_index
    })
end

function sDrone:AttackOnSightTarget(args, player)
    if self.target then return end
    self:PursueTarget(player, true)
end

-- Updates the drone's cell in DroneManager cells
function sDrone:UpdateCell()
    local cell = GetCell(self.position, Cell_Size)
    if self.cell then
        VerifyCellExists(sDroneManager.drones, self.cell)
        sDroneManager.drones[self.cell.x][self.cell.y] = nil
    end
    
    self.cell = cell
    VerifyCellExists(sDroneManager.drones, self.cell)
    sDroneManager.drones[self.cell.x][self.cell.y][self.id] = self

    if not self.cell or self.cell.x ~= cell.x or self.cell.y ~= cell.y then
        self.updated = true
        self.updates.position = self.position
    end
end

-- Take a look at the current target and see if they still exist
function sDrone:ReconsiderTarget()
    if self.state ~= DroneState.Pursuing then return end

    if not self:IsPlayerAValidTarget(self.target) then
        self:PursueTarget(self:FindNewTarget(), true)
        return true
    end

end

function sDrone:IsPlayerFriendly(player)
    return self.config.owner_id == tostring(player:GetSteamId()) or AreFriends(player, self.config.owner_id)
end

function sDrone:IsPlayerAValidTarget(player, distance)
    local out_of_range = Distance2D(self.position, self.tether_position) > self.tether_range

    return IsValid(player) and
        not player:GetValue("Invisible") and 
        not player:GetValue("StealthEnabled") and
        player:GetHealth() > 0 and
        not player:GetValue("Loading") and
        not player:GetValue("dead") and
        not player:GetValue("InSafezone") and
        not self:IsPlayerFriendly(player) and
        Distance2D(self.position, player:GetPosition()) < (distance or 500)
        and not out_of_range
end

-- Finds a new target from recently damaged or nearby players
function sDrone:FindNewTarget()
    local out_of_range = Distance2D(self.position, self.tether_position) > self.tether_range
    if out_of_range then return end

    for steam_id, _ in pairs(self.players_who_damaged) do
        local player = sDroneManager.players[steam_id]
        if self:IsPlayerAValidTarget(player, 200) then
            return player
        end
    end

    -- No recently damaged players found, so let's look for nearby players because we're mad
    VerifyCellExists(sDroneManager.player_cells, self.cell)
    local players_in_cell = sDroneManager.player_cells[self.cell.x][self.cell.y]

    for _, player in pairs(players_in_cell) do
        if self:IsPlayerAValidTarget(player, 75) then
            return player
        end
    end
end

-- Take a look at the current host and see if there is a better player
function sDrone:ReconsiderHost()
    if self:IsDestroyed() then return end

    local should_reconsider_host = false

    if IsValid(self.host) then
        -- Host is far away
        if Distance2D(self.host:GetPosition(), self.position) > 1500 then
            should_reconsider_host = true
        end
    else
        -- Host does not exist
        should_reconsider_host = true
    end

    if should_reconsider_host then
        self:SetHost(self:FindNewHost() or self.host)
        return true
    end

end

function sDrone:SetHost(player)
    self.host = player
    self:Sync()
end

function sDrone:FindNewHost()
    if self:IsDestroyed() then return end
    local nearby_players = sDroneManager:GetNearbyPlayersInCell(GetCell(self.position, Cell_Size))

    if count_table(nearby_players) == 0 then return end

    local closest = 
    {
        player = nearby_players[1],
        dist = nearby_players[1]:GetPosition():Distance(self.position)
    }

    for _, player in pairs(nearby_players) do
        local dist = player:GetPosition():Distance(self.position)
        if dist < closest.dist then
            closest.player = player
            closest.dist = dist
        end
    end

    if not IsValid(closest.player) then return end

    if IsValid(self.host) and closest.player == self.host then return end

    return closest.player

end

-- Called by clients when finding a path fails
function sDrone:DespawnDrone(args, player)
    if self.static then return end
    self:Remove()
end

function sDrone:Remove()
    self.removed = true

    if not self.destroyed then
        Network:Broadcast("Drones/Remove", {id = self.id})
    end

    for _, sub in pairs(self.network_subs) do
        Network:Unsubscribe(sub)
    end

    self.network_subs = {}
    
    -- Remove from drone list
    if sDroneManager.drones[self.cell.x] and sDroneManager.drones[self.cell.x][self.cell.y] then
        sDroneManager.drones[self.cell.x][self.cell.y][self.id] = nil
    end
    
    sDroneManager.drones_by_id[self.id] = nil
    if self.region then
        sDroneManager.drone_counts_by_region[self.region] = sDroneManager.drone_counts_by_region[self.region] - 1
    end
end

-- Called when a player destroys a drone
function sDrone:Destroyed(args)
    if self:IsDestroyed() then return end
    
    self.state = DroneState.Destroyed

    args = args or {}
    local exp_split = {}
    for steam_id, damage_dealt in pairs(self.players_who_damaged) do
        exp_split[steam_id] = math.clamp(damage_dealt / self.max_health, 0, 1)
        sDroneManager:AddDroneKillToPlayer(sDroneManager.players[steam_id])
    end
    
    if self.config.owner_id then
        local message = string.format("Your Drone (Lv %d) was destroyed.", self.level)
        if IsValid(args.player) then
            message = string.format("Your Drone (Lv %s) was destroyed by %s.", 
                self.level, tostring(args.player:GetName()))
        end
        
        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = self.config.owner_id,
            message = message,
            color = Color(200, 0, 0)
        }) 
    end

    Events:Fire("drones/DroneDestroyed", {
        player = args.player,
        exp_split = exp_split,
        drone_level = self.level,
        damage_entity = args.type or DamageEntity.None,
        position = self.position
    })
    
    Timer.SetTimeout(1000, function()
        self:Remove()
    end)
end

function sDrone:TryToFireAirstrike(position)
    
    if self.airstrike_timer:GetSeconds() < 15 then return end
    
    if self.level < 15 then return end
    
    if math.random() < self.config.airstrike then
        Events:Fire("drones/CreateAirstrike", {
            position = position,
            owner_id = self.config.owner_id
        })
        self.airstrike_timer:Restart()
    end
        
end

function sDrone:TryToFireGrenade(grenade_position)
    
    if not IsValid(self.target) then return end
    
    local position = self.target:GetPosition()
    local distance = grenade_position:Distance(position)
    Events:Fire("drones/CreateGrenade", {
        drone_position = grenade_position,
        position = position,
        distance = distance,
        owner_id = self.config.owner_id
    })

end

function sDrone:Damage(args)
    if self:IsDestroyed() then return end

    local steam_id = tostring(args.player:GetSteamId())
    local new_attacker = not self.players_who_damaged[steam_id]
    if not self.players_who_damaged[steam_id] then
        self.players_who_damaged[steam_id] = 0
    end

    self.players_who_damaged[steam_id] = self.players_who_damaged[steam_id] + args.damage
    self.health = math.max(0, self.health - args.damage)
    self:PursueTarget(args.player, new_attacker)
    
    if self:IsPlayerAValidTarget(args.player, 200) then
        self:TryToFireAirstrike(args.player:GetPosition())
    end

    if self.health == 0 then
        self:Destroyed(args)
    end

    self:Sync({
        state = self.state,
        health = self.health,
        target = self.target
    })

end

function sDrone:IsDestroyed()
    return self.state == DroneState.Destroyed
end

function sDrone:OneHostSync(args, player)
    if self:IsDestroyed() then return end
    if not IsValid(self.host) or player ~= self.host then return end
    -- Update some aspects from player
    self.target_offset = args.offset or self.target_offset
    self.position = args.position or self.position
    if args.position then
        self:UpdateCell()
    end
    self:Sync({
        target_offset = self.target_offset,
        position = self.position
    })

    self.current_path = args.path or self.current_path
    self.current_path_index = args.path_index or self.current_path_index
    if args.path then
        self:Sync({
            current_path = self.current_path,
            current_path_index = self.current_path_index
        })
    end

    if args.path_index then
        self:Sync({
            current_path_index = self.current_path_index,
            position = self.position
        })
    end
    
    if args.grenade then
        self:TryToFireGrenade(args.grenade_position) 
    end
    
end

function sDrone:UpdateApplied()
    self.has_update = false
    self.updates = {}
end

-- Syncs the drone to a specified player, or if none specified, all players in nearby cells
function sDrone:Sync(_data)
    data = _data or {}
    data.host = self.host
    data.target = self.target
    data.state = self.state
    data.id = self.id

    self.has_update = true
    for key, value in pairs(_data or {}) do
        self.updates[key] = value
    end

end

-- Gets only positional sync data of the drone
function sDrone:GetPathSyncData()

    return {
        id = self.id,
        position = self.position,
        target = self.target,
        target_offset = self.target_offset,
        tether_range = self.tether_range,
        tether_position = self.tether_position,
        current_path = self.current_path,
        current_path_index = self.current_path_index,
        height = self.height
    }

end

-- Gets all sync data of the drone
function sDrone:GetSyncData()

    return {
        id = self.id,
        level = self.level,
        config = self.config,
        max_health = self.max_health,
        health = self.health,
        region = self.region,
        path_data = self:GetPathSyncData(),
        host = self.host,
        state = self.state,
        static = self.static
    }

end