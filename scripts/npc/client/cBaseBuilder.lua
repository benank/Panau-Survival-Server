class "BaseBuilder"

function BaseBuilder:__init()
    self.debug_bases = {}
    self.debug_enabled = false

    Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)

    if IsTest and self.debug_enabled then
        Events:Subscribe("Render", self, self.Render)
    end

    Network:Subscribe("npc/SyncDebugBase", self, self.SyncDebugBase)
end

function BaseBuilder:LocalPlayerChat(args)
end

function BaseBuilder:SyncDebugBase(args)
    local base = Base()
    base:SetName(args.name)
    base:InitializeFromJsonData(args.serialized_data)

    --output_table(args)
    self.debug_bases[args.name] = base
end

function BaseBuilder:Render()
    for base_name, base in pairs(self.debug_bases) do
        self:RenderBaseDebug(base)
    end
end

function BaseBuilder:RenderBaseDebug(base)
    local base_pos = base:GetPosition()

    if base_pos then
        -- Render the base name at base position
        if Vector3.Distance(Camera:GetPosition(), base_pos) < 800 then
            local pos = Render:WorldToScreen(base_pos)
            Render:DrawText(pos, "Base: [ " .. base:GetName() .. " ]", Color.Aqua)
        end
    end

    for spawn_point_name, spawn_point in pairs(base:GetSpawnPoints()) do
        self:RenderSpawnPoint(spawn_point)    
    end
end

function BaseBuilder:RenderSpawnPoint(spawn_point)
    if spawn_point:GetPath() then
        local spawn_point_path = spawn_point:GetPath()
        spawn_point_path:RenderDebug(false) -- render just the Path positions

        -- render the spawn point name at first path position since there is a Path
        local first_pos = spawn_point_path:GetPositions()[1]
        if Vector3.Distance(Camera:GetPosition(), first_pos) < 600 then
            Render:DrawText(Render:WorldToScreen(first_pos), "Spawn Point: [ " .. spawn_point:GetName() .. " ]", Color.LawnGreen)
        end
    end

    if spawn_point:GetSpawnPosition() then
        local spawn_pos = spawn_point:GetSpawnPosition()
        -- Render the spawn point name at spawn point position
        if Vector3.Distance(Camera:GetPosition(), spawn_pos) < 800 then
            local transform = Transform3()
            transform:Translate(spawn_pos)
            transform:Rotate(Angle(0, math.pi / 2, 0))
            Render:SetTransform(transform)
            Render:FillCircle(Vector3.Zero, 1.75, Color.FireBrick)
            Render:ResetTransform()

            local yaw = spawn_point:GetSpawnPositionYaw() or 0
            Render:DrawLine(spawn_pos, spawn_pos + (Angle(yaw, 0, 0) * (Vector3.Forward * 1.75)), Color.Black)

            local pos = Render:WorldToScreen(spawn_pos + Vector3(0, 0.5, 0))
            Render:DrawText(pos, "Spawn Point: [ " .. tostring(spawn_point:GetName()) .. " ]", Color.LawnGreen)
        end
    end
    -- render the spawn point name at defined sp position
    --if self.position then
    --Render:DrawText(Render:WorldToScreen(self.position), "Spawn Point: [ " .. spawn_point:GetName() .. " ]", Color.LawnGreen)
    --end
end

if IsTest then
    BaseBuilder = BaseBuilder()
end