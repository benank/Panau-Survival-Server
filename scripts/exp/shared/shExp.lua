Exp = 
{
    Starting_Level = 0,
    Max_Level = 100,
    Lootbox = 
    {
        [1] = 1,
        [2] = 2,
        [3] = 5,
        [4] = 10,
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
    KillExpireTime = 60 * 60 * 24 -- Timer for killing the same person. If killed again before this timer expires, no exp is given
}


function GetMaximumExp(level)
    return 200 + level * 500
end

-- Gets an exp modifier based on the difference in the killer and killed players' levels
function GetKillLevelModifier(killer_level, killed_level)
    return math.min(2, (killed_level + 1) / (killer_level + 1))
end