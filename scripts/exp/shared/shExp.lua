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
        [13] = 60, -- Locked Stash
        [14] = 12 -- Proximity Alarm
    },
    DestroyStash = 
    {
        [11] = 30, -- Barrel Stash
        [12] = 50, -- Garbage Stash
        [13] = 100, -- Locked Stash
        [14] = 6 -- Proximity alarm
    },
    DestroyDrone = 
    {
        Base = 15,
        Per_Level = 10,
        AdditionalPercentPerPlayer = 0.1 -- X% more total exp for each player who damages a drone
    },
    DestroyExplosive = 
    {
        [DamageEntity.Mine] = 5,
        [DamageEntity.Claymore] = 5,
        [DamageEntity.C4] = 10
    },
    KillExpireTime = 60 * 60 * 4, -- Timer for killing the same person. If killed again before this timer expires, no exp is given
    UnfriendTime = 60 * 60 * 24 * 7, -- Timer for killing a recently unfriended person
    LevelCutoffs = -- Level cutoffs for no exp for these players
    {
        [0] = -1,
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