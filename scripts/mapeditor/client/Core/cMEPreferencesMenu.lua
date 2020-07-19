class("PreferencesMenu" , MapEditor)

function MapEditor.PreferencesMenu:__init()
	EGUSM.SubscribeUtility.__init(self)
	MapEditor.Action.__init(self)
	
	MapEditor.preferencesMenu = self
	
	self.CreateWindow = MapEditor.PreferencesMenu.CreateWindow
	self.ResolutionChange = MapEditor.PreferencesMenu.ResolutionChange
	
	self:CreateWindow()
	
	self:ResolutionChange{size = Render.Size}
	
	self:SetVisible(false)
	
	self:EventSubscribe("ResolutionChange" , MapEditor.PreferencesMenu.ResolutionChange)
end

function MapEditor.PreferencesMenu:CreateWindow()
	local window = Window.Create()
	window:SetTitle("Preferences")
	window:SetSize(Vector2(340 , 380))
	self.window = window
	
	local textSize = 12
	local textWidth = Render:GetTextWidth("Camera movement sensitivity: 00.00" , textSize)
	
	-- Camera movement sensitivity slider
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(2 , 2) , Vector2(2 , 4))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(16)
	
	local slider = HorizontalSlider.Create(base)
	slider:SetDock(GwenPosition.Fill)
	slider:SetRange(0.1 , 1)
	slider:Subscribe("ValueChanged" , self , self.CamSensitivityMoveSliderChanged)
	self.camSensitivityMoveSlider = slider
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(textSize)
	label:SetWidth(textWidth)
	self.camSensitivityMoveLabel = label
	
	-- Camera rotation sensitivity slider
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(2 , 2) , Vector2(2 , 4))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(16)
	
	local slider = HorizontalSlider.Create(base)
	slider:SetDock(GwenPosition.Fill)
	slider:SetRange(0.002 , 0.015)
	slider:Subscribe("ValueChanged" , self , self.CamSensitivityRotSliderChanged)
	self.camSensitivityRotSlider = slider
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(textSize)
	label:SetWidth(textWidth)
	self.camSensitivityRotLabel = label
	
	-- Camera type
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(2 , 0) , Vector2(4 , 0))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(18)
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(textSize)
	label:SetText("Camera type")
	label:SetWidth(textWidth)
	
	local comboBox = ComboBox.Create(base)
	comboBox:SetDock(GwenPosition.Fill)
	comboBox:AddItem("Noclip" , "Noclip")
	comboBox:AddItem("Orbit" , "Orbit")
	comboBox:SelectItemByName("Noclip")
	comboBox:Subscribe("Selection" , self , self.CameraTypeChanged)
	self.camTypeComboBox = comboBox
	
	-- Position snap
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(2 , 1) , Vector2(4 , 1))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(18)
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(textSize)
	label:SetText("Position snap")
	label:SetWidth(textWidth)
	
	local textBox = TextBoxNumeric.Create(base)
	textBox:SetDock(GwenPosition.Fill)
	textBox:Subscribe("Blur" , self , self.SnapPositionChanged)
	self.positionSnapTextBox = textBox
	
	-- Angle snap
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(2 , 1) , Vector2(4 , 1))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(18)
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(textSize)
	label:SetText("Angle snap")
	label:SetWidth(textWidth)
	
	local textBox = TextBoxNumeric.Create(base)
	textBox:SetDock(GwenPosition.Fill)
	textBox:Subscribe("Blur" , self , self.SnapAngleChanged)
	self.angleSnapTextBox = textBox
	
	-- Draw labels
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(2 , 1) , Vector2(4 , 1))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(18)
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(textSize)
	label:SetText("Draw object labels")
	label:SetWidth(textWidth)
	
	local button = Button.Create(base)
	button:SetDock(GwenPosition.Fill)
	button:Subscribe("Press" , self , self.DrawLabelsChanged)
	self.drawLabelsButton = button
	
	-- Time of day
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(2 , 2) , Vector2(2 , 4))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(16)
	
	local slider = HorizontalSlider.Create(base)
	slider:SetDock(GwenPosition.Fill)
	slider:SetRange(0 , 23)
	slider:SetClampToNotches(true)
	slider:SetNotchCount(24)
	slider:Subscribe("ValueChanged" , self , self.TimeOfDaySliderChanged)
	self.timeOfDaySlider = slider
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(textSize)
	label:SetWidth(textWidth)
	self.timeOfDayLabel = label
	
	-- Weather
	
	local base = BaseWindow.Create(self.window)
	base:SetMargin(Vector2(2 , 2) , Vector2(2 , 4))
	base:SetDock(GwenPosition.Top)
	base:SetHeight(16)
	
	local slider = HorizontalSlider.Create(base)
	slider:SetDock(GwenPosition.Fill)
	slider:SetRange(0 , 2)
	slider:SetClampToNotches(true)
	slider:SetNotchCount(21)
	slider:Subscribe("ValueChanged" , self , self.WeatherSliderChanged)
	self.weatherSlider = slider
	
	local label = Label.Create(base)
	label:SetDock(GwenPosition.Left)
	label:SetAlignment(GwenPosition.CenterV)
	label:SetTextSize(textSize)
	label:SetWidth(textWidth)
	self.weatherLabel = label
	
	-- Bind menu
	
	local label = Label.Create(self.window)
	label:SetMargin(Vector2(0 , 3) , Vector2(24 , 1))
	label:SetDock(GwenPosition.Top)
	label:SetAlignment(GwenPosition.CenterH)
	label:SetTextSize(16)
	label:SetText("Controls")
	label:SizeToContents()
	
	local scrollControl = ScrollControl.Create(self.window)
	scrollControl:SetDock(GwenPosition.Fill)
	scrollControl:SetScrollable(false , true)
	scrollControl:SetAutoHideBars(false)
	
	self:UpdateValues()
	
	-- TODO: These should probably be split into different sections.
	local bindMenu = BindMenu.Create(scrollControl)
	bindMenu:SetMargin(Vector2(0 , 0) , Vector2(2 , 0))
	bindMenu:SetDock(GwenPosition.Top)
	bindMenu:SetHeight(460)
	
	bindMenu:AddControl("Move object" ,                      "G")
	bindMenu:AddControl("Rotate object" ,                    "R")
	bindMenu:AddControl("Delete object" ,                    "X")
	bindMenu:AddControl("Floor object" ,                     "F")
	bindMenu:AddControl("Duplicate object" ,                 "C")
	bindMenu:AddControl("Parent object" ,                    "P")
	bindMenu:AddControl("Undo" ,                             "Z")
	bindMenu:AddControl("Redo" ,                             "Y")
	
	bindMenu:AddControl("Noclip camera: Toggle" ,            "J")
	bindMenu:AddControl("Noclip camera: Up" ,                "Space")
	bindMenu:AddControl("Noclip camera: Down" ,              "Control")
	
	bindMenu:RequestSettings()
	
	self.bindMenu = bindMenu
end

function MapEditor.PreferencesMenu:SetVisible(visible)
	self.window:SetVisible(visible)
end

function MapEditor.PreferencesMenu:GetVisible()
	return self.window:GetVisible()
end

function MapEditor.PreferencesMenu:UpdateValues()
	self.camSensitivityMoveSlider:SetValue(MapEditor.Preferences.camSensitivityMove)
	self.camSensitivityMoveLabel:SetText(
		string.format("Camera movement sensitivity: %.1f" , MapEditor.Preferences.camSensitivityMove)
	)
	
	self.camSensitivityRotSlider:SetValue(MapEditor.Preferences.camSensitivityRot)
	self.camSensitivityRotLabel:SetText(
		string.format("Camera rotation sensitivity: %.3f" , MapEditor.Preferences.camSensitivityRot)
	)
	
	self.camTypeComboBox:SelectItemByName(MapEditor.Preferences.camType)
	
	self.positionSnapTextBox:SetText(string.format("%f" , MapEditor.Preferences.snapPosition))
	
	self.angleSnapTextBox:SetText(string.format("%f" , MapEditor.Preferences.snapAngle))
	
	self.drawLabelsButton:SetText(tostring(MapEditor.Preferences.drawLabels))
	
	self.timeOfDaySlider:SetValue(MapEditor.Preferences.timeOfDay)
	self.timeOfDayLabel:SetText(string.format("Time of day: %i" , MapEditor.Preferences.timeOfDay))
	
	self.weatherSlider:SetValue(MapEditor.Preferences.weatherSeverity)
	self.weatherLabel:SetText(
		string.format("Weather severity: %.1f" , MapEditor.Preferences.weatherSeverity)
	)
end

-- GWEN events

function MapEditor.PreferencesMenu:CamSensitivityMoveSliderChanged()
	local value = self.camSensitivityMoveSlider:GetValue()
	MapEditor.Preferences.camSensitivityMove = value
	self.camSensitivityMoveLabel:SetText(string.format("Camera movement sensitivity: %.1f" , value))
end

function MapEditor.PreferencesMenu:CamSensitivityRotSliderChanged()
	local value = self.camSensitivityRotSlider:GetValue()
	MapEditor.Preferences.camSensitivityRot = value
	self.camSensitivityRotLabel:SetText(string.format("Camera rotation sensitivity: %.3f" , value))
end

function MapEditor.PreferencesMenu:CameraTypeChanged(comboBox)
	local name = comboBox:GetSelectedItem():GetText()
	
	MapEditor.Preferences.camType = name
	
	if MapEditor.map then
		MapEditor.map:SetCameraType(name , Camera:GetPosition() , Camera:GetAngle())
	end
end

function MapEditor.PreferencesMenu:SnapPositionChanged(textBox)
	MapEditor.Preferences.snapPosition = textBox:GetValue()
end

function MapEditor.PreferencesMenu:SnapAngleChanged(textBox)
	MapEditor.Preferences.snapAngle = textBox:GetValue()
end

function MapEditor.PreferencesMenu:DrawLabelsChanged(button)
	MapEditor.Preferences.drawLabels = not MapEditor.Preferences.drawLabels
	
	button:SetText(tostring(MapEditor.Preferences.drawLabels))
end

function MapEditor.PreferencesMenu:TimeOfDaySliderChanged()
	local value = self.timeOfDaySlider:GetValue()
	MapEditor.Preferences.timeOfDay = value
	self.timeOfDayLabel:SetText(string.format("Time of day: %i" , value))
	
	Network:Send("SetTimeOfDay" , MapEditor.Preferences.timeOfDay)
end

function MapEditor.PreferencesMenu:WeatherSliderChanged()
	local value = self.weatherSlider:GetValue()
	MapEditor.Preferences.weatherSeverity = value
	self.weatherLabel:SetText(string.format("Weather severity: %.1f" , value))
	
	Network:Send("SetWeather" , MapEditor.Preferences.weatherSeverity)
end

-- Events

function MapEditor.PreferencesMenu:ResolutionChange(args)
	local position = Vector2(
		(args.size.x - self.window:GetWidth()) * 0.5 ,
		(args.size.y - self.window:GetHeight()) * 0.4
	)
	self.window:SetPosition(position)
end
