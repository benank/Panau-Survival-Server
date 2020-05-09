Exp = 
{
    Lootbox = 
    {
        [1] = 1,
        [2] = 5,
        [3] = 20,
        [4] = 100,
        [5] = 500
    }
    -- TODO: exp for kills
}


function GetMaximumExp(level)
    return 200 + level * 500
end