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
}
