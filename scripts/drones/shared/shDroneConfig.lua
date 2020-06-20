Cell_Size = 512

Drone_Configuration = 
{
    speed = {base = 7, per_level = 0.5},
    damage_modifier = {base = 1, per_level = 0.1},
    has_rockets = {base = false, base_chance = 0.02, chance_per_level = 0.02},
    fire_rate = {base = 10, per_level = 1},
    rocket_fire_rate = {base = 0.1, per_level = 0.025},
    attack_on_sight = {base = false, base_chance = 0.05, chance_per_level = 0.05},
    accuracy_modifier = {base = 1, per_level = -0.01},
    health = {base = 50, per_level = 20}
}

DroneState = 
{
    Wandering = 1, -- Peacefully wandering
    Pursuing = 2, -- Actively pursuing a target
    Hunting = 3, -- Hunting for prey territorially
    Destroyed = 4 -- Drone has been destroyed
}

DronePersonality = 
{
    Defensive = 1, -- Drone only attacks if attacked
    Hostile = 2 -- Drone attacks on sight
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