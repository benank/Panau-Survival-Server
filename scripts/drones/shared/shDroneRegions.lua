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
        level_range = {min = 1, max = 3}
    },
    [DroneRegionEnum.ParkDistrict] = 
    {
        radius = 1000,
        center = Vector3(-12708, 234, -4778),
        level_range = {min = 2, max = 7}
    },
    [DroneRegionEnum.DocksDistrict] = 
    {
        radius = 900,
        center = Vector3(-15321, 203, -2815),
        level_range = {min = 10, max = 20}
    },
    [DroneRegionEnum.ResidentialDistrict] = 
    {
        radius = 1100,
        center = Vector3(-12507, 203, -1119),
        level_range = {min = 2, max = 7}
    },
}

function GetLevelFromRegion(region)
    local region_data = DroneRegions[region]
    if not region_data then return end
    return math.random(region_data.level_range.max - region_data.level_range.min) + region_data.level_range.min
end