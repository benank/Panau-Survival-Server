class("Object" , MapEditor)

-- Static

MapEditor.Object.iconRadius = 1
MapEditor.Object.shadowColor = Color(0 , 0 , 0 , 192)
MapEditor.Object.objects = {}
MapEditor.Object.members = {
	"id" ,
	"type" ,
	"localPosition" ,
	"localAngle" ,
	"isClientSide" ,
}

MapEditor.Object.Unmarshal = function(o)
	local objectClass = Objects[o.type]
	if objectClass == nil then
		error("Object class not found: "..tostring(o.type))
	end
	
	local localPosition = Vector3(o.localPosition[1] , o.localPosition[2] , o.localPosition[3])
	local localAngle = Angle(o.localAngle[1] , o.localAngle[2] , o.localAngle[3] , o.localAngle[4])
	
	local object = objectClass(localPosition , localAngle , o.id)
	
	-- Properties and children are done in PropertyManager.Unmarshal later on.
	
	return object
end

MapEditor.Object.Compare = function(o1 , o2)
	if o1 == MapEditor.NoObject then
		if o2 == MapEditor.NoObject then
			return true
		else
			return false
		end
	else
		if o2 == MapEditor.NoObject then
			return false
		else
			return o1:GetId() == o2:GetId()
		end
	end
end

-- Why not MapEditor.map:GetObject(id)? Because some objects are not part of the map. Array
-- duplicates, for example.
MapEditor.Object.GetById = function(id)
	return MapEditor.Object.objects[id]
end

-- Instance

function MapEditor.Object:__init(initialPosition , initialAngle , id)
	MapEditor.Marshallable.__init(self , MapEditor.Object.members)
	MapEditor.PropertyManager.__init(self)
	
	self.Destroy = MapEditor.Object.Destroy
	self.Recreate = MapEditor.Object.Recreate
	self.Render = MapEditor.Object.Render
	self.SetPosition = MapEditor.Object.SetPosition
	self.SetAngle = MapEditor.Object.SetAngle
	self.SetLocalPosition = MapEditor.Object.SetLocalPosition
	self.SetLocalAngle = MapEditor.Object.SetLocalAngle
	self.SetParent = MapEditor.Object.SetParent
	self.SetSelected = MapEditor.Object.SetSelected
	self.GetId = MapEditor.Object.GetId
	self.GetPosition = MapEditor.Object.GetPosition
	self.GetAngle = MapEditor.Object.GetAngle
	self.GetLocalPosition = MapEditor.Object.GetLocalPosition
	self.GetLocalAngle = MapEditor.Object.GetLocalAngle
	self.GetParent = MapEditor.Object.GetParent
	self.GetIsSelected = MapEditor.Object.GetIsSelected
	self.GetIsScreenPointWithin = MapEditor.Object.GetIsScreenPointWithin
	self.GetScreenPoints = MapEditor.Object.GetScreenPoints
	self.GetCanHaveParent = MapEditor.Object.GetCanHaveParent
	self.IterateChildren = MapEditor.Object.IterateChildren
	self.IterateChildrenRecursive = MapEditor.Object.IterateChildrenRecursive
	self.IterateParentChain = MapEditor.Object.IterateParentChain
	self.AddChild = MapEditor.Object.AddChild
	self.RemoveChild = MapEditor.Object.RemoveChild
	self.RecalculateTransform = MapEditor.Object.RecalculateTransform
	self.CreateCopy = MapEditor.Object.CreateCopy
	self.Marshal = MapEditor.Object.Marshal
	self.__tostring = MapEditor.Object.__tostring
	
	self.id = id or MapEditor.map.objectIdCounter
	MapEditor.map.objectIdCounter = MapEditor.map.objectIdCounter + 1
	self.type = class_info(self).name
	self.localPosition = initialPosition or Vector3(0 , 208 , 0)
	self.localAngle = initialAngle or Angle(0 , 0 , 0)
	self.isClientSide = false
	self.parent = MapEditor.NoObject
	
	-- position and angle are global and are calculated in RecalculateTransform when necessary.
	self.position = self.localPosition
	self.angle = self.localAngle
	
	self.children = {}
	self.isSelected = false
	-- Available types and their variables:
	-- * "Icon",   icon   (Image)
	-- * "Radius", radius (number)
	-- * "Bounds", bounds ({Vector3 , Vector3})
	self.selectionStrategy = {type = "Icon" , icon = Icons.Default}
	self.prettyType = Utility.PrettifyVariableName(self.type)
	self.labelColor = Color(208 , 208 , 208 , 192)
	
	MapEditor.Object.objects[self.id] = self
end

function MapEditor.Object:Destroy()
	if self.OnDestroy then
		self:OnDestroy()
	end
	
	MapEditor.Object.objects[self.id] = nil
end

function MapEditor.Object:Recreate()
	MapEditor.Object.objects[self.id] = self
	
	if self.OnRecreate then
		self:OnRecreate()
	end
end

function MapEditor.Object:Render()
	local labelSourcePosition = Copy(self.position)
	if self.selectionStrategy.type == "Bounds" then
		MapEditor.Utility.DrawBounds{
			position = self.position ,
			angle = self.angle ,
			bounds = self.selectionStrategy.bounds ,
			isSelected = self.isSelected ,
		}
		
		labelSourcePosition.y = labelSourcePosition.y - self.selectionStrategy.bounds[2].y
	elseif self.selectionStrategy.type == "Icon" then
		local transform = Transform3()
		transform:Translate(self.position)
		transform:Rotate(Camera:GetAngle())
		transform:Rotate(Angle(0 , math.tau/-4 , 0))
		Render:SetTransform(transform)
		
		MapEditor.iconModel:SetTexture(self.selectionStrategy.icon)
		MapEditor.iconModel:Draw()
		
		if self.isSelected then
			transform:Rotate(Angle(0 , math.tau/4 , 0))
			Render:SetTransform(transform)
			Render:DrawCircle(Vector3.Zero , MapEditor.Object.iconRadius , Color.LawnGreen)
		end
		
		Render:ResetTransform()
		
		labelSourcePosition.y = labelSourcePosition.y - MapEditor.Object.iconRadius
	elseif self.selectionStrategy.type == "Radius" then
		local transform = Transform3()
		transform:Translate(self.position)
		transform:Rotate(Camera:GetAngle())
		Render:SetTransform(transform)
		
		Render:DrawCircle(Vector3.Zero , self.selectionStrategy.radius , Color.Gray)
		
		if self.isSelected then
			Render:DrawCircle(Vector3.Zero , self.selectionStrategy.radius * 1.05 , Color.LawnGreen)
		end
		
		Render:ResetTransform()
		
		labelSourcePosition.y = labelSourcePosition.y - self.selectionStrategy.radius
	end
	
	if self.OnRender then
		self:OnRender()
	end
	
	-- Draw label.
	if MapEditor.Preferences.drawLabels then
		local screenPosition , success = Render:WorldToScreen(labelSourcePosition)
		if success and screenPosition:IsNaN() == false then
			local text = string.format("%i %s" , self.id , self.prettyType)
			local fontSize = 10
			local textSize = Render:GetTextSize(text , fontSize)
			screenPosition.x = screenPosition.x - textSize.x * 0.5
			screenPosition.y = screenPosition.y + 2
			local shadowPosition = screenPosition + Vector2.One
			
			Render:DrawText(shadowPosition , text , MapEditor.Object.shadowColor , fontSize)
			Render:DrawText(screenPosition , text , self.labelColor , fontSize)
		end
	end
end

function MapEditor.Object:SetPosition(position)
	if self.parent ~= MapEditor.NoObject then
		self.localPosition = self.parent.angle:Inverse() * (position - self.parent.position)
	else
		self.localPosition = position
	end
	
	self:RecalculateTransform()
end

function MapEditor.Object:SetAngle(angle)
	if self.parent ~= MapEditor.NoObject then
		self.localAngle = self.parent.angle:Inverse() * angle
	else
		self.localAngle = angle
	end
	
	self:RecalculateTransform()
end

function MapEditor.Object:SetLocalPosition(localPosition)
	self.localPosition = localPosition
	
	self:RecalculateTransform()
end

function MapEditor.Object:SetLocalAngle(localAngle)
	self.localAngle = localAngle
	
	self:RecalculateTransform()
end

