class 'DynamicCellTable'
-- holds one value per cell
-- good, easy-to-use system for storing things based on cells
-- be careful if using custom class instances this
-- deep copies default value if it is a table

function DynamicCellTable:__init(data, default_entry_value)
	if data then
		self.data = data
	else
		self.data = {}
	end
	
	self.default_entry_value = default_entry_value
end

function DynamicCellTable:AddEntry(x, y, entry)
	if not self.data[x] then self.data[x] = {} end
	
	if entry and type(entry) == "table" then
		local copied_entry = Copy(entry) -- deep copy
		self.data[x][y] = copied_entry
	else
		self.data[x][y] = entry
	end
	
	return self.data[x][y]
end

function DynamicCellTable:HasValue(x, y)
	return (self.data[x] and self.data[x][y])
end

function DynamicCellTable:GetValue(x, y) -- set value to default if it doesn't exist and return default
	if self.data[x] and self.data[x][y] then
		return self.data[x][y]
	else
		return self:AddEntry(x, y, self.default_entry_value)
	end
end

function DynamicCellTable:SetValue(x, y, value) -- set value to value if it doesn't exist
	if self.data[x] and self.data[x][y] then
		self.data[x][y] = value
	else
		self:AddEntry(x, y, value)
	end
end

-- dynamic cell table iterator
function dynamic_cell_table(dct)
	local iterator_out = {}
	
	for _x, x_table in pairs(dct.data) do
		for _y, value in pairs(x_table) do
			table.insert(iterator_out, {x = _x, y = _y, entry = value})
		end
	end
	
	local i = 0
	return function()
		i = i + 1
		if iterator_out[i] then
			return iterator_out[i].x, iterator_out[i].y, iterator_out[i].entry
		else
			return nil, nil, nil
		end
	end
end