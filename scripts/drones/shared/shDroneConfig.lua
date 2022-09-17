Cell_Size = 512

DRONE_PATH_RADIUS = 500
DRONE_TARGET_DIST_STOP = 100
DRONE_CATCH_UP_SPEED = 50

Drone_Follow_Offsets = 
{
    x = {min = 7, max = 15},
    y = {min = 2, max = 15},
    z = {min = 7, max = 15}
}

function GetRandomFollowOffset(sight_range)
    local dir = Vector3(0.5 - math.random(), 0, 0.5 - math.random()):Normalized()

    local max = math.max(5, math.random() * sight_range)
    dir.x = dir.x * (max - Drone_Follow_Offsets.x.min) * math.random()
    dir.x = dir.x < 0 and dir.x - Drone_Follow_Offsets.x.min or dir.x + Drone_Follow_Offsets.x.min

    dir.y = (Drone_Follow_Offsets.y.max - Drone_Follow_Offsets.y.min) * math.random() + Drone_Follow_Offsets.y.min

    dir.z = dir.z * (max - Drone_Follow_Offsets.z.min) * math.random()
    dir.z = dir.z < 0 and dir.z - Drone_Follow_Offsets.z.min or dir.z + Drone_Follow_Offsets.z.min

    return dir
end

Drone_Configuration = 
{
    speed = {base = 4, per_level = 0.16},
    damage_modifier = {base = 0.5, per_level = 0.00055},
    has_rockets = {base = false, base_chance = 0, chance_per_level = 0.01},
    fire_time_min = {base = 0.15, per_level = 0.005},
    fire_time_max = {base = 0.5, per_level = 0.02},
    fire_rate_interval = {base = 5, per_level = -0.02},
    rocket_fire_rate = {base = 0.1, per_level = 0.025},
    attack_on_sight = {base = false, base_chance = 0, chance_per_level = 0.01},
    accuracy_modifier = {base = 0.02, per_level = 0.02},
    health = {base = 30, per_level = 13},
    sight_range = {base = 20, per_level = 1.75},
    attack_range = {base = 6, per_level = 0.75},
    airstrike = {base = 0.0005, per_level = 0.0008},
    grenade = {base = 0.001, per_level = 0.00025},
    grenade_fire_rate = {base = 12, per_level = -0.035}
}

DroneState = 
{
    Wandering = 1, -- Peacefully wandering
    Pursuing = 2, -- Actively pursuing a target
    Destroyed = 3, -- Drone has been destroyed
    Static = 4 -- Drone is not moving and hovers in one place
}

--[[
    Gets a drone configuration depending on the drone level

    returns (in table):

        speed (number): speed of the drone
        damage_modifier (number): damage modifier of the drone bullets
        has_rockets (bool): whether or not the drone has a rocket launcher
        fire_rate (number): bullets the drone can fire per second
        rocket_fire_rate (number): fire rate of the rockets per second
        attack_on_sight (bool): whether or not this drone will attack you on sight, or only retaliate
        accuracy_modifier (number): modifier for the angle rotation slerp to be more or less accurate
        health (number): maximum health of the drone

]]

function GetDroneConfiguration(level)

    local config = {}

    for config_name, data in pairs(Drone_Configuration) do
        if data.per_level then
            config[config_name] = data.base + data.per_level * level
        elseif data.chance_per_level then
            config[config_name] = math.random() < (data.base_chance + data.chance_per_level * level)
                and (not data.base) or (data.base)
        end
    end

    return config

end