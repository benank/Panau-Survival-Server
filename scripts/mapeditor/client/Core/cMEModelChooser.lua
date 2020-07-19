-- Uses the ModelViewer to select a model when changing a "model" property from the properties menu.

class("ModelChooser" , MapEditor)

function MapEditor.ModelChooser:__init(callback , instance)
	self.callback = callback
	self.instance = instance
	
	MapEditor.modelViewer:SetVisible(true)
	
	-- Add our own controls to the model viewer's window.
	
	local base = BaseWindow.Create(MapEditor.modelViewer.window)
	-- This is how you make it dock at the very bottom in GWEN. Yes.
	base:SendToBack()
	base:SetDock(GwenPosition.Bottom)
	self.baseControl = base
	
	local button = Button.Create(self.baseControl)
	button:SetMargin(Vector2(0 , 2) , Vector2(0 , 0))
	button:SetDock(GwenPosition.Left)
	button:SetText("Confirm")
	button:SetWidth(80)
	button:Subscribe("Press" , self , self.ConfirmButtonPressed)
	self.confirmButton = button
	
	self.baseControl:SetHeight(self.confirmButton:GetHeight() + 2)
	
	self.gwenSubs = {}
	local Sub = function(control , name , ourFunc)
		local sub = control:Subscribe(name , self , ourFunc or self[name])
		table.insert(self.gwenSubs , {sub = sub , control = control})
	end
	Sub(MapEditor.modelViewer.window , "WindowClosed")
end

function MapEditor.ModelChooser:CallCallback(modelPath)
	if self.instance then
		self.callback(self.instance , modelPath)
	else
		self.callback(modelPath)
	end
	
	MapEditor.modelViewer:SetVisible(false)
	
	self.baseControl:Remove()
	
	for index , subInfo in ipairs(self.gwenSubs) do
		subInfo.control:Unsubscribe(subInfo.sub)
	end
end

-- GWEN events

function MapEditor.ModelChooser:WindowClosed()
	self:CallCallback(nil)
end

function MapEditor.ModelChooser:ConfirmButtonPressed()
	self:CallCallback(MapEditor.modelViewer:GetModelPath())
end
