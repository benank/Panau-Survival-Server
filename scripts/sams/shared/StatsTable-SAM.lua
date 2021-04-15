SAMStatsTable	=	{
	Name				=	"SAM",	--	Name of the Missile, no reason to change.													Default: "SAM"
	Class				=	"SAM",	--	Name of the Missile type, no reason to change.												Default: "SAM"
	Beep				=	true,	--	Whether or not the missile emits the iconic proximity beep.									Default: true
	Damage				=	0.33,	--	As a percent of Max Player HP.																Default: 0.33 (33%)
	Radius				=	15,		--	How large of an area, in meters, the explosion damages.										Default: 15
	MaxSpeed			=	100,	--	Maximum speed, in meters per seconds, that the missile can fly.								Default: 90
	Booster				=	3,		--	A factor of how quickly the missile reaches max speed and can turn, set to 1 for instant.	Default: 3
	TurnRate			=	45,		--	How many degrees the missile can turn each second.											Default: 45
	Range				=	1500,	--	How far, in meters, the missile can go before exploding/running out of fuel.				Default: 1000
	FireEffect			=	53,		--	The Firing effect, no reason to change.														Default: 53
	ProjectileEffect	=	246,	--	The Projectile effect, no reason to change.													Default: 246
	ObjectModel			=	"f1m07.bomb.eez/gp040-a.lod",	--	The Missile's model, change to "" to remove.						Default: "f1m07.bomb.eez/gp040-a.lod"
	ObjectCollision		=	"gp040_lod1-a_col.pfx",			--	The Missile's collision, change to "" to remove.					Default: "gp040_lod1-a_col.pfx"
	Note				=	""		--	Ignore this, it is for debugging.
				}
			
SAM_Configuration = 
{
    Damage = {base = 0.2, per_level = 0.001},
    MaxHealth = {base = 300, per_level = 15},
    MaxSpeed = {base = 85, per_level = 2.25},
    TurnRate = {base = 42, per_level = 0.5},
    FireInterval = {base = 12, per_level = -0.1},
    Range = {base = 1000, per_level = 20}
}
	
--[[
    Gets a SAM configuration depending on the SAM level

]]

function GetSAMConfiguration(level)

    local config = deepcopy(SAMStatsTable)

    for config_name, data in pairs(SAM_Configuration) do
        if data.per_level then
            config[config_name] = data.base + data.per_level * level
        elseif data.chance_per_level then
            config[config_name] = math.random() < (data.base_chance + data.chance_per_level * level)
                and (not data.base) or (data.base)
        end
    end

    return config

end