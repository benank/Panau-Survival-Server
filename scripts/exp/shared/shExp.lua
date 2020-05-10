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
        [5] = 50
    },    
    Kill = 
    {
        [DamageEntity.None] = 10,
        [DamageEntity.Physics] = 30,
        [DamageEntity.Bullet] = 50,
        [DamageEntity.Explosion] = 45,
        [DamageEntity.Vehicle] = 20,
        [DamageEntity.ToxicGrenade] = 40,
        [DamageEntity.Molotov] = 40,
        [DamageEntity.Mine] = 25,
        [DamageEntity.Claymore] = 25,
        [DamageEntity.HEGrenade] = 40,
        [DamageEntity.LaserGrenade] = 35,
        [DamageEntity.Hunger] = 0,
        [DamageEntity.Thirst] = 0,
        [DamageEntity.VehicleGuard] = 20,
        [DamageEntity.WarpGrenade] = 0,
        [DamageEntity.Suicide] = 30,
        [DamageEntity.AdminKill] = 0
    },
    KillExpireTime = 60 * 60 * 24, -- Timer for killing the same person. If killed again before this timer expires, no exp is given
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
    return 20 * level
end