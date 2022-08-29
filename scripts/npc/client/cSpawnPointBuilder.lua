class "SpawnPointBuilder"

function SpawnPointBuilder:__init()
    self.creating_spawn_point = false
    self.building_spawn_point_path_name = nil
    self.building_spawn_point = SpawnPoint()

    Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
    Events:Subscribe("Render", self, self.RenderDebug)

    --Network:Subscribe("npc/SyncPatrol", self, self.SyncPatrol)
end

function SpawnPointBuilder:LocalPlayerChat(args)
    if args.text:find("/createsp") then -- /createsp basename spawn_point_name
        self:CreateSpawnPoint(args)
        return false
    end
    if args.text:find("/setactorprofile") then -- /setactorprofile actor_profile_enum
        self:SetActorProfile(args)
        return false
    end
    if args.text:find("/setpath") then -- /setpath path_name
        self:SetPath(args)
        return false
    end
    if args.text:find("/savesp") then -- /savesp
        self:SaveSpawnPoint(args)
        return false
    end
    if args.text:find("/outputsp") then -- /outputsp
        self:OutputSpawnPoint()
        return false
    end
    if args.text:find("/setspawnpos") then -- /setspawnpos
        self:SetSpawnPosition(args)
        return false
    end
end

function SpawnPointBuilder:CreateSpawnPoint(args)
    if self.creating_spawn_point == true then
        Chat:Print("You are already creating a spawn point", Color.Red)
        return
    end

    local chat_tokens = split(args.text, " ")
    local base_name = chat_tokens[2]
    local spawn_point_name = chat_tokens[3]
    if not base_name then
        Chat:Print("Specify a base name", Color.Red)
        return
    end

    if not spawn_point_name then
        Chat:Print("Specify a spawn point name", Color.Red)
        return
    end

    self.creating_spawn_point = true
    self.building_spawn_point = SpawnPoint()
    self.building_spawn_point:SetName(spawn_point_name)
    self.building_spawn_point:SetBaseName(base_name)

    self:OutputSpawnPoint()
end

function SpawnPointBuilder:SetActorProfile(args)
    if not self.creating_spawn_point then
        Chat:Print("You are not currently creating a spawn point!", Color.Red)
        return
    end

    local chat_tokens = split(args.text, " ")
    local actor_profile_enum = chat_tokens[2]
    if not actor_profile_enum then
        Chat:Print("Specify a actor profile enum!", Color.Red)
        return
    end

    self.building_spawn_point:SetActorProfileEnum(tonumber(actor_profile_enum))
    self:OutputSpawnPoint()
end

function SpawnPointBuilder:SetPath(args)
    if not self.creating_spawn_point then
        Chat:Print("You are not currently creating a spawn point!", Color.Red)
        return
    end

    local chat_tokens = split(args.text, " ")
    local path_name = chat_tokens[2]
    if not path_name then
        Chat:Print("Specify a path name!", Color.Red)
        return
    end

    self.building_spawn_point_path_name = path_name
    self:OutputSpawnPoint()
end

function SpawnPointBuilder:SaveSpawnPoint(args)
    Network:Send("npc/AddSpawnPoint", {
        spawn_point_data = self.building_spawn_point:GetJsonCompatibleData(),
        path_name = self.building_spawn_point_path_name
    })

    self.creating_spawn_point = false
    self.building_spawn_point_path_name = nil
end

function SpawnPointBuilder:SetSpawnPosition(args)
    if not self.creating_spawn_point then
        Chat:Print("You are not currently creating a spawn point!", Color.Red)
        return
    end

    self.building_spawn_point:SetSpawnPosition(LocalPlayer:GetPosition())
    self.building_spawn_point:SetSpawnPositionYaw(LocalPlayer:GetAngle().yaw)
    self:OutputSpawnPoint()
end

function SpawnPointBuilder:OutputSpawnPoint()
    if not self.creating_spawn_point then
        Chat:Print("You are not currently creating a spawn point!", Color.Red)
        return
    end

    Chat:Print("-------------------------", Color.White)
    Chat:Print("SpawnPoint [ ", Color.White, tostring(self.building_spawn_point:GetName()), Color.LawnGreen, " ] for base [ ", Color.White,
        tostring(self.building_spawn_point:GetBaseName()), Color.LawnGreen, " ]:", Color.White)
    if self.building_spawn_point_path_name then
        Chat:Print("Path name: [ ", Color.White, tostring(self.building_spawn_point_path_name), Color.LawnGreen, " ]", Color.White)
    end
    if self.building_spawn_point:GetActorProfileEnum() then
        Chat:Print("Actor Profile: [ ", Color.White, tostring(ActorProfileEnum:GetDescription(self.building_spawn_point:GetActorProfileEnum())), Color.LawnGreen, " ]", Color.White)
    end
    if self.building_spawn_point:GetSpawnPosition() then
        Chat:Print("Spawn Position: [ ", Color.White, tostring(self.building_spawn_point:GetSpawnPosition()), Color.LawnGreen, " ]", Color.White)
    end
end

function SpawnPointBuilder:RenderDebug()
    if self.creating_spawn_point then
        if self.building_spawn_point:GetSpawnPosition() then
            local spawn_pos = self.building_spawn_point:GetSpawnPosition()
            -- Render the base name at base position
            if Vector3.Distance(Camera:GetPosition(), spawn_pos) < 800 then
                local transform = Transform3()
                transform:Translate(spawn_pos)
                transform:Rotate(Angle(0, math.pi / 2, 0))
                Render:SetTransform(transform)
                Render:FillCircle(Vector3.Zero, 1.75, Color.FireBrick)
                Render:ResetTransform()

                Render:DrawLine(spawn_pos, spawn_pos + (Angle(self.building_spawn_point:GetSpawnPositionYaw(), 0, 0) * (Vector3.Forward * 1.75)), Color.Black)

                local pos = Render:WorldToScreen(spawn_pos)
                Render:DrawText(pos, "Spawn Point: [ " .. self.building_spawn_point:GetName() .. " ]", Color.White)
            end
        end
    end
end

if IsTest then
    SpawnPointBuilder = SpawnPointBuilder()
end