class("SaveAs" , Actions)

function Actions.SaveAs:__init() ; Actions.SaveLoadBase.__init(self)
	self.window:SetTitle("Save map as")
	self.processButton:SetText("Save as")
	
	self:NetworkSubscribe("ConfirmMapSave")
end

function Actions.SaveAs:OnProcess(mapName)
	MapEditor.map.name = mapName
	MapEditor.map:Save(mapName)
end

-- Network events

function Actions.SaveAs:ConfirmMapSave()
	self:Destroy()
end
