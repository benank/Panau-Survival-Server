DroneRegionEnum = 
{
    FinancialDistrict = 1,
    ParkDistrict = 2,
    DocksDistrict = 3,
    ResidentialDistrict = 4,
    LostIsland = 5,
    LostIslandInner = 6,
    Desert = 7,
    CapeCarnival = 8,
    Casino = 9,
    TopRight = 10,
    BottomIslands = 11,
    TopCities = 12,
    TopCityTall = 13
}

DRONE_SPAWN_INTERVAL = 1

function GetClosestRegion(pos)
    local closest = DroneRegionEnum.FinancialDistrict
    local closest_dist = 99999

    for region_enum, region in pairs(DroneRegions) do
        local dist = region.center:Distance(pos)
        if dist < closest_dist then
            closest_dist = dist
            closest = region_enum
        end
    end

    return closest
end

DroneRegions = 
{
    [DroneRegionEnum.FinancialDistrict] = 
    {
        radius = 1000,
        center = Vector3(-10314, 203, -3000),
        level_range = {min = 1, max = 10},
        spawn = 
        {
            max = 40, -- Max drones alive at one time
            chance = 0.9, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 40
            }
        },
        drone_spawn_rate = {}
    },
    [DroneRegionEnum.ParkDistrict] = 
    {
        radius = 1100,
        center = Vector3(-12708, 234, -4778),
        level_range = {min = 8, max = 15},
        spawn = 
        {
            max = 50, -- Max drones alive at one time
            chance = 0.8, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 50
            }
        },
    },
    [DroneRegionEnum.DocksDistrict] = 
    {
        radius = 900,
        center = Vector3(-15321, 203, -2815),
        level_range = {min = 15, max = 40},
        spawn = 
        {
            max = 50, -- Max drones alive at one time
            chance = 0.6 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.ResidentialDistrict] = 
    {
        radius = 1000,
        center = Vector3(-12507, 203, -1119),
        level_range = {min = 8, max = 15},
        spawn = 
        {
            max = 50, -- Max drones alive at one time
            chance = 0.8, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 50
            }
        },
    },
    [DroneRegionEnum.LostIsland] = 
    {
        radius = 1500,
        center = Vector3(-13609, 366, -13458),
        level_range = {min = 50, max = 200},
        spawn = 
        {
            max = 75, -- Max drones alive at one time
            chance = 0.1, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 40
            }
        },
    },
    [DroneRegionEnum.LostIslandInner] = 
    {
        radius = 300,
        center = Vector3(-14088, 366, -14142),
        level_range = {min = 75, max = 300},
        spawn = 
        {
            max = 25, -- Max drones alive at one time
            chance = 0.2, -- Chance of a drone spawning every interval
            height = 
            {
                min = 250,
                max = 400
            }
        },
    },
    [DroneRegionEnum.Desert] = 
    {
        radius = 6000,
        center = Vector3(-7605, 234, 7313),
        level_range = {min = 1, max = 50},
        spawn = 
        {
            max = 100, -- Max drones alive at one time
            chance = 0.1 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.CapeCarnival] = 
    {
        radius = 700,
        center = Vector3(13815, 240, -2299),
        level_range = {min = 25, max = 70},
        spawn = 
        {
            max = 25, -- Max drones alive at one time
            chance = 0.1, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 15
            }
        },
    },
    [DroneRegionEnum.Casino] = 
    {
        radius = 2000,
        center = Vector3(1414, 210, 1812),
        level_range = {min = 15, max = 30},
        spawn = 
        {
            max = 20, -- Max drones alive at one time
            chance = 0.1 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.TopRight] = 
    {
        radius = 3000,
        center = Vector3(11468, 267, -8950),
        level_range = {min = 10, max = 25},
        spawn = 
        {
            max = 20, -- Max drones alive at one time
            chance = 0.1 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.BottomIslands] = 
    {
        radius = 3500,
        center = Vector3(11468, 267, -8950),
        level_range = {min = 10, max = 50},
        spawn = 
        {
            max = 25, -- Max drones alive at one time
            chance = 0.5 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.TopCities] = 
    {
        radius = 1000,
        center = Vector3(-285, 232, -12563),
        level_range = {min = 10, max = 30},
        spawn = 
        {
            max = 50, -- Max drones alive at one time
            chance = 0.1 -- Chance of a drone spawning every interval
        },
    },
    [DroneRegionEnum.TopCityTall] = 
    {
        radius = 150,
        center = Vector3(-507, 750, -12054),
        level_range = {min = 20, max = 50},
        spawn = 
        {
            max = 10, -- Max drones alive at one time
            chance = 0.1, -- Chance of a drone spawning every interval
            height = 
            {
                min = 0,
                max = 100
            }
        },
    }
}

function GetExtraHeightOfDroneFromRegion(region)
    local region_data = DroneRegions[region]
    if not region_data then return 0 end
    local height_data = region_data.spawn.height
    if not height_data then return 0 end

    return (height_data.max - height_data.min) * math.random() + height_data.min
end

function GetLevelFromRegion(region)
    local region_data = DroneRegions[region]
    if not region_data then return end
    return math.random(region_data.level_range.max - region_data.level_range.min) + region_data.level_range.min
end