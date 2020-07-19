-- Manages choosing a color when changing a Color property from the properties menu.

class("ColorChooser" , MapEditor)

function MapEditor.ColorChooser:__init(rectangle , callback , instance)
	self.rectangle = rectangle
	self.callback = callback
	self.instance = instance
	
	local size = Vector2(Render.Width * 0.15 + 150 , Render.Height * 0.12 + 120)
	local position = rectangle:RelativeToAbsolute(rectangle:GetPosition())
	position.x = position.x + rectangle:GetWidth() + 40
	position.y = position.y - size.y * 0.2
	
	local window = Window.Create()
	window:SetSize(size)
	window:SetPosition(position)
	window:SetTitle("Choose color")
	window:Subscribe("WindowClosed" , self , self.WindowClosed)
	self.window = window
	
	local colorPicker = HSVColorPicker.Create(self.window)
	colorPicker:SetDock(GwenPosition.Fill)
	colorPicker:SetColor(self.rectangle:GetColor())
	colorPicker:Subscribe("ColorChanged" , self , self.ColorChanged)
	self.colorPicker = colorPicker
	
	local button = Button.Create(self.window)
	button:SetMargin(Vector2(0 , 4) , Vector2(0 , 0))
	button:SetDock(GwenPosition.Bottom)
	button:SetHeight(22)
	button:SetTextSize(14)
	button:SetText("Confirm")
	button:Subscribe("Press" , self , self.ConfirmPressed)
end

function MapEditor.ColorChooser:CallCallback(color)
	if self.instance then
		self.callback(self.instance , color)
	else
		self.callback(color)
	end
	
	self.window:Remove()
end

-- Gwen events

function MapEditor.ColorChooser:ColorChanged()
	self.rectangle:SetColor(self.colorPicker:GetColor())
end

function MapEditor.ColorChooser:ConfirmPressed()
	self:CallCallback(self.rectangle:GetColor())
end

function MapEditor.ColorChooser:WindowClosed()
	self:CallCallback(nil)
end
