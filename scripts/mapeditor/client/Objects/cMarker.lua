class("Marker" , Objects)

function Objects.Marker:__init(...) ; MapEditor.Object.__init(self , ...)
	local size = Vector3(0.5 , 0.5 , 0.5)
	self.selectionStrategy = {
		type = "Bounds" ,
		bounds = {-size , size}
	}
	
	self.cursorModel = MapEditor.models["Cursor"]
end

function Objects.Marker:OnRender()
	-- Render cursor model.
	local transform = Transform3()
	transform:Translate(self:GetPosition())
	transform:Rotate(self:GetAngle())
	Render:SetTransform(transform)
	self.cursorModel:Draw()
	Render:ResetTransform()
end
