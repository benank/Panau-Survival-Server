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
        [DamageEntity.Bullet] = 100,
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
        [DamageEntity.C4] = 85
    },
    KillExpireTime = 60 * 60 * 8, -- Timer for killing the same person. If killed again before this timer expires, no exp is given
    Level0ExpCutoffLevel = 5 -- Level where you stop getting exp for killing level 0 players
}


function GetMaximumExp(level)
    return math.round(500000 * math.exp(0.04354 * level) * (math.exp(0.04354) - 1) / (math.exp(4.354) - 1))
end

-- Gets an exp modifier based on the difference in the killer and killed players' levels
function GetKillLevelModifier(killer_level, killed_level)
    if killed_level == 0 and killer_level >= Exp.Level0ExpCutoffLevel then
        return 0
    else
        return math.pow(10, (killed_level - killer_level) / Exp.Max_Level)
    end
end

function GetExpLostOnDeath(level)
    return 5 * level
end