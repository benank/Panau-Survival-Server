WorkBenchConfig = 
{
    locations = 
    {
        {position = Vector3(4755.66, 572.124, 13219.67), angle = Angle()}, -- South
        {position = Vector3(14426.58, 204.574, -1102.409), angle = Angle()}, -- East
        {position = Vector3(2602.199, 384, -11045.744), angle = Angle()}, -- North
        {position = Vector3(-12293.124, 569.63, 2815.34), angle = Angle()}, -- West
    },
    blacklisted_items = -- Put any blacklisted items in here
    {
        ["BlackList Item"] = true
    },
    max_items_at_once = 3, -- How many items can be put in the workbench at once
    maximum_durability = 5, -- Max durability is 5x normal
    durability_bonus = 0.1, -- x% durability bonus upon one finished combination
    radius = 100, -- No build zone
    time_to_combine = 10 -- Combined durability / max_durability * time_to_combine = seconds it takes to combine
}