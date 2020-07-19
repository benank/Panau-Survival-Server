class("RaceRespawnPoint" , Objects)

function Objects.RaceRespawnPoint:__init(...) ; MapEditor.Object.__init(self , ...)
	self:AddProperty{
		name = "modelId" ,
		type = "number" ,
		description = "Vehicle model id that players must have to use this respawn point. -1 is "..
			" on-foot. 0 removes this restriction." ,
	}
	self:AddProperty{
		name = "speed" ,
		type = "number" ,
		description = "Speed in km/h that vehicles will spawn at." ,
	}
	
	self.selectionStrategy = {
		type = "Bounds" ,
		bounds = {Vector3(-0.95 , 0 , -2.25) , Vector3(0.95 , 1.45 , 2.25)} ,
	}
	
	self.cursorModel = MapEditor.models["Cursor"]
end

function Objects.RaceRespawnPoint:OnRender()
	-- Render cursor model.
	local transform = Transform3()
	transform:Translate(self:GetPosition())
	transform:Rotate(self:GetAngle())
	Render:SetTransform(transform)
	self.cursorModel:Draw()
	Render:ResetTransform()
end
