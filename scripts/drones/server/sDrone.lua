class 'sDrone'

local DRONE_ID = 0
local function GetDroneId()
    DRONE_ID = DRONE_ID + 1
    return DRONE_ID
end

function sDrone:__init(args)

    output_table(args)
    self.id = GetDroneId()
    self.region = args.region
    self.level = GetLevelFromRegion(self.region)
    self.position = args.position -- Approximate position of the drone in the world

    self.tether_position = DroneRegions[self.region].center -- Position used for tether checks
    self.tether_range = DroneRegions[self.region].radius -- Max distance travelled from initial spawn position

    self.target_position = self.position -- Target position that the drone is currently travelling to
    self.target = nil -- Current active target that the drone is pursuing
    self.target_offset = Vector3() -- Offset from the target the drone flies at

    self.current_path = {} -- Table of points that the drone is currently pathing through
    self.current_path_index = 1 -- Current index of the path the drone is on

    self.config = GetDroneConfiguration(self.level)
    print("Drone config")
    output_table(self.config)

    self.max_health = self.config.health
    self.health = self.max_health

    self.state = DroneState.Wandering
    self.personality = self.config.attack_on_sight and DronePersonality.Hostile or DronePersonality.Defensive

    self.host = nil -- Player who currently "controls" the drone and dictates its pathfinding

    self.network_subs = 
    {
        Network:Subscribe("drones/sync/full" .. tostring(self.id), self, self.FullHostSync),
        Network:Subscribe("drones/sync/one" .. tostring(self.id), self, self.OneHostSync)
    }

    self:UpdateCell()

    -- Find host upon creation
    self:ReconsiderHost()

    self.host_interval = Timer.SetInterval(1500, function()
        local updated = self:ReconsiderHost()
        updated = self:ReconsiderTarget() or updated
        if updated then self:Sync() end
    end)

    self:Sync()

end

-- Updates the drone's cell in DroneManager cells
function sDrone:UpdateCell()
    local cell = GetCell(self.position, Cell_Size)
    if not self.cell or self.cell.x ~= cell.x or self.cell.y ~= cell.y then
        if self.cell then
            sDroneManager.drones[self.cell.x][self.cell.y] = nil
        end

        self.cell = cell
        VerifyCellExists(sDroneManager.drones, self.cell)
        sDroneManager.drones[self.cell.x][self.cell.y][self.id] = self
    end
end

-- Take a look at the current target and see if they still exist
function sDrone:ReconsiderTarget()
    if self.state ~= DroneState.Pursuing then return end

    if not IsValid(self.target) or 
    self.target:GetHealth() <= 0 or
    self.target:GetValue("InSafezone") or
    self.position:Distance(self.target:GetPosition()) > 500 or
    self.position:Distance(self.tether_position) > self.tether_range then
        self.target = nil
        self.state = DroneState.Wandering
        return true
    end

end

-- Take a look at the current host and see if there is a better player
function sDrone:ReconsiderHost()
    if self:IsDestroyed() then return end

    local should_reconsider_host = false

    if IsValid(self.host) then
        -- Host is far away
        if self.host:GetPosition():Distance(self.position) > 500 then
            should_reconsider_host = true
        end
    else
        -- Host does not exist
        should_reconsider_host = true
    end

    if should_reconsider_host then
        self.host = self:FindNewHost()
        return true
    end

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

    _debug("New host: " .. tostring(closest.player))
    return closest.player

end

function sDrone:Remove()
    Timer.Clear(self.host_interval)

    for _, sub in pairs(self.network_subs) do
        Network:Unsubscribe(sub)
    end

    self.network_subs = {}
    
    -- Remove from drone list
    if sDroneManager.drones[self.cell.x] and sDroneManager.drones[self.cell.x][self.cell.y] then
        sDroneManager.drones[self.cell.x][self.cell.y][self.id] = nil
    end
end

-- Called when a player destroys a drone
function sDrone:Destroyed(args)
    if self:IsDestroyed() then return end

    self.state = DroneState.Destroyed

    Events:Fire("drones/DroneDestroyed", {
        player = args.player,
        drone_level = self.level
    })
    
    self:Sync()

    Timer.SetTimeout(1000, function()
        self:Remove()
    end)
end

function sDrone:Damage(args)
    if self:IsDestroyed() then return end

    print(string.format("Drone damaged for %.2f damage by %s", args.damage, tostring(args.player)))
    self.health = math.max(0, self.health - args.damage)
    self.target = args.player
    self.state = DroneState.Pursuing

    if self.health == 0 then
        self:Destroyed(args)
    else
        self:Sync()
    end

end

function sDrone:IsDestroyed()
    return self.state == DroneState.Destroyed
end

function sDrone:FullHostSync(args, player)
    -- Update everything from player
end

function sDrone:OneHostSync(args, player)
    if self:IsDestroyed() then return end
    -- Update some aspects from player
    if args.type == "offset" then
        self.offset = args.offset
        self.position = args.position
        self:UpdateCell()
    elseif args.type == "path" then
        self.current_path = args.path or self.path
        self.current_path_index = args.path_index or self.current_path_index
    elseif args.type == "path_index" then
        self.current_path_index = args.path_index or self.current_path_index
    end

    -- TODO: only sync changed data
    self:Sync()
end

-- Syncs the drone to a specified player, or if none specified, all players in nearby cells
function sDrone:Sync(player)

    if IsValid(player) then
        Network:Send(player, "Drones/SingleSync", self:GetSyncData())
    else
        local nearby_players = sDroneManager:GetNearbyPlayersInCell(self.cell)
        Network:SendToPlayers(nearby_players, "Drones/SingleSync", self:GetSyncData())
    end

end

-- Gets only positional sync data of the drone
function sDrone:GetPathSyncData()

    return {
        id = self.id,
        position = self.position,
        target_position = self.target_position,
        target = self.target,
        target_offset = self.target_offset,
        tether_range = self.tether_range,
        tether_position = self.tether_position,
        current_path = self.current_path,
        current_path_index = self.current_path_index
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
        personality = self.personality,
        path_data = self:GetPathSyncData(),
        host = self.host,
        state = self.state
    }

end