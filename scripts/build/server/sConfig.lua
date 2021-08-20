Config = 
{
    base_landclaim_lifetime = 30, -- 30 days lifetime for a landclaim once placed
    landclaim_name_max_length = 20,
    player_base_landclaims = 10, -- 2 initial max landclaims
    player_max_landclaims = -- Additional max landclaims per perk
    {
        --[35] = 2,
        [58] = 1,
        [76] = 1,
        [97] = 1,
        [117] = 1,
        [132] = 1,
        [142] = 1,
        [157] = 1,
        [168] = 1,
        [174] = 1,
        [182] = 1,
        [191] = 1,
        [199] = 1,
        [204] = 1,
        [209] = 1,
        [217] = 1,
        [220] = 1,
        [226] = 1,
        [230] = 1
    },
    damage_perks = 
    {
        ["C4"] = 
        {
            [56] = {[1] = 1.10},
            [114] = {[1] = 1.20},
            [152] = {[1] = 1.30}
        },
        ["Claymore"] = 
        {
            [95] = {[1] = 1.10},
            [167] = {[1] = 1.20},
            [197] = {[1] = 1.30}
        }
    }
}