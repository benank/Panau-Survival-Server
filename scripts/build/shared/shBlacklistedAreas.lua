BlacklistedAreas = 
{
    {pos = Vector3(-10468.322266, 203.262085, -3469.024658), size = 20},
    {pos = Vector3(-6643.242188, 208.981903, -3879.970947), size = 100},
    {pos = Vector3(-6370.579102, 208.933044, -3705.792236), size = 100},
    {pos = Vector3(14134.099609, 332.878632, 14360.429688), size = 1000},
    {pos = Vector3(-14136.325195, 322.804749, -14170.808594), size = 1000},
    {pos = Vector3(-13737.822266, 200.717514, 6303.510254), size = 500},
    -- Workbenches
    {pos = Vector3(4755.66, 572.124, 13219.67), size = 100},
    {pos = Vector3(11455.59, 444, -516.274), size = 100},
    {pos = Vector3(3018.479, 206.1557, -11952.077), size = 100},
    {pos = Vector3(-7116.8, 388.98, 2928.25), size = 100},
}

local blacklist = SharedObject.Create("BlacklistedAreas", {blacklist = BlacklistedAreas})