class("Property" , MapEditor)

MapEditor.Property.GetDefaultValue = function(type)
	if type == "number" then
		return 0
	elseif type == "string" then
		return ""
	elseif type == "boolean" then
		return false
	elseif type == "table" then
		return {}
	elseif type == "Color" then
		return Color(255 , 255 , 255)
	elseif MapEditor.IsObjectType(type) then
		return MapEditor.NoObject
	elseif type == "model" then
		return ""
	end
end

function MapEditor.Property:__init(args)
	self.propertyManager = args.propertyManager
	self.name = args.name
	self.type = args.type
	self.subtype = args.subtype
	self.description = args.description or "[No description.]"
	
	self.value = args.default or MapEditor.Property.GetDefaultValue(self.type)
	
	if self.type == "table" then
		self.defaultElement = args.defaultElement or MapEditor.Property.GetDefaultValue(self.subtype)
	end
end

function MapEditor.Property:SetValue(value , index)
	local copiedValue
	if self.type == "table" and index == nil then
		copiedValue = {}
		for index , value in ipairs(value) do
			if MapEditor.IsObjectType(self.subtype) then
				copiedValue[index] = value
			else
				copiedValue[index] = Copy(value) or value
			end
		end
	else
		if MapEditor.IsObjectType(self.type) or MapEditor.IsObjectType(self.subtype) then
			copiedValue = value
		else
			copiedValue = Copy(value) or value
		end
	end
	
	local oldValue = self.value
	local isSame = false
	if index then
		if self.value[index] == copiedValue then
			isSame = true
		end
		self.value[index] = copiedValue
	else
		if self.value == copiedValue then
			isSame = true
		end
		self.value = copiedValue
	end
	
	if isSame == false then
		self.propertyManager:PropertyChanged{
			name = self.name ,
			newValue = self.value ,
			oldValue = oldValue ,
		}
	end
end
