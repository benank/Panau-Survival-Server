DroneRegionEnum = 
{
    FinancialDistrict = 1,
    ParkDistrict = 2,
    DocksDistrict = 3,
    ResidentialDistrict = 4
}

DroneRegions = 
{
    [DroneRegionEnum.FinancialDistrict] = 
    {
        radius = 1000,
        center = Vector3(-10314, 203, -3000),
        level_range = {min = 1, max = 5},
        spawn = 
        {
            max = 30, -- Max drones alive at one time
            interval = 10, -- How often drones can spawn (every X minutes)
            change = 0.9 -- Chance of a drone spawning every interval
        },
        drone_spawn_rate = {}
    },
    [DroneRegionEnum.ParkDistrict] = 
    {
        radius = 1000,
        center = Vector3(-12708, 234, -4778),
        level_range = {min = 5, max = 10},
        spawn = 
        {
            max = 50, -- Max drones alive at one time
            interval = 10, -- How often drones can spawn (every X minutes)
            change = 0.9 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.DocksDistrict] = 
    {
        radius = 900,
        center = Vector3(-15321, 203, -2815),
        level_range = {min = 10, max = 20},
        spawn = 
        {
            max = 40, -- Max drones alive at one time
            interval = 30, -- How often drones can spawn (every X minutes)
            change = 0.8 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.ResidentialDistrict] = 
    {
        radius = 1100,
        center = Vector3(-12507, 203, -1119),
        level_range = {min = 5, max = 10},
        spawn = 
        {
            max = 50, -- Max drones alive at one time
            interval = 10, -- How often drones can spawn (every X minutes)
            change = 0.9 -- Chance of a drone spawning every interval
        },
    },
}

function GetLevelFromRegion(region)
    local region_data = DroneRegions[region]
    if not region_data then return end
    return math.random(region_data.level_range.max - region_data.level_range.min) + region_data.level_range.min
end