-- Manages choosing an Object when changing an Object property from the properties menu.

class("ObjectChooser" , MapEditor)

function MapEditor.ObjectChooser:__init(objectType , callback , instance)
	EGUSM.SubscribeUtility.__init(self)
	
	self.objectType = objectType
	self.callback = callback
	self.instance = instance
	
	self.controlDisplayer = MapEditor.ControlDisplayer{
		name = "Choose object" ,
		linesFromBottom = 3 ,
		"Done" ,
		"Cancel" ,
	}
	
	self:EventSubscribe("Render")
	self:EventSubscribe("ControlUp")
end

function MapEditor.ObjectChooser:CallCallback(object)
	if self.instance then
		self.callback(self.instance , object)
	else
		self.callback(object)
	end
	
	self.controlDisplayer:Destroy()
	self:Destroy()
end

-- Events

function MapEditor.ObjectChooser:Render()
	-- Draw a simple cursor thing on the mouse.
	local mousePos = Mouse:GetPosition()
	local size = 60
	Render:DrawLine(
		mousePos + Vector2(-size , 0) ,
		mousePos + Vector2(size , 0) ,
		Color(127 , 127 , 127 , 127)
	)
	Render:DrawLine(
		mousePos + Vector2(0 , -size) ,
		mousePos + Vector2(0 , size) ,
		Color(127 , 127 , 127 , 127)
	)
end

function MapEditor.ObjectChooser:ControlUp(args)
	if args.name == "Done" then
		local object = MapEditor.map:GetObjectFromScreenPoint(Mouse:GetPosition())
		if object then
			local isCorrectType = false
			if self.objectType == "Object" then
				isCorrectType = true
			elseif class_info(object).name == self.objectType then
				isCorrectType = true
			end
			
			if isCorrectType then
				self:CallCallback(object)
			else
				self:CallCallback(MapEditor.NoObject)
			end
		else
			self:CallCallback(MapEditor.NoObject)
		end
		
		Events:Fire("SetMenusEnabled" , true)
	elseif args.name == "Cancel" then
		self:CallCallback(nil)
	end
end
