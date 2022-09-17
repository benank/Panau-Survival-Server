WorkBenchConfig = 
{
    locations = 
    {
        -- ["Southern Workbench"] = {position = Vector3(4755.66, 572.124, 13219.67), angle = Angle()}, -- South
        -- ["Eastern Workbench"] = {position = Vector3(11455.59, 444, -516.274), angle = Angle(-math.pi * 0.2, 0, 0)}, -- East
        ["Panau Falls Casino Workbench"] = {position = Vector3(2192.39, 648.9, 1365), angle = Angle(0, 0, 0)}, -- North
        ["PBC Tower Workbench"] = {position = Vector3(-497.348846, 799.554688, -12044.131836), angle = Angle(math.pi * 0.4, 0, 0)},
        ["Docks District Workbench"] = {position = Vector3(-15314, 501.761, -2408.28), angle = Angle(math.pi * 0.4, 0, 0)},
        ["Parks District Workbench"] = {position = Vector3(-11642.025391, 203.040579, -5215.140137), angle = Angle(math.pi * 0.4, 0, 0)},
        ["Residential District Workbench"] = {position = Vector3(-11616.697266, 211.920645, -954.870911), angle = Angle(math.pi * 0.4, 0, 0)},
        ["Gambler\'s Den Workbench"] = {position = Vector3(-7745.649414, 205.799719, 6750.222656), angle = Angle(math.pi * 0.1, 0, 0)},
        ["Party Workbench"] = {position = Vector3(6921.548340, 201.228071, 12321.868164), angle = Angle(math.pi * 0.4, 0, 0)},
        ["Ski Resort Workbench"] = {position = Vector3(8037.465332, 540.931311, -1561.646973), angle = Angle(math.pi * 0.2, 0, 0)},
        ["Flower Workbench"] = {position = Vector3(9226.545898, 223.351470, -11987.953125), angle = Angle(math.pi * 0.25, 0, 0)},
    },
    blacklisted_items = -- Put any blacklisted items in here
    {
        ["BlackList Item"] = true
    },
    max_items_at_once = 3, -- How many items can be put in the workbench at once
    maximum_durability = 5, -- Max durability is 5x normal
    durability_bonus = 0.1, -- x% durability bonus upon one finished combination
    use_perk_req = 12, -- Perk required to use workbenches
    perks = -- Perks that decrease combine time
    {
        [70] = 1 - 0.25,
        [106] = 1 - 0.5
    }
}