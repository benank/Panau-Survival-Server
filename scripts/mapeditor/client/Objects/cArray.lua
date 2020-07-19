----------------------------------------------------------------------------------------------------
-- Array
----------------------------------------------------------------------------------------------------

class("Array" , Objects)

function Objects.Array:__init(...) ; MapEditor.Object.__init(self , ...)
	self:AddProperty{
		name = "count" ,
		type = "number" ,
		description = "How many of this object's children to duplicate. (Don't add too many "..
		"zeroes. You have been warned.)" ,
	}
	-- Global position offsets
	self:AddProperty{
		name = "offsetX" ,
		type = "number" ,
	}
	self:AddProperty{
		name = "offsetY" ,
		type = "number" ,
	}
	self:AddProperty{
		name = "offsetZ" ,
		type = "number" ,
	}
	-- Global angle offsets
	self:AddProperty{
		name = "offsetYaw" ,
		type = "number" ,
	}
	self:AddProperty{
		name = "offsetPitch" ,
		type = "number" ,
	}
	self:AddProperty{
		name = "offsetRoll" ,
		type = "number" ,
	}
	-- Relative position offsets
	self:AddProperty{
		name = "relativeOffsetX" ,
		type = "number" ,
	}
	self:AddProperty{
		name = "relativeOffsetY" ,
		type = "number" ,
	}
	self:AddProperty{
		name = "relativeOffsetZ" ,
		type = "number" ,
	}
	-- Relative angle offsets
	self:AddProperty{
		name = "relativeOffsetYaw" ,
		type = "number" ,
	}
	self:AddProperty{
		name = "relativeOffsetPitch" ,
		type = "number" ,
	}
	self:AddProperty{
		name = "relativeOffsetRoll" ,
		type = "number" ,
	}
	
	self.selectionStrategy = {type = "Icon" , icon = Icons.Array}
	
	self.baseDuplicateManager = ArrayDuplicateManager(self , nil , self)
end

function Objects.Array:UpdateDuplicateTransforms(duplicateManager)
	local position = duplicateManager.sourceObject:GetPosition()
	local angle = duplicateManager.sourceObject:GetAngle()
	
	local offsetPosition = Vector3(
		self:GetProperty("offsetX").value ,
		self:GetProperty("offsetY").value ,
		self:GetProperty("offsetZ").value
	)
	local offsetAngle = Angle(
		math.rad(self:GetProperty("offsetYaw").value) ,
		math.rad(self:GetProperty("offsetPitch").value) ,
		math.rad(self:GetProperty("offsetRoll").value)
	)
	local relativeOffsetPosition = Vector3(
		self:GetProperty("relativeOffsetX").value ,
		self:GetProperty("relativeOffsetY").value ,
		self:GetProperty("relativeOffsetZ").value
	)
	local relativeOffsetAngle = Angle(
		math.rad(self:GetProperty("relativeOffsetYaw").value) ,
		math.rad(self:GetProperty("relativeOffsetPitch").value) ,
		math.rad(self:GetProperty("relativeOffsetRoll").value)
	)
	
	local Next = function()
		position = position + angle * relativeOffsetPosition
		angle = angle * relativeOffsetAngle
		
		position = position + offsetPosition
		angle = offsetAngle * angle
	end
	
	for index , object in ipairs(duplicateManager.duplicates) do
		Next()
		object:SetLocalPosition(position)
		object:SetLocalAngle(angle)
	end
end

function Objects.Array:OnDestroy()
	self.baseDuplicateManager:Destroy()
end

function Objects.Array:OnRecreate()
	self.baseDuplicateManager = ArrayDuplicateManager(self , nil , self)
end

function Objects.Array:OnRender()
	self.baseDuplicateManager:Render()
end

function Objects.Array:OnPropertyChange(args)
	if args.name == "count" then
		local delta = args.newValue - args.oldValue
		self.baseDuplicateManager:UpdateCount(delta)
	else
		for objectId , duplicateManager in pairs(self.baseDuplicateManager.duplicateManagers) do
			self:UpdateDuplicateTransforms(duplicateManager)
		end
	end
end

function Objects.Array.CreatePropertyMenuAuxControls(base)
	local button = Button.Create(base)
	button:SetPadding(Vector2(6 , 0) , Vector2(6 , 0))
	button:SetDock(GwenPosition.Left)
	button:SetText("Make permanent")
	button:SizeToContents()
	button:Subscribe("Press" , function()
		MapEditor.map:SetAction(Actions.ApplyArray)
	end)
end

----------------------------------------------------------------------------------------------------
-- ArrayDuplicateManager
----------------------------------------------------------------------------------------------------

class("ArrayDuplicateManager")

function ArrayDuplicateManager:__init(array , parentManager , sourceObject)
	EGUSM.SubscribeUtility.__init(self)
	
	self.Destroy = ArrayDuplicateManager.Destroy
	
	self.array = array
	self.parentManager = parentManager
	self.sourceObject = sourceObject
	
	self.duplicates = {}
	self.duplicateManagers = {}
	self.isArray = parentManager == nil
	self.isTopLevel = MapEditor.Object.Compare(self.sourceObject:GetParent() , self.array)
	
	if self.isArray == false then
		local count = self.array:GetProperty("count").value
		self:UpdateCount(count)
	end
	
	self.sourceObject:IterateChildren(function(child)
		self:AddChild(child)
	end)
	
	self:EventSubscribe("ObjectTransformChange")
	self:EventSubscribe("ObjectParentChange")
	self:EventSubscribe("PropertyChange")
end

function ArrayDuplicateManager:Destroy()
	for index , duplicate in ipairs(self.duplicates) do
		duplicate:SetParent(MapEditor.NoObject)
		duplicate:Destroy()
	end
	for objectId , duplicateManager in pairs(self.duplicateManagers) do
		duplicateManager:Destroy()
	end
	
	self:UnsubscribeAll()
end

function ArrayDuplicateManager:Render()
	for index , duplicate in ipairs(self.duplicates) do
		-- Hack: Don't call Render on StaticObjects (after they get their bounds) to improve framerate.
		if duplicate.type == "StaticObject" then
			if duplicate.isUpdatingBounds then
				duplicate:Render()
			end
		else
			duplicate:Render()
		end
	end
	for objectId , duplicateManager in pairs(self.duplicateManagers) do
		duplicateManager:Render()
	end
end

function ArrayDuplicateManager:AddChild(child)
	self.duplicateManagers[child.id] = ArrayDuplicateManager(self.array , self , child)
end

function ArrayDuplicateManager:UpdateCount(delta)
	if self.isArray == false then
		if delta > 0 then
			-- Add some objects.
			for n = 1 , delta do
				local newObject = self.sourceObject:CreateCopy()
				table.insert(self.duplicates , newObject)
				
				if self.isTopLevel then
					newObject:SetLocalPosition(self.sourceObject:GetPosition())
					newObject:SetLocalAngle(self.sourceObject:GetAngle())
				else
					newObject:SetParent(self.parentManager.duplicates[#self.duplicates])
					newObject:SetLocalPosition(self.sourceObject:GetLocalPosition())
					newObject:SetLocalAngle(self.sourceObject:GetLocalAngle())
				end
			end
			
			if self.isTopLevel then
				self.array:UpdateDuplicateTransforms(self)
			end
		elseif delta < 0 then
			-- Remove some objects.
			for n = 1 , -delta do
				local lastDuplicate = self.duplicates[#self.duplicates]
				lastDuplicate:Destroy()
				table.remove(self.duplicates , #self.duplicates)
			end
		end
	end
	
	for objectId , duplicateManager in pairs(self.duplicateManagers) do
		duplicateManager:UpdateCount(delta)
	end
end

-- Events

function ArrayDuplicateManager:ObjectTransformChange(args)
	-- Make sure this is our source object.
	if args.objectId ~= self.sourceObject.id then
		return
	end
	
	if self.isTopLevel then
		self.array:UpdateDuplicateTransforms(self)
	else
		for index , duplicate in ipairs(self.duplicates) do
			duplicate:SetLocalPosition(self.sourceObject:GetLocalPosition())
			duplicate:SetLocalAngle(self.sourceObject:GetLocalAngle())
		end
	end
end

function ArrayDuplicateManager:ObjectParentChange(args)
	-- An object was parented to our source object, so add a duplicate manager for that object.
	if args.newParentId == self.sourceObject.id then
		local object = MapEditor.Object.GetById(args.objectId)
		self:AddChild(object)
	-- An object was unparented to our source object, so remove the duplicate manager we (hopefully)
	-- have for that object.
	elseif args.oldParentId == self.sourceObject.id then
		self.duplicateManagers[args.objectId]:Destroy()
		self.duplicateManagers[args.objectId] = nil
	end
end

function ArrayDuplicateManager:PropertyChange(args)
	-- Make sure this is our source object.
	if args.objectId ~= self.sourceObject.id then
		return
	end
	
	-- Mirror the changed property on all of our duplicates.
	for index , duplicate in ipairs(self.duplicates) do
		duplicate:SetProperty(args.name , self.sourceObject:GetProperty(args.name).value)
	end
end
