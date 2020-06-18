WorkBenchConfig = 
{
    locations = 
    {
        ["Southern Workbench"] = {position = Vector3(4755.66, 572.124, 13219.67), angle = Angle()}, -- South
        ["Eastern Workbench"] = {position = Vector3(11455.59, 444, -516.274), angle = Angle(-math.pi * 0.2, 0, 0)}, -- East
        ["Northern Workbench"] = {position = Vector3(3018.479, 206.05, -11952.077), angle = Angle(-math.pi * 0.2, -math.pi * 0.01, -math.pi * 0.02)}, -- North
        ["Western Workbench"] = {position = Vector3(-7116.8, 388.85, 2928.25), angle = Angle(math.pi * 0.4, 0, 0)}, -- West
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