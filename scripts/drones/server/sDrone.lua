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

    self.config = GetDroneConfiguration(self.level)

    self.max_health = self.config.health
    self.health = self.max_health

    self.state = DroneState.Wandering
    self.personality = self.config.attack_on_sight and DronePersonality.Hostile or DronePersonality.Defensive

    self.controller = nil -- Player who currently "controls" the drone and dictates its pathfinding

end

-- Called when a player destroys a drone
function sDrone:Destroyed(args)
    -- Give args.player exp, set it to destroyed, sync to players

    self.state = DroneState.Destroyed

    self:Sync()
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

function sDrone:GetSyncData()

    return {
        id = self.id,
        position = self.position,
        level = self.level,
        config = self.config
    }

end

function sDrone:ToString()
    return string.format("")
end