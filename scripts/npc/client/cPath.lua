class "Path"

function Path:__init()
    getter_setter(self, "name") -- adds Path:GetName and Path:SetName and defines instance.name
    getter_setter(self, "positions") -- adds Path:GetPositions and Path:SetPositions and defines instance.positions
end

function Path:RenderDebug(render_name)
    local cam_pos = Camera:GetPosition()
    local previous = self.positions[1]

    if render_name then
        -- Render the path name
        if Vector3.Distance(cam_pos, previous) < 400 then
            local pos = Render:WorldToScreen(previous)
            Render:DrawText(pos, self.name, Color.Red)
        end
    end

    for index, position in ipairs(self.positions) do
        Render:DrawLine(previous, position, Color.Aqua)

        if Vector3.Distance(cam_pos, position) < 50 then
            Render:FillCircle(Render:WorldToScreen(position), 6, Color.Silver)
            --Render:DrawText(Render:WorldToScreen(position), tostring(index), Color.White)
        end

        previous = position
    end
end

function Path:InitializeFromJsonData(data)
    if data.positions then
        self.positions = {}

        for _, serialized_position in pairs(data.positions) do
            table.insert(self.positions, Serializer:DeserializeVector3(serialized_position))
        end
    end
end

function Path:GetJsonCompatibleData()
    local json_data = {}
    
    
    local serialized_positions = {}
    if self.positions then
        for index, position in ipairs(self.positions) do
            table.insert(serialized_positions, Serializer:SerializeVector3(position, 2))
        end
    end
    json_data.positions = serialized_positions


    return json_data
end