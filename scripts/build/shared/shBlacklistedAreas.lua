BlacklistedAreas = 
{
    -- Workbenches
    -- {pos = Vector3(2192.39, 649.05, 1365), size = 2},
    -- {pos = Vector3(-15314, 501.761, -2408.28), size = 2},
}

local blacklist = SharedObject.Create("BlacklistedAreas", {blacklist = BlacklistedAreas})

function IsInLocation(position, radius, locations)
    for _, location in pairs(locations) do
        if Distance2D(position, location.pos) < location.size + radius then
            return true
        end
    end
end

BlacklistedLandclaimAreas = 
{
    {pos = Vector3(-10299, 204, -3012), size = 400},
    -- Workbenches
    {pos = Vector3(2192.39, 649.05, 1365), size = 100},
    {pos = Vector3(-15314, 501.761, -2408.28), size = 100},
    {pos = Vector3(-497.348846, 799.554688, -12044.131836), size = 100},
    {pos = Vector3(-11642.025391, 203.040579, -5215.140137), size = 100},
    {pos = Vector3(-11616.697266, 211.920645, -954.870911), size = 100},
    {pos = Vector3(-7745.649414, 205.799719, 6750.222656), size = 100},
    {pos = Vector3(6921.548340, 201.228071, 12321.868164), size = 100},
    {pos = Vector3(8037.465332, 540.931311, -1561.646973), size = 100},
    {pos = Vector3(9226.545898, 223.351470, -11987.953125), size = 100},
}