-- keepGlobalTransform is optional.
function MapEditor.Object:SetParent(object , keepGlobalTransform)
	-- Return if our parent won't change.
	if MapEditor.Object.Compare(self.parent , object) then
		return
	end
	-- Make sure we can parent the object.
	if self:GetCanHaveParent(object) == false then
		Chat:Print("Cannot parent "..tostring(self).." to "..tostring(object) , Color.Red)
		return
	end
	-- If we already have a parent, remove us from their children.
	if self.parent ~= MapEditor.NoObject then
		self.parent:RemoveChild(self)
	end
	-- If keepGlobalTransform is true, our global position and angle won't change after parenting.
	if keepGlobalTransform then
		if object ~= MapEditor.NoObject then
			local inverseParentAngle = object.angle:Inverse()
			local deltaPosition = self.position - object.position
			self:SetLocalAngle(inverseParentAngle * self.angle)
			self:SetLocalPosition(inverseParentAngle * deltaPosition)
		else
			self:SetLocalAngle(self.angle)
			self:SetLocalPosition(self.position)
		end
	end
	-- Set our new parent and add us to their children.
	local oldParent = self.parent
	self.parent = object
	if self.parent ~= MapEditor.NoObject then
		self.parent:AddChild(self)
	end
	-- Recalculate our transform (as well as our children's).
	self:RecalculateTransform()
	-- Fire the ObjectParentChange event.
	local args = {
		objectId = self:GetId() ,
	}
	if oldParent ~= MapEditor.NoObject then
		args.oldParentId = oldParent:GetId()
	end
	if self.parent ~= MapEditor.NoObject then
		args.newParentId = self.parent:GetId()
	end
	Events:Fire("ObjectParentChange" , args)
end

function MapEditor.Object:SetSelected(selected)
	if self.isSelected == selected then
		return
	end
	
	self.isSelected = selected
	
	if self.isSelected then
		MapEditor.map.selectedObjects:AddObject(self)
		if self.OnSelect then
			self:OnSelect()
		end
	else
		MapEditor.map.selectedObjects:RemoveObject(self)
		if self.OnDeselect then
			self:OnDeselect()
		end
	end
end

function MapEditor.Object:GetId()
	return self.id
end

function MapEditor.Object:GetPosition()
	return self.position
end

function MapEditor.Object:GetAngle()
	return self.angle
end

function MapEditor.Object:GetLocalPosition()
	return self.localPosition
end

function MapEditor.Object:GetLocalAngle()
	return self.localAngle
end

function MapEditor.Object:GetParent()
	return self.parent
end

function MapEditor.Object:GetIsSelected()
	return self.isSelected
end

function MapEditor.Object:GetIsScreenPointWithin(screenPointToTest)
	if self.selectionStrategy.type == "Bounds" then
		-- Take the bounding box screen points and convert them to a screen rect, then test to see if
		-- screenPointToTest is within that. Not perfect, but there's not much else to do.
		
		local screenPoints = self:GetScreenPoints()
		if #screenPoints == 0 then
			return false
		end
		
		local xMin = 50000
		local xMax = 0
		local yMin = 50000
		local yMax = 0
		for index , screenPoint in ipairs(screenPoints) do
			xMin = math.min(xMin , screenPoint.x)
			xMax = math.max(xMax , screenPoint.x)
			yMin = math.min(yMin , screenPoint.y)
			yMax = math.max(yMax , screenPoint.y)
		end
		
		local isWithinBounds = (
			screenPointToTest.x > xMin and
			screenPointToTest.x < xMax and
			screenPointToTest.y > yMin and
			screenPointToTest.y < yMax
		)
		
		return isWithinBounds
	else
		-- Test if screenPointToTest is within a determined screen radius of us.
		
		local screenPoint , success = Render:WorldToScreen(self.position)
		if success == false then
			return false
		end
		
		local distance = Vector3.Distance(Camera:GetPosition() , self.position)
		-- I'm not sure why this works exactly but it works.
		local screenRadius = (Render.Height * math.sqrt2) / distance
		local screenDistance = Vector2.Distance(screenPoint , screenPointToTest)
		
		if self.selectionStrategy.type == "Icon" then
			screenRadius = screenRadius * MapEditor.Object.iconRadius
		elseif self.selectionStrategy.type == "Radius" then
			screenRadius = screenRadius * self.selectionStrategy.radius
		else
			error("Invalid selection strategy: "..tostring(self.selectionStrategy.type))
		end
		
		return screenDistance <= screenRadius
	end
end

function MapEditor.Object:GetScreenPoints()
	local points = {}
	
	local positionsToCheck = {}
	if self.selectionStrategy.type == "Icon" then
		table.insert(positionsToCheck , self.position)
	elseif self.selectionStrategy.type == "Radius" then
		-- Not sure if this is the best idea.
		-- TODO: Use an rectangle/circle collision algorithm.
		local position = self.position
		local radius = self.selectionStrategy.radius
		local radius2 = radius * math.sqrt3 * 0.5
		positionsToCheck = {
			position ,
			position + Vector3(radius , 0 , 0) ,
			position + Vector3(-radius , 0 , 0) ,
			position + Vector3(0 , radius , 0) ,
			position + Vector3(0 , -radius , 0) ,
			position + Vector3(0 , 0 , radius) ,
			position + Vector3(0 , 0 , -radius) ,
			position + Vector3(radius2 , radius2 , radius2) ,
			position + Vector3(-radius2 , radius2 , radius2) ,
			position + Vector3(radius2 , radius2 , -radius2) ,
			position + Vector3(-radius2 , radius2 , -radius2) ,
			position + Vector3(radius2 , -radius2 , radius2) ,
			position + Vector3(-radius2 , -radius2 , radius2) ,
			position + Vector3(radius2 , -radius2 , -radius2) ,
			position + Vector3(-radius2 , -radius2 , -radius2) ,
		}
	elseif self.selectionStrategy.type == "Bounds" then
		local bounds = self.selectionStrategy.bounds
		local position = self.position
		local angle = self.angle
		positionsToCheck = {
			position ,
			position + angle * Vector3(bounds[1].x , bounds[1].y , bounds[1].z) ,
			position + angle * Vector3(bounds[2].x , bounds[1].y , bounds[1].z) ,
			position + angle * Vector3(bounds[1].x , bounds[1].y , bounds[2].z) ,
			position + angle * Vector3(bounds[2].x , bounds[1].y , bounds[2].z) ,
			position + angle * Vector3(bounds[1].x , bounds[2].y , bounds[1].z) ,
			position + angle * Vector3(bounds[2].x , bounds[2].y , bounds[1].z) ,
			position + angle * Vector3(bounds[1].x , bounds[2].y , bounds[2].z) ,
			position + angle * Vector3(bounds[2].x , bounds[2].y , bounds[2].z) ,
		}
	end
	
	for index , positionToCheck in ipairs(positionsToCheck) do
		local screenPos , success = Render:WorldToScreen(positionToCheck)
		if success then
			table.insert(points , screenPos)
		end
	end
	
	return points
end

function MapEditor.Object:GetCanHaveParent(object)
	-- Return true if object is none.
	if object == MapEditor.NoObject then
		return true
	end
	-- Return false if the object is one of our children or ourselves.
	local parentBuffer = object
	while parentBuffer ~= MapEditor.NoObject do
		if MapEditor.Object.Compare(parentBuffer , self) then
			return false
		end
		
		parentBuffer = parentBuffer:GetParent()
	end
	
	return true
end

function MapEditor.Object:IterateChildren(func)
	for n = #self.children , 1 , -1 do
		func(self.children[n])
	end
end

function MapEditor.Object:IterateChildrenRecursive(func)
	for n = #self.children , 1 , -1 do
		local child = self.children[n]
		
		func(child)
		
		child:IterateChildrenRecursive(func)
	end
end

function MapEditor.Object:IterateParentChain(func)
	if self.parent ~= MapEditor.NoObject then
		func(self.parent)
		self.parent:IterateParentChain(func)
	end
end

function MapEditor.Object:AddChild(object)
	table.insert(self.children , object)
end

function MapEditor.Object:RemoveChild(object)
	for index , child in ipairs(self.children) do
		if MapEditor.Object.Compare(child , object) then
			table.remove(self.children , index)
			break
		end
	end
end

function MapEditor.Object:RecalculateTransform()
	local previousPosition = self.position
	local previousAngle = self.angle
	
	if self.parent ~= MapEditor.NoObject then
		self.angle = self.parent.angle * self.localAngle
		self.position = self.parent.position + self.parent.angle * self.localPosition
	else
		self.angle = self.localAngle
		self.position = self.localPosition
	end
	-- If the transform changed, call OnTransformChange and fire ObjectTransformChange.
	if
		Utility.CompareVectors(self.position , previousPosition) == false or
		Utility.CompareAngles(self.angle , previousAngle) == false
	then
		if self.OnTransformChange then
			self:OnTransformChange(self.position , self.angle)
		end
		
		local args = {
			objectId = self.id ,
			position = self.position ,
			angle = self.angle ,
		}
		Events:Fire("ObjectTransformChange" , args)
	end
	-- Call RecalculateTransform on our children.
	self:IterateChildren(MapEditor.Object.RecalculateTransform)
end

function MapEditor.Object:CreateCopy()
	local newObject = Objects[self.type]()
	
	self:IterateProperties(function(property)
		newObject:SetProperty(property.name , property.value)
	end)
	
	return newObject
end

-- TODO: Haaaaaack, make the marshalling system better
function MapEditor.Object:Marshal()
	local t = MapEditor.PropertyManager.Marshal(self)
	if self.parent ~= MapEditor.NoObject then
		t.parent = self.parent:GetId()
	end
	return t
end

function MapEditor.Object:__tostring()
	return string.format("%s (id %i)" , self.type , self.id)
end
