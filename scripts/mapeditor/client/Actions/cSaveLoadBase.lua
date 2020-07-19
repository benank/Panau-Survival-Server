class("SaveLoadBase" , Actions)

function Actions.SaveLoadBase:__init()
	EGUSM.SubscribeUtility.__init(self)
	MapEditor.Action.__init(self)
	
	self.CreateWindow = Actions.SaveLoadBase.CreateWindow
	self.Destroy = Actions.SaveLoadBase.Destroy
	self.ResolutionChange = Actions.SaveLoadBase.ResolutionChange
	
	self:CreateWindow()
	
	self:ResolutionChange{size = Render.Size}
	
	Network:Send("RequestMapList" , "")
	
	self:EventSubscribe("ResolutionChange" , Actions.SaveLoadBase.ResolutionChange)
	self:NetworkSubscribe("ReceiveMapList" , Actions.SaveLoadBase.ReceiveMapList)
end

function Actions.SaveLoadBase:CreateWindow()
	local window = Window.Create()
	window:SetTitle("Save/load menu")
	window:SetSize(Vector2(340 , 440))
	window:Subscribe("WindowClosed" , self , Actions.SaveLoadBase.WindowClosed)
	self.window = window
	
	local listBox = ListBox.Create(self.window)
	listBox:SetDock(GwenPosition.Fill)
	listBox:AddItem("Requesting map list...")
	listBox:SetEnabled(false)
	listBox:Subscribe("RowSelected" , self , Actions.SaveLoadBase.RowSelected)
	self.listBox = listBox
	
	local bottomBase = BaseWindow.Create(self.window)
	bottomBase:SetDock(GwenPosition.Bottom)
	bottomBase:SetHeight(24)
	
	local textBox = TextBox.Create(bottomBase)
	textBox:SetMargin(Vector2(2 , 0) , Vector2(4 , 0))
	textBox:SetDock(GwenPosition.Fill)
	textBox:SetEnabled(false)
	textBox:Subscribe("ReturnPressed" , self , Actions.SaveLoadBase.TextBoxOrButtonUsed)
	self.textBox = textBox
	
	local button = Button.Create(bottomBase)
	button:SetPadding(Vector2(12 , 0) , Vector2(12 , 0))
	button:SetDock(GwenPosition.Right)
	button:SetText("Save/load")
	button:SizeToContents()
	button:SetEnabled(false)
	button:Subscribe("Press" , self , Actions.SaveLoadBase.TextBoxOrButtonUsed)
	self.processButton = button
end

function Actions.SaveLoadBase:Destroy()
	if MapEditor.map then
		self:Cancel()
	end
	
	self:UnsubscribeAll()
	self.window:Remove()
end



-- GWEN events

function Actions.SaveLoadBase:WindowClosed()
	self:Destroy()
end

function Actions.SaveLoadBase:RowSelected()
	local name = self.listBox:GetSelectedRow():GetCellText(0)
	self.textBox:SetText(name)
end

function Actions.SaveLoadBase:TextBoxOrButtonUsed()
	local mapName = self.textBox:GetText()
	if mapName:len() == 0 then
		return
	end
	
	self:OnProcess(mapName)
end

-- Events

function Actions.SaveLoadBase:ResolutionChange(args)
	local position = Vector2(
		(args.size.x - self.window:GetWidth()) * 0.5 ,
		(args.size.y - self.window:GetHeight()) * 0.4
	)
	self.window:SetPosition(position)
end

-- Network events

function Actions.SaveLoadBase:ReceiveMapList(maps)
	self.listBox:Clear()
	for index , mapName in ipairs(maps) do
		self.listBox:AddItem(mapName)
	end
	
	self.listBox:SetEnabled(true)
	self.textBox:SetEnabled(true)
	self.processButton:SetEnabled(true)
end
