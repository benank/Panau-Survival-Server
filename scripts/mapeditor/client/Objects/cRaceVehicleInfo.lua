class("RaceVehicleInfo" , Objects)

function Objects.RaceVehicleInfo:__init(...) ; MapEditor.Object.__init(self , ...)
	self:AddProperty{
		name = "modelId" ,
		type = "number" ,
		-- range = {-1 , 91} ,
		default = -1 ,
		description = "Vehicle model id. See Model ID on the JC2-MP wiki. -1 is on-foot." ,
	}
	self:AddProperty{
		name = "templates" ,
		type = "table" ,
		subtype = "string" ,
		default = {""} ,
		description = "Vehicle templates to choose from. See the JC2-MP wiki on vehicle templates." ,
	}
	
	self.selectionStrategy = {type = "Icon" , icon = Icons.VehicleInfo}
end
