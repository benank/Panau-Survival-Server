class("SelectBase" , Actions)

function Actions.SelectBase:__init(controlName)
	EGUSM.SubscribeUtility.__init(self)
	MapEditor.Action.__init(self)
	
	self.controlName = controlName
	self.downPosition = Mouse:GetPosition()
	self.delta = Vector2(0 , 0)
	self.color = Color.White
	self:EventSubscribe("Render" , Actions.SelectBase.Render)
	self:EventSubscribe("ControlUp" , Actions.SelectBase.ControlUp)
end

-- Events

function Actions.SelectBase:Render()
	self.delta = Mouse:GetPosition() - self.downPosition
	
	MapEditor.Utility.DrawArea(
		self.downPosition ,
		self.delta ,
		4 ,
		self.color
	)
end

function Actions.SelectBase:ControlUp(args)
	if args.name == self.controlName then
		-- If we dragged to make a decent sized rectangle, select the objects in that rectangle.
		if self.delta:Length() > 16 then
			local pos1 = self.downPosition
			local pos2 = self.downPosition + self.delta
			local left =   math.min(pos1.x , pos2.x)
			local right =  math.max(pos1.x , pos2.x)
			local top =    math.min(pos1.y , pos2.y)
			local bottom = math.max(pos1.y , pos2.y)
			
			-- Iterate through all of the map's objects and call our function on those that are within
			-- the bounds of our selection rectangle.
			-- TODO: This won't scale very well at ALL
			local objects = {}
			local hasObjects = false
			local screenPos , isOnScreen
			MapEditor.map:IterateObjects(function(object)
				local screenPoints = object:GetScreenPoints()
				
				for index , screenPoint in ipairs(screenPoints) do
					if
						screenPoint.x > left and
						screenPoint.x < right and
						screenPoint.y > top and
						screenPoint.y < bottom
					then
						objects[object:GetId()] = object
						hasObjects = true
						break
					end
				end
			end)
			
			if hasObjects then
				self:OnObjectsChosen(objects)
			else
				self:OnNothingChosen()
			end
		-- Otherwise, select a single object that we clicked on.
		else
			local object = MapEditor.map:GetObjectFromScreenPoint(Mouse:GetPosition())
			
			if object then
				self:OnObjectsChosen({[object:GetId()] = object})
			else
				self:OnNothingChosen()
			end
		end
		
		self:UnsubscribeAll()
	end
end
