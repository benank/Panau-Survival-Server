Exp = 
{
    Starting_Level = 1,
    Max_Level = 1000,
    Lootbox = 
    {
        [1] = 8,
        [2] = 16,
        [3] = 30,
        [4] = 50,
        [5] = 100,
        [9] = 25,
        [10] = 25,
        [16] = 100, -- Level 1 airdrop
        [17] = 200, -- Level 2 airdrop
        [18] = 300, -- Level 3 airdrop
        [19] = 50 -- SAM lootbox
    },    
    Kill = 
    {
        [DamageEntity.None] = 150,
        [DamageEntity.Physics] = 150,
        [DamageEntity.Bullet] = 150,
        [DamageEntity.Explosion] = 150,
        [DamageEntity.Vehicle] = 150,
        [DamageEntity.ToxicGrenade] = 150,
        [DamageEntity.Molotov] = 150,
        [DamageEntity.Snowball] = 150,
        [DamageEntity.Mine] = 150,
        [DamageEntity.Claymore] = 150,
        [DamageEntity.HEGrenade] = 150,
        [DamageEntity.LaserGrenade] = 150,
        [DamageEntity.Hunger] = 0,
        [DamageEntity.Thirst] = 0,
        [DamageEntity.VehicleGuard] = 150,
        [DamageEntity.WarpGrenade] = 0,
        [DamageEntity.Suicide] = 50,
        [DamageEntity.AdminKill] = 0,
        [DamageEntity.C4] = 150,
        [DamageEntity.MeleeGrapple] = 50,
        [DamageEntity.MeleeKick] = 50,
        [DamageEntity.MeleeSlidingKick] = 50,
        [DamageEntity.CruiseMissile] = 150,
        [DamageEntity.AreaBombing] = 150,
        [DamageEntity.TacticalNuke] = 150,
    },
    Hack = 
    {
        [13] = 30, -- Locked Stash
        [14] = 10, -- Proximity Alarm
        ["SAM"] = 50
    },
    DestroyStash = 
    {
        [11] = 50, -- Barrel Stash
        [12] = 75, -- Garbage Stash
        [13] = 100, -- Locked Stash
        [14] = 10 -- Proximity alarm
    },
    DestroySAM = 150,
    DestroyDrone = 
    {
        [DamageEntity.Bullet] =         120,
        [DamageEntity.Explosion] =      120,
        [DamageEntity.Mine] =           100,
        [DamageEntity.Claymore] =       100,
        [DamageEntity.HEGrenade] =      100,
        [DamageEntity.LaserGrenade] =   100,
        [DamageEntity.C4] =             100,
        [DamageEntity.CruiseMissile] =  80,
        [DamageEntity.AreaBombing] =    80,
        [DamageEntity.TacticalNuke] =   80,
        AdditionalPercentPerPlayer = 0.2 -- X% more total exp for each player who damages a drone
    },
    DestroyExplosive = 
    {
        [DamageEntity.Mine] = 5,
        [DamageEntity.Claymore] = 5,
        [DamageEntity.C4] = 20
    },
    DestroyBuildObject = 
    {
        ["Wall"] = 15,
        ["Door"] = 15,
        ["Bed"] = 15
    },
    KillExpireTime = 60 * 60 * 10, -- Timer for killing the same person. If killed again before this timer expires, no exp is given
    UnfriendTime = 60 * 60 * 24 * 7, -- Timer for killing a recently unfriended person
    LevelCutoffs = -- Level cutoffs for no exp for these players
    {
        [0] = -1,
        -- [5] = 0,
        -- [10] = 1,
        -- [15] = 2,
        -- [20] = 3,
        -- [25] = 4,
        -- [30] = 5
    }
}


function GetMaximumExp(level)
    return (math.round(500000 * math.exp(0.04354 * level) * (math.exp(0.04354) - 1) / (math.exp(4.354) - 1))) * 2
end

-- Gets an exp modifier based on the difference in the killer and killed players' levels
function GetKillLevelModifier(killer_level, killed_level)

    local cutoff_level = GetMaxFromLevel(killer_level, Exp.LevelCutoffs)

    if cutoff_level ~= nil and killed_level <= cutoff_level then
        return 0
    else
        local mod = killed_level > killer_level and 0.8 or 0.15
        return math.pow(10, (killed_level - killer_level) / (Exp.Max_Level * mod))
    end
end

function GetExpLostOnDeath(level)
    return GetMaximumExp(level)
end