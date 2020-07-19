class("TransformBase" , Actions)

function Actions.TransformBase:__init()
	EGUSM.SubscribeUtility.__init(self)
	MapEditor.Action.__init(self)
	
	self.GetAverageObjectPosition = Actions.TransformBase.GetAverageObjectPosition
	self.Undo = Actions.TransformBase.Undo
	self.Redo = Actions.TransformBase.Redo
	self.OnConfirmOrCancel = Actions.TransformBase.OnConfirmOrCancel
	
	self.mouse = {start = Mouse:GetPosition() , delta = Vector2(0 , 0)}
	-- Map of tables
	--    Key: Object id
	--    Value: map: {
	--       object =         MapEditor.Object ,
	--       startTransform = {position = Vector3 , angle = Angle} ,
	--       endTransform =   {position = Vector3 , angle = Angle} ,
	--    }
	self.objects = {}
	MapEditor.map.selectedObjects:IterateObjects(function(object)
		-- If a child and its parent are moved or rotated at the same time, weird things happen. Make
		-- sure that any selected children of selected objects get removed.
		local isAParentSelected = false
		object:IterateParentChain(function(parent)
			if parent:GetIsSelected() == true then
				isAParentSelected = true
			end
		end)
		if isAParentSelected == true then
			return
		end
		
		self.objects[object:GetId()] = {
			object =         object ,
			startTransform = {position = object:GetPosition() , angle = object:GetAngle()} ,
			endTransform =   {position = object:GetPosition() , angle = object:GetAngle()} ,
		}
	end)
	
	self.pivot = self:GetAverageObjectPosition()
	self.lockedAxis = nil
	self.isLocal = false
	
	Controls.Add("Lock to X axis" , "X")
	Controls.Add("Lock to Y axis" , "Y")
	Controls.Add("Lock to Z axis" , "Z")
	Controls.Add("Toggle local" , "L")
	
	self.controlDisplayer = MapEditor.ControlDisplayer{
		name = "TransformBase" ,
		linesFromBottom = 3 ,
		"Done" ,
		"Cancel" ,
		"Lock to X axis" ,
		"Lock to Y axis" ,
		"Lock to Z axis" ,
		"Toggle local" ,
	}
	
	self.controlDisplayer:SetControlDisplayedName("Toggle local" , "Using global axes")
	
	self:EventSubscribe("Render" , Actions.TransformBase.Render)
	self:EventSubscribe("ControlUp" , Actions.TransformBase.ControlUp)
	self:EventSubscribe("ControlDown" , Actions.TransformBase.ControlDown)
end

function Actions.TransformBase:GetAverageObjectPosition()
	local position = Vector3(0 , 0 , 0)
	local count = 0
	for objectId , objectInfo in pairs(self.objects) do
		position = position + objectInfo.object:GetPosition()
		count = count + 1
	end
	position = position / count
	
	return position
end

function Actions.TransformBase:Undo()
	for objectId , objectInfo in pairs(self.objects) do
		objectInfo.object:SetPosition(objectInfo.startTransform.position)
		objectInfo.object:SetAngle(objectInfo.startTransform.angle)
	end
end

function Actions.TransformBase:Redo()
	for objectId , objectInfo in pairs(self.objects) do
		objectInfo.object:SetPosition(objectInfo.endTransform.position)
		objectInfo.object:SetAngle(objectInfo.endTransform.angle)
	end
end

function Actions.TransformBase:OnConfirmOrCancel()
	self.controlDisplayer:Destroy()
	self:UnsubscribeAll()
end

-- Events

function Actions.TransformBase:Render()
	-- This is here instead of the constructor because of annoying ordering issues (Move's
	-- constructor will be ran after our constructor.)
	if table.count(self.objects) == 0 then
		self:Cancel()
		return
	end
	
	self.mouse.delta = Mouse:GetPosition() - self.mouse.start
	
	if self.OnRender then
		self:OnRender(self.mouse ,self.pivot)
	end
	
	for objectId , objectInfo in pairs(self.objects) do
		-- TODO: probably just send the array (also make it an array, not a map)
		self:OnProcess(objectInfo , self.mouse , self.pivot)
		objectInfo.object:SetPosition(objectInfo.endTransform.position)
		objectInfo.object:SetAngle(objectInfo.endTransform.angle)
	end
end

function Actions.TransformBase:ControlUp(args)
	if args.name == "Done" then
		self:Confirm()
	elseif args.name == "Cancel" then
		self:Undo()
		self:Cancel()
	end
end

function Actions.TransformBase:ControlDown(args)
	local LockAxis = function(axis)
		if self.lockedAxis == axis then
			self.lockedAxis = nil
		else
			self.lockedAxis = axis
		end
	end
	
	if args.name == "Lock to X axis" then
		LockAxis("X")
	elseif args.name == "Lock to Y axis" then
		LockAxis("Y")
	elseif args.name == "Lock to Z axis" then
		LockAxis("Z")
	elseif args.name == "Toggle local" then
		self.isLocal = not self.isLocal
		
		if self.isLocal then
			self.controlDisplayer:SetControlDisplayedName("Toggle local" , "Using local axes")
		else
			self.controlDisplayer:SetControlDisplayedName("Toggle local" , "Using global axes")
		end
	end
end
