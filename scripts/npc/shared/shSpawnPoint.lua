class "SpawnPoint"

function SpawnPoint:__init()
    getter_setter(self, "name") -- adds SpawnPoint:GetName and SpawnPoint:SetName
    getter_setter(self, "base_name") -- adds SpawnPoint:GetBaseName and SpawnPoint:SetBaseName
    getter_setter(self, "actor_profile_enum") -- adds SpawnPoint:GetActorProfileEnum and SpawnPoint:SetActorProfileEnum
    getter_setter(self, "path") -- adds SpawnPoint:GetPath and SpawnPoint:SetPath
    getter_setter(self, "spawn_position") -- adds SpawnPoint:GetSpawnPosition and SpawnPoint:SetSpawnPosition
    getter_setter(self, "spawn_position_yaw") -- adds SpawnPoint:GetSpawnPositionYaw and SpawnPoint:SetSpawnPositionYaw
end

function SpawnPoint:GetJsonCompatibleData()
    local json_data = {}

    if self.name then
        json_data["name"] = self.name
    end

    if self.base_name then
        json_data["base_name"] = self.base_name
    end

    -- serialize the Path
    if self.path then
        local path_data = self.path:GetJsonCompatibleData()
        json_data["path"] = path_data
    end

    if self.actor_profile_enum then
        json_data["actor_profile_enum"] = self.actor_profile_enum
    end

    if self.spawn_position then
        json_data["spawn_position"] = Serializer:SerializeVector3(self.spawn_position, 3)
        json_data["spawn_position_yaw"] = self.spawn_position_yaw
    end

    return json_data
end

function SpawnPoint:InitializeFromJsonData(data)
    if data.name then
        self.name = data.name
    end

    if data.base_name then
        self.base_name = data.base_name
    end

    -- load a serialized Path
    if data.path then
        local path = Path()
        path:InitializeFromJsonData(data.path)
        self.path = path
    end

    if data.actor_profile_enum then
        self.actor_profile_enum = tonumber(data.actor_profile_enum)
    end

    if data.spawn_position then
        self.spawn_position = Serializer:DeserializeVector3(data.spawn_position)
        self.spawn_position_yaw = tonumber(data.spawn_position_yaw)
    end
end