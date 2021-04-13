class 'SAMManager'

function SAMManager:__init()
	Network:Subscribe("MissileStrikeDamagePlayer", self, self.MissileStrikeDamagePlayer)
end

function SAMManager:MissileStrikeDamagePlayer(strikeTable)
	--	Player	--
	local DamagedPlayer			=	strikeTable.player
	local DamagedPlayerName		=	DamagedPlayer:GetName()
	local DamagedVehicle		=	DamagedPlayer:GetVehicle()
	local DamagedPlayerPosition	=	DamagedPlayer:GetPosition()
	--	Negate all damage if the player is Immune
	if Immune(DamagedPlayer) then
		print(DamagedPlayerName .. " cannot be harmed.")
		return
	end
	
	--	Strike	--
	local StrikeCenter		=	strikeTable.epicenter
	local StrikeVehicle		=	strikeTable.Stats.Name
	local StrikeClass		=	strikeTable.Stats.Class
	local StrikeDamage		=	strikeTable.Stats.Damage
	local StrikeRadius		=	strikeTable.Stats.Radius
	--	Distance	--
	local PlayerStrikeDistance	=	Vector3.Distance(DamagedPlayerPosition, StrikeCenter)
	local DistanceDifference	=	PlayerStrikeDistance / StrikeRadius
	local DistanceModifier	=	1 - DistanceDifference
	--	Effective	--
	EffectiveDamage			=	StrikeDamage * DistanceModifier
	EffectivePlayerDamage	=	EffectiveDamage
	EffectiveVehicleDamage	=	0
	
	if IsValid(DamagedVehicle) then
		local DamagedVehicleModel	=	DamagedVehicle:GetModelId()
		EffectiveVehicleDamage		=	EffectiveDamage
		EffectivePlayerDamage		=	EffectiveVehicleDamage / 4
		local VehicleSetHealth		=	DamagedVehicle:GetHealth() - EffectiveVehicleDamage
		if VehicleSetHealth <= 0 then
			VehicleSetHealth	=	0.1
		end
		DamagedVehicle:SetHealth(VehicleSetHealth)
	end
	local PlayerSetHealth	=	DamagedPlayer:GetHealth() - EffectivePlayerDamage
	DamagedPlayer:SetHealth(PlayerSetHealth)
--	print("[" .. StrikeVehicle .. " " .. StrikeClass .. "] " .. DamagedPlayerName .. ": " .. Round(EffectiveVehicleDamage, 3) .. "/" .. Round(EffectivePlayerDamage, 3) .. ".")
end

SAMManager = SAMManager()