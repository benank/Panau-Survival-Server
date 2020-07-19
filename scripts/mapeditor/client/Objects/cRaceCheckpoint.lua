class("RaceCheckpoint" , Objects)

function Objects.RaceCheckpoint:__init(...) ; MapEditor.Object.__init(self , ...)
	self:AddProperty{
		name = "nextCheckpoint" ,
		type = "RaceCheckpoint" ,
	}
	self:AddProperty{
		name = "validVehicles" ,
		type = "table" ,
		subtype = "number" ,
		default = {} ,
		description = "Model ids of the vehicles that can activate this checkpoint. Be sure to set "..
			"this so people can't activate checkpoints while out of their car. -1 is on-foot." ,
	}
	self:AddProperty{
		name = "allowAllVehicles" ,
		type = "boolean" ,
		default = true ,
		description = "If true, Valid Vehicles doesn't apply, so any vehicle will work, even "..
			"on-foot." ,
	}
	self:AddProperty{
		name = "isRespawnable" ,
		type = "boolean" ,
		default = true ,
		description = "Make sure to disable respawning for checkpoints that are inside of poles or "..
			"before a jump that requires speed." ,
	}
	self:AddProperty{
		name = "respawnPoints" ,
		type = "table" ,
		subtype = "RaceRespawnPoint" ,
		description = "You can add your own respawn points in case the checkpoint's default one is "..
			"inadequate." ,
	}
	
	self.selectionStrategy = {type = "Radius" , radius = 10}
	
	self.timer = Timer()
	
	self:OnRecreate()
end

function Objects.RaceCheckpoint:OnRecreate()
	self.ring = ClientParticleSystem.Create(
		AssetLocation.Game ,
		{
			position = self:GetPosition() ,
			angle = self:GetAngle() ,
			path = "fx_race_firering_01.psm" ,
		}
	)
end

function Objects.RaceCheckpoint:OnDestroy()
	self.ring:Remove()
end

function Objects.RaceCheckpoint:OnRender()
	self.ring:SetAngle(Camera:GetAngle())
	
	-- Render relationship line to our nextCheckpoint.
	local nextCheckpoint = self:GetProperty("nextCheckpoint").value
	if nextCheckpoint ~= MapEditor.NoObject then
		local position = self:GetPosition()
		local distance = Vector3.Distance(nextCheckpoint:GetPosition() , position)
		local direction = (nextCheckpoint:GetPosition() - position):Normalized()
		local angle = Angle.FromVectors(Vector3.Forward , direction)
		
		local transform = Transform3()
		transform:Translate(position)
		transform:Rotate(angle)
		transform:Scale(distance)
		Render:SetTransform(transform)
		MapEditor.models.dashedLine:Draw()
		Render:ResetTransform()
	end
end

function Objects.RaceCheckpoint:OnTransformChange(position , angle)
	self.ring:SetPosition(position)
end
