class 'sDrone'

local DRONE_ID = 0
local function GetDroneId()
    DRONE_ID = DRONE_ID + 1
    return DRONE_ID
end

function sDrone:__init(args)

    self.id = GetDroneId()
    self.level = args.level
    self.position = args.position -- Approximate position of the drone in the world

    self.spawn_position = args.spawn_position -- Initial spawn position
    self.tether_range = args.tether_range -- Max distance travelled from initial spawn position

    self.target_position = self.position -- Target position that the drone is currently travelling to
    self.target = nil -- Current active target that the drone is pursuing
    self.target_offset = Vector3() -- Offset from the target the drone flies at

    self.current_path = {} -- Table of points that the drone is currently pathing through
    self.current_path_index = 1 -- Current index of the path the drone is on

    self.config = GetDroneConfiguration(self.level)

    self.max_health = self.config.health
    self.health = self.max_health

    self.state = DroneState.Wandering
    self.personality = self.config.attack_on_sight and DronePersonality.Hostile or DronePersonality.Defensive

    self.host = nil -- Player who currently "controls" the drone and dictates its pathfinding

    self.host_interval = Timer.SetInterval(2500, function()
        local updated = self:ReconsiderHost()
        updated = self:ReconsiderTarget() or updated
        if updated then self:Sync() end
    end)

end

-- Take a look at the current target and see if they still exist
function sDrone:ReconsiderTarget()

    if not IsValid(target) or 
    self.position:Distance(target:GetPosition()) > 500 or
    self.position:Distance(self.spawn_position) > self.tether_range then
        self.target = nil
        self.state = DroneState.Wandering
        return true
    end

end

-- Take a look at the current host and see if there is a better player
function sDrone:ReconsiderHost()

    local should_reconsider_host = false

    if IsValid(self.host) then
        -- Host is far away
        if self.host:GetPosition():Distance(self.position) > 1000 then
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

    return closest.player

end

function sDrone:Remove()
    Timer.Clear(self.host_interval)
end

-- Called when a player destroys a drone
function sDrone:Destroyed(args)
    if self.state == DroneState.Destroyed then return end

    -- Give args.player exp, set it to destroyed, sync to players

    self.state = DroneState.Destroyed

    self:Sync()

    Timer.SetTimeout(5000, function()
        self:Remove()
    end)
end

function sDrone:Damage(args)

    self.health = math.max(0, self.health - args.damage)

    self:Sync()

    if self.health == 0 then
        self:Destroyed(args)
    end

end

-- Syncs the drone to a specified player, or if none specified, all players in nearby cells
function sDrone:Sync(player)

    if IsValid(player) then
        Network:Send(player, "Drones/SingleSync", self:GetSyncData())
    else
        local nearby_players = sDroneManager:GetNearbyPlayersInCell(GetCell(self.position, Cell_Size))
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
        current_path = self.current_path,
        current_path_index = self.current_path_index,
        state = self.state,
        host = self.host
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
        path_data = self:GetPathSyncData()
    }

end

function sDrone:ToString()
    return string.format("")
end