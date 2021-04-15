Exp = 
{
    Starting_Level = 0,
    Max_Level = 100,
    Lootbox = 
    {
        [1] = 4,
        [2] = 8,
        [3] = 20,
        [4] = 40,
        [5] = 70,
        [9] = 12,
        [10] = 12,
        [16] = 50, -- Level 1 airdrop
        [17] = 100, -- Level 2 airdrop
        [18] = 200 -- Level 3 airdrop
    },    
    Kill = 
    {
        [DamageEntity.None] = 40,
        [DamageEntity.Physics] = 120,
        [DamageEntity.Bullet] = 180,
        [DamageEntity.Explosion] = 180,
        [DamageEntity.Vehicle] = 100,
        [DamageEntity.ToxicGrenade] = 160,
        [DamageEntity.Molotov] = 160,
        [DamageEntity.Snowball] = 160,
        [DamageEntity.Mine] = 100,
        [DamageEntity.Claymore] = 100,
        [DamageEntity.HEGrenade] = 160,
        [DamageEntity.LaserGrenade] = 140,
        [DamageEntity.Hunger] = 0,
        [DamageEntity.Thirst] = 0,
        [DamageEntity.VehicleGuard] = 80,
        [DamageEntity.WarpGrenade] = 0,
        [DamageEntity.Suicide] = 120,
        [DamageEntity.AdminKill] = 0,
        [DamageEntity.C4] = 160,
        [DamageEntity.MeleeGrapple] = 60,
        [DamageEntity.MeleeKick] = 60,
        [DamageEntity.MeleeSlidingKick] = 60,
        [DamageEntity.CruiseMissile] = 180,
        [DamageEntity.AreaBombing] = 160,
        [DamageEntity.TacticalNuke] = 160,
    },
    Hack = 
    {
        [13] = 30, -- Locked Stash
        [14] = 5 -- Proximity Alarm
    },
    DestroyStash = 
    {
        [11] = 5, -- Barrel Stash
        [12] = 10, -- Garbage Stash
        [13] = 20, -- Locked Stash
        [14] = 2 -- Proximity alarm
    },
    DestroySAM = 40,
    DestroyDrone = 
    {
        [DamageEntity.Bullet] =         70,
        [DamageEntity.Explosion] =      70,
        [DamageEntity.Mine] =           60,
        [DamageEntity.Claymore] =       60,
        [DamageEntity.HEGrenade] =      60,
        [DamageEntity.LaserGrenade] =   60,
        [DamageEntity.C4] =             60,
        [DamageEntity.CruiseMissile] =  20,
        [DamageEntity.AreaBombing] =    20,
        [DamageEntity.TacticalNuke] =   20,
        AdditionalPercentPerPlayer = 0.1 -- X% more total exp for each player who damages a drone
    },
    DestroyExplosive = 
    {
        [DamageEntity.Mine] = 1,
        [DamageEntity.Claymore] = 1,
        [DamageEntity.C4] = 4
    },
    DestroyBuildObject = 
    {
        ["Wall"] = 2,
        ["Door"] = 10,
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
    return 5 * level
end