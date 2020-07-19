class("ObjectPlacer" , Actions)

function Actions.ObjectPlacer:__init(objectClass)
	EGUSM.SubscribeUtility.__init(self)
	MapEditor.Action.__init(self)
	
	self.objectClass = objectClass
	self.position = Camera:GetPosition() + Camera:GetAngle() * Vector3.Forward * 5
	self.angle = Angle(0 , 0 , 0)
	self.object = self.objectClass(self.position , self.angle)
	MapEditor.map:AddObject(self.object)
	
	self.controlDisplayer = MapEditor.ControlDisplayer{
		name = "Place object" ,
		linesFromBottom = 3 ,
		"Done" ,
		"Cancel" ,
	}
	
	self:EventSubscribe("Render")
	self:EventSubscribe("ControlUp")
end

function Actions.ObjectPlacer:Undo()
	self.object:Destroy()
	MapEditor.map:RemoveObject(self.object)
end

function Actions.ObjectPlacer:Redo()
	self.object:Recreate()
	MapEditor.map:AddObject(self.object)
end

function Actions.ObjectPlacer:OnConfirmOrCancel()
	self.controlDisplayer:Destroy()
end

-- Events

function Actions.ObjectPlacer:Render()
	local dir = Render:ScreenToWorldDirection(Mouse:GetPosition())
	local result = Physics:Raycast(Camera:GetPosition() , dir , 0.1 , 512)
	self.position = result.position
	self.object:SetPosition(self.position)
end

function Actions.ObjectPlacer:ControlUp(args)
	if args.name == "Done" then
		self:UnsubscribeAll()
		self:Confirm()
	elseif args.name == "Cancel" then
		self.object:Destroy()
		MapEditor.map:RemoveObject(self.object)
		
		self:UnsubscribeAll()
		self:Cancel()
	end
end
