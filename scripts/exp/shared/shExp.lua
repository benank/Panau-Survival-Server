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
        [10] = 6
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
        [DamageEntity.C4] = 170,
        [DamageEntity.MeleeGrapple] = 200,
        [DamageEntity.MeleeKick] = 220,
        [DamageEntity.MeleeSlidingKick] = 200,
    },
    Hack = 
    {
        [13] = 75, -- Locked Stash
        [14] = 15 -- Proximity Alarm
    },
    DestroyStash = 
    {
        [11] = 50, -- Barrel Stash
        [12] = 100, -- Garbage Stash
        [13] = 150, -- Locked Stash
        [14] = 15 -- Proximity alarm
    },
    DestroyExplosive = 
    {
        [DamageEntity.Mine] = 6,
        [DamageEntity.Claymore] = 6,
        [DamageEntity.C4] = 15
    },
    KillExpireTime = 60 * 60 * 8, -- Timer for killing the same person. If killed again before this timer expires, no exp is given
    LevelCutoffs = -- Level cutoffs for no exp for these players
    {
        [3] = 0,
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
        return math.pow(10, (killed_level - killer_level) / Exp.Max_Level)
    end
end

function GetExpLostOnDeath(level)
    return 5 * level
end