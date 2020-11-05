Exp = 
{
    Starting_Level = 0,
    Max_Level = 100,
    Lootbox = 
    {
        [1] = 2,
        [2] = 4,
        [3] = 10,
        [4] = 20,
        [5] = 50,
        [9] = 6,
        [10] = 6,
        [16] = 50, -- Level 1 airdrop
        [17] = 75, -- Level 2 airdrop
        [18] = 100
    },    
    Kill = 
    {
        [DamageEntity.None] = 20,
        [DamageEntity.Physics] = 60,
        [DamageEntity.Bullet] = 90,
        [DamageEntity.Explosion] = 90,
        [DamageEntity.Vehicle] = 50,
        [DamageEntity.ToxicGrenade] = 80,
        [DamageEntity.Molotov] = 80,
        [DamageEntity.Mine] = 50,
        [DamageEntity.Claymore] = 50,
        [DamageEntity.HEGrenade] = 80,
        [DamageEntity.LaserGrenade] = 70,
        [DamageEntity.Hunger] = 0,
        [DamageEntity.Thirst] = 0,
        [DamageEntity.VehicleGuard] = 40,
        [DamageEntity.WarpGrenade] = 0,
        [DamageEntity.Suicide] = 60,
        [DamageEntity.AdminKill] = 0,
        [DamageEntity.C4] = 80,
        [DamageEntity.MeleeGrapple] = 30,
        [DamageEntity.MeleeKick] = 30,
        [DamageEntity.MeleeSlidingKick] = 30,
        [DamageEntity.CruiseMissile] = 90,
        [DamageEntity.AreaBombing] = 80,
        [DamageEntity.TacticalNuke] = 80,
    },
    Hack = 
    {
        [13] = 50, -- Locked Stash
        [14] = 10 -- Proximity Alarm
    },
    DestroyStash = 
    {
        [11] = 15, -- Barrel Stash
        [12] = 30, -- Garbage Stash
        [13] = 70, -- Locked Stash
        [14] = 5 -- Proximity alarm
    },
    DestroyDrone = 
    {
        [DamageEntity.Bullet] =         40,
        [DamageEntity.Explosion] =      40,
        [DamageEntity.Mine] =           25,
        [DamageEntity.Claymore] =       25,
        [DamageEntity.HEGrenade] =      30,
        [DamageEntity.LaserGrenade] =   30,
        [DamageEntity.C4] =             30,
        [DamageEntity.CruiseMissile] =  15,
        [DamageEntity.AreaBombing] =    12,
        [DamageEntity.TacticalNuke] =   12,
        AdditionalPercentPerPlayer = 0.1 -- X% more total exp for each player who damages a drone
    },
    DestroyExplosive = 
    {
        [DamageEntity.Mine] = 2,
        [DamageEntity.Claymore] = 2,
        [DamageEntity.C4] = 6
    },
    DestroyBuildObject = 
    {
        ["Wall"] = 2,
        ["Door"] = 2,
        ["Bed"] = 1
    },
    KillExpireTime = 60 * 60 * 4, -- Timer for killing the same person. If killed again before this timer expires, no exp is given
    UnfriendTime = 60 * 60 * 24 * 7, -- Timer for killing a recently unfriended person
    LevelCutoffs = -- Level cutoffs for no exp for these players
    {
        [0] = -1,
        [5] = 0,
        [10] = 1,
        [15] = 2,
        [20] = 3,
        [25] = 4,
        [30] = 5
    }
}


function GetMaximumExp(level)
    return math.round(500000 * math.exp(0.04354 * level) * (math.exp(0.04354) - 1) / (math.exp(4.354) - 1))
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
    return 10 * level
end