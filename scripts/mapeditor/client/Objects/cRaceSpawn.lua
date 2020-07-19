class("RaceSpawn" , Objects)

function Objects.RaceSpawn:__init(...) ; MapEditor.Object.__init(self , ...)
	-- Array of Object ids.
	self:AddProperty{
		name = "vehicles" ,
		type = "table" ,
		subtype = "RaceVehicleInfo" ,
		default = {} ,
		description = "Race Vehicle Infos that this spawn can have." ,
	}
	
	self.selectionStrategy = {
		type = "Bounds" ,
		bounds = {Vector3(-0.95 , 0 , -2.25) , Vector3(0.95 , 1.45 , 2.25)} ,
	}
	
	self.cursorModel = MapEditor.models["Cursor"]
end

function Objects.RaceSpawn:OnRender()
	-- Render cursor model.
	local transform = Transform3()
	transform:Translate(self:GetPosition())
	transform:Rotate(self:GetAngle())
	Render:SetTransform(transform)
	self.cursorModel:Draw()
	Render:ResetTransform()
	
	-- Draw relationship lines to our VehicleInfos.
	for index , vehicleInfo in ipairs(self:GetProperty("vehicles").value) do
		if vehicleInfo ~= MapEditor.NoObject then
			Render:DrawLine(self:GetPosition() , vehicleInfo.position , Color(127 , 127 , 127 , 127))
		end
	end
end
