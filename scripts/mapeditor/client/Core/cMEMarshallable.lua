class("Marshallable" , MapEditor)

-- Static functions

MapEditor.Marshallable.MarshalValue = function(value)
	local valueType = type(value)
	if valueType == "userdata" then
		if value.Marshal then
			return value:Marshal()
		else
			local marshalFunction = MapEditor.Marshallable.MarshalByType[value.__type]
			if marshalFunction then
				return marshalFunction(value)
			else
				error("Cannot marshal value: "..tostring(memberName))
			end
		end
	elseif valueType == "table" then
		local t = {}
		for k , v in pairs(value) do
			t[k] = MapEditor.Marshallable.MarshalValue(v)
		end
		return t
	else
		return value
	end
end

MapEditor.Marshallable.MarshalByType = {}

MapEditor.Marshallable.MarshalByType.Vector2 = function(value)
	return {value.x , value.y}
end

MapEditor.Marshallable.MarshalByType.Vector3 = function(value)
	return {value.x , value.y , value.z}
end

MapEditor.Marshallable.MarshalByType.Angle = function(value)
	return {value.x , value.y , value.z , value.w}
end

MapEditor.Marshallable.MarshalByType.Color = function(value)
	return {value.r , value.g , value.b , value.a}
end

-- Instance functions

function MapEditor.Marshallable:__init(memberNames)
	-- Expose functions.
	self.Marshal = MapEditor.Marshallable.Marshal
	
	if self.memberNames then
		for index , memberName in ipairs(memberNames or {}) do
			table.insert(self.memberNames , memberName)
		end
	else
		self.memberNames = memberNames or {}
	end
end

function MapEditor.Marshallable:Marshal()
	local t = {}
	
	for index , memberName in ipairs(self.memberNames) do
		local member = self[memberName]
		if member ~= nil then
			local marshalledMember = MapEditor.Marshallable.MarshalValue(member)
			t[memberName] = marshalledMember
		end
	end
	
	return t
end
