class "Base"

function Base:__init()
    getter_setter(self, "name") -- adds Base:GetName and Base:SetName and defines instance.name
    getter_setter(self, "radius") -- adds Base:GetRadius and Base:SetRadius and defines instance.radius
    getter_setter(self, "position") -- adds Base:GetPosition and Base:SetPosition and defines instance.position
    getter_setter(self, "spawn_points") -- adds Base:GetSpawnPoints and Base:SetSpawnPoints and defines instance.spawn_points
    --self:SetRadius(1000)
    self:SetSpawnPoints({})
end

function Base:InitializeFromJsonData(data)
    if data.name then
        self.name = data.name
    end

    if data.position then
        self.position = Serializer:DeserializeVector3(data.position)
    end

    if data.radius then
        self.radius = data.radius
    end

    if data.spawn_points then
        self.spawn_points = {}

        for spawn_point_name, spawn_point_data in pairs(data.spawn_points) do
            local spawn_point = SpawnPoint()
            spawn_point:InitializeFromJsonData(spawn_point_data)

            self.spawn_points[spawn_point_name] = spawn_point
        end
    end
end

function Base:AddSpawnPoint(spawn_point)
    self.spawn_points[spawn_point:GetName()] = spawn_point
end

function Base:RemoveSpawnPoint(spawn_point_name)
    self.spawn_points[spawn_point_name] = nil
end

function Base:GetJsonCompatibleData()
    local json_data = {}

    if self.name then
        json_data.name = self.name
    end

    if self.position then
        json_data.position = Serializer:SerializeVector3(self.position, 2)
    end

    if self.radius then
        json_data.radius = self.radius
    end

    if self.spawn_points and count_table(self.spawn_points) > 0 then
        json_data["spawn_points"] = {}
        for spawn_point_name, spawn_point in pairs(self.spawn_points) do
            json_data["spawn_points"][spawn_point_name] = spawn_point:GetJsonCompatibleData()
        end
    end

    return json_data
end

function Base:SpawnActors()
    for spawn_point_name, spawn_point in pairs(self.spawn_points) do
        local actor_profile_instance = ActorManager:CreateActor(spawn_point:GetActorProfileEnum())
        actor_profile_instance:InitializeFromSpawnPoint(spawn_point)
        actor_profile_instance.actor:SetActive(true)
    end
end