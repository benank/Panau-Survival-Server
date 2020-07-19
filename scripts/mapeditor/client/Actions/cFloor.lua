class("Floor" , Actions)

function Actions.Floor:__init()
	MapEditor.Action.__init(self)
	
	self.objectsInfo = {}
	MapEditor.map.selectedObjects:IterateObjects(function(object)
		table.insert(self.objectsInfo , {object = object , originalPosition = object:GetPosition()})
	end)
	
	if #self.objectsInfo > 0 then
		self:Redo()
		self:Confirm()
	else
		self:Cancel()
	end
end

function Actions.Floor:Undo()
	for index , objectInfo in ipairs(self.objectsInfo) do
		objectInfo.object:SetPosition(objectInfo.originalPosition)
	end
end

function Actions.Floor:Redo()
	for index , objectInfo in ipairs(self.objectsInfo) do
		local result = Physics:Raycast(
			objectInfo.object:GetPosition() ,
			-Vector3.Up ,
			0.001 ,
			60
		)
		
		-- Clamp y to sea level.
		result.position.y = math.max(200 , result.position.y)
		
		if result.distance < 60 then
			objectInfo.object:SetPosition(result.position)
		end
	end
end
