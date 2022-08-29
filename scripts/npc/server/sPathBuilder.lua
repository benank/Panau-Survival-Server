class "PathBuilder"

function PathBuilder:__init()
    self.temp_name_counter = 0
    self.paths = {}

    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    Network:Subscribe("npc/SavePath", self, self.SavePath)
end

function PathBuilder:ModuleLoad()
    DirectoryUtils:GetFilesInDirectory("./scripts/npc/paths", ".json", self, self.LoadAllPaths)
end

function PathBuilder:LoadAllPaths(filepaths)
    for _, path_filepath in ipairs(filepaths) do
        local path_name = path_filepath:sub(1, -6)
        local path_data = PathSerialization:GetPathDataFromFile(path_name)

        local path = Path()
        path:SetName(path_name)
        path:InitializeFromJsonData(path_data)

        self.paths[path_name] = path
    end

    self:SyncPaths()
end

-- called on /savepath
function PathBuilder:SavePath(args)
    local path = Path()
    path:SetName(args.path_name)
    path:SetPositions(args.path_positions)

    PathSerialization:SavePath(path)
    self:SyncPath(path)
end

function PathBuilder:SyncPaths()
    Thread(function()
        for path_name, path in pairs(self.paths) do
            self:SyncPath(path)
            Timer.Sleep(400)
        end
    end)

end

function PathBuilder:SyncPath(path)
    Network:Broadcast("npc/SyncPath", {
        name = path:GetName(),
        serialized_data = path:GetJsonCompatibleData()
    })
end

if IsTest then
    PathBuilder = PathBuilder()
end

