class "Path"
Path.id_counter = 0

function Path:__init()
    getter_setter(self, "id")
    Path.id_counter = Path.id_counter + 1
    self:SetId(Path.id_counter)
    getter_setter(self, "name") -- adds Path:GetName and Path:SetName and defines instance.name
    getter_setter(self, "positions") -- adds Path:GetPositions and Path:SetPositions and defines instance.positions
end

function Path:InitializeFromJsonData(data)
    if data.positions then
        self.positions = {}

        for _, serialized_position in pairs(data.positions) do
            table.insert(self.positions, Serializer:DeserializeVector3(serialized_position))
        end
    end

    if data.name then
        self.name = data.name
    end
end

function Path:GetJsonCompatibleData()
    local json_data = {}
    
    if self.name then
        json_data["name"] = self.name
    end
    
    local serialized_positions = {}
    if self.positions then
        for index, position in ipairs(self.positions) do
            table.insert(serialized_positions, Serializer:SerializeVector3(position, 2))
        end
    end
    json_data["positions"] = serialized_positions


    return json_data
end

function Path:GetLastNodePosition()
    return self.positions[#self.positions]
end

function Path:GetReversedCopy()
    local new_path = Path()
    local reversed_path_positions = reversed_copy(self.positions)
    new_path:SetName(self.name)
    new_path:SetPositions(reversed_path_positions)
    return new_path
end

