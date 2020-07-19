class("Action" , MapEditor)

function MapEditor.Action:__init()
	self.Confirm = MapEditor.Action.Confirm
	self.Cancel = MapEditor.Action.Cancel
end

function MapEditor.Action:Confirm()
	if self.OnConfirmOrCancel then
		self:OnConfirmOrCancel()
	end
	
	MapEditor.map:ActionFinish()
end

function MapEditor.Action:Cancel()
	if self.OnConfirmOrCancel then
		self:OnConfirmOrCancel()
	end
	
	MapEditor.map:ActionCancel()
end
