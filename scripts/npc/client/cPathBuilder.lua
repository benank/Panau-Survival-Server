class "PathBuilder"

function PathBuilder:__init()
    self.place_position_keybind = string.byte("0")
    self.creating_path = false
    self.path_name = ""
    self.path_positions = {}

    self.paths = {}
    self.show_paths = true

    Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
    Events:Subscribe("KeyUp", self, self.KeyUp)
    Events:Subscribe("Render", self, self.Render)

    Network:Subscribe("npc/SyncPath", self, self.SyncPath)
end

function PathBuilder:LocalPlayerChat(args)
    if args.text:find("/createpath") then -- /createpath pathname
        self:CreatePath(args)
        return false
    end
    if args.text:find("/savepath") then -- /savepath
        self:SavePath(args)
        return false
    end
    if args.text:find("/showpaths") then
        self.show_paths = not self.show_paths
    end
end

function PathBuilder:CreatePath(args)
    if self.creating_path == true then
        Chat:Print("You are already creating a path", Color.Red)
        return
    end

    local chat_tokens = split(args.text, " ")
    local name = chat_tokens[2]
    if not name then
        Chat:Print("Specify a path name!", Color.Red)
        return
    end

    self.path_positions = {}
    self.creating_path = true
    self.path_name = name
end

function PathBuilder:SavePath(args)
    Network:Send("npc/SavePath", {
        path_name = self.path_name,
        path_positions = self.path_positions
    })
    self.creating_path = false
end

function PathBuilder:KeyUp(args)
    if self.creating_path then
        if args.key == self.place_position_keybind then
            table.insert(self.path_positions, LocalPlayer:GetPosition())
        end
    end
end

function PathBuilder:Render(args)
    if self.creating_path and count_table(self.path_positions) > 0 then
        self:RenderNewPathPositions()
    end

    if self.show_paths then
        for path_name, path in pairs(self.paths) do
            self:RenderPath(path)
        end
    end
end

function PathBuilder:RenderNewPathPositions()
    local campos = Camera:GetPosition()
    local previous = self.path_positions[1]

    for index, position in ipairs(self.path_positions) do
        Render:DrawLine(previous, position, Color.Black)

        if Vector3.Distance(campos, position) < 50 then
            Render:FillCircle(Render:WorldToScreen(position), 6, Color.White)
        end

        previous = position
    end
end

function PathBuilder:RenderPath(path)
    local path_name = path:GetName()
    local campos = Camera:GetPosition()
    local path_positions = path:GetPositions()
    local previous = path_positions[1]

    -- Render the path name
    if Vector3.Distance(campos, previous) < 200 then
        local pos = Render:WorldToScreen(previous)
        Render:DrawText(pos, path_name, Color.Red)
    end

    for index, position in ipairs(path_positions) do
        Render:DrawLine(previous, position, Color.White)

        if Vector3.Distance(campos, position) < 50 then
            Render:FillCircle(Render:WorldToScreen(position), 6, Color.Orange)
        end

        previous = position
    end
end

function PathBuilder:SyncPath(args)
    local path = Path()
    path:SetName(args.name)
    path:InitializeFromJsonData(args.serialized_data)

    self.paths[path:GetName()] = path
end

if IsTest then
    PathBuilder = PathBuilder()
end