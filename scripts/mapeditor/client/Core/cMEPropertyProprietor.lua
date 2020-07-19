-- Used by MapEditor.PropertiesMenu when selecting multiple objects that have common properties.

class("PropertyProprietor" , MapEditor)

function MapEditor.PropertyProprietor:__init(properties)
	-- array of Propertys with the same name that are part of different PropertyManagers.
	self.properties = properties
	self.name = self.properties[1].name
	self.type = self.properties[1].type
	self.subtype = self.properties[1].subtype
	self.defaultElement = self.properties[1].defaultElement
	self.isObject = MapEditor.IsObjectType(self.type) or MapEditor.IsObjectType(self.subtype)
	-- This is copied from commonValue, or if it's nil, it's a sane default value.
	self.value = nil
	self.hasCommonValue = false
	self.description = nil
	
	-- If commonValue ends up nil, there is a conflict. Otherwise, all Propertys have the same value.
	commonValue = nil
	for index , property in ipairs(self.properties) do
		if property.type == "table" then
			if commonValue == nil then
				commonValue = property.value
			else
				local isIdentical = self:CompareTables(commonValue , property.value)
				if isIdentical == false then
					commonValue = nil
					break
				end
			end
		else
			if commonValue == nil then
				commonValue = property.value
			else
				-- Comparing class instances causes an error :|
				if self.isObject then
					local id , commonId = -1 , -1
					if commonValue ~= MapEditor.NoObject then
						commonId = commonValue:GetId()
					end
					if property.value ~= MapEditor.NoObject then
						id = property.value:GetId()
					end
					
					if id ~= commonId then
						commonValue = nil
						break
					end
				else
					if property.value ~= commonValue then
						commonValue = nil
						break
					end
				end
			end
		end
	end
	-- Get self.description.
	for index , property in ipairs(self.properties) do
		if self.description == nil then
			self.description = property.description
		elseif property.description ~= self.description then
			self.description = "[Property descriptions differ]"
			break
		end
	end
	
	if commonValue ~= nil then
		self.hasCommonValue = true
		if self.type == "table" then
			-- Deep copy the table, don't use a reference. Will Copy even work here? I think there's a
			-- reason I didn't use it here. Oh well, I trust my past self. He seems like a cool guy. He
			-- did write this entire script, after all.
			self.value = {}
			for index , value in ipairs(commonValue) do
				table.insert(self.value , value)
			end
		elseif self.isObject then
			self.value = commonValue
		else
			-- If commonValue is a Color or something, we don't want to use the reference.
			self.value = Copy(commonValue) or commonValue
		end
	else
		if self.type == "table" then
			self.value = {}
		else
			self.value = MapEditor.Property.GetDefaultValue(self.type)
		end
	end
end

function MapEditor.PropertyProprietor:CompareTables(a , b)
	if #a == #b then
		for index = 1 , #a do
			if self.isObject then
				if type(a[index]) ~= type(b[index]) then
					return false
				elseif a[index] == MapEditor.NoObject then
					if b[index] ~= MapEditor.NoObject then
						return false
					end
				else
					if a[index]:GetId() ~= b[index]:GetId() then
						return false
					end
				end
			else
				if a[index] ~= b[index] then
					return false
				end
			end
		end
		
		return true
	else
		return false
	end
end

function MapEditor.PropertyProprietor:SetValue(value , noAction)
	-- Don't do anything if nothing changed.
	if self.isObject then
		if MapEditor.Object.Compare(self.value , value) then
			return false
		end
	else
		if self.value == value then
			return false
		end
	end
	
	self.value = value
	
	-- Some special types are already taken care of (ObjectChooser and related).
	if not noAction then
		local args = {
			propertyProprietor = self ,
			value = value ,
		}
		MapEditor.map:SetAction(Actions.PropertyChange , args)
	end
	
	return true
end

function MapEditor.PropertyProprietor:SetTableValue(index , value , noAction)
	-- Don't do anything if nothing changed.
	if self.isObject then
		if MapEditor.Object.Compare(self.value[index] , value) then
			return false
		end
	else
		if self.value[index] == value then
			return false
		end
	end
	
	self:SyncTables()
	
	self.value[index] = value
	
	-- Some special types are already taken care of (ObjectChooser and related).
	if not noAction then
		local args = {
			propertyProprietor = self ,
			value = value ,
			index = index ,
			tableActionType = "Set" ,
		}
		MapEditor.map:SetAction(Actions.PropertyChange , args)
	end
	
	return true
end

function MapEditor.PropertyProprietor:RemoveTableValue(index)
	self:SyncTables()
	
	local args = {
		propertyProprietor = self ,
		index = index ,
		tableActionType = "Remove" ,
	}
	MapEditor.map:SetAction(Actions.PropertyChange , args)
	
	table.remove(self.value , index)
end

function MapEditor.PropertyProprietor:AddTableValue()
	self:SyncTables()
	
	local args = {
		propertyProprietor = self ,
		tableActionType = "Add" ,
	}
	MapEditor.map:SetAction(Actions.PropertyChange , args)
	
	table.insert(self.value , self.defaultElement)
end

-- This edits all of our properties to have the same values.
-- Uhh, wouldn't this result in all properties either not changing or becoming an empty table?
function MapEditor.PropertyProprietor:SyncTables()
	for index , property in ipairs(self.properties) do
		if self:CompareTables(self.value , property.value) == false then
			property.value = {}
			for index , value in ipairs(self.value) do
				property.value[index] = value
			end
		end
	end
end
