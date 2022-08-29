class "BaseBuilder"

function BaseBuilder:__init()
    Events:Subscribe("PlayerChat", self, self.PlayerChat)
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)

    Network:Subscribe("npc/AddSpawnPoint", self, self.AddSpawnPoint)
end

function BaseBuilder:ModuleLoad(args)
    Thread(function() 
        Timer.Sleep(3000)
        self:LoadDebugBase("base1")
    end)
end

function BaseBuilder:PlayerChat(args)
    if args.text:find("/createbase") then -- /createbase basename, also saves the base
        self:CreateBase(args)
        return false
    end
    if args.text:find("/savebase") then -- /savebase basename
        self:SaveBase(args)
        return false
    end
    if args.text:find("/setbasepos") then-- /setbasepos basename , also saves the base
        self:SetBasePosition(args)
        return false
    end
    if args.text:find("/setbaseradius") then -- /setbaseradius basename radius, also saves the base
        self:SetBaseRadius(args)
        return false
    end
    if args.text:find("/deletesp") then -- /deletesp base_name spawn_point_name
        self:DeleteSpawnPointFromBase(args)
        return false
    end
end

function BaseBuilder:LoadDebugBase(name)
    Bases:LoadBase(name)
    self:SyncDebugBase(Bases:GetBaseByName(name))
end

function BaseBuilder:SyncDebugBase(base)
    Network:Broadcast("npc/SyncDebugBase", {
        name = base:GetName(),
        serialized_data = base:GetJsonCompatibleData()
    })
end

function BaseBuilder:CreateBase(args)
    local chat_tokens = split(args.text, " ")
    local name = chat_tokens[2]

    if not name then
        args.player:SendChatMessage("Specify a Base name!", Color.Red)
        return
    end
    
    Bases:Create(name)
    local base = Bases:GetBaseByName(name)
    base:SetPosition(args.player:GetPosition())

    BaseSerialization:SaveBase(base)

    self:SyncDebugBase(base)
end

function BaseBuilder:SetBasePosition(args)
    local chat_tokens = split(args.text, " ")
    local name = chat_tokens[2]

    if not name then
        args.player:SendChatMessage("Specify a Base name!", Color.Red)
        return
    end
    
    local base = Bases:GetBaseByName(name)
    base:SetPosition(args.player:GetPosition())

    BaseSerialization:SaveBase(base)

    self:SyncDebugBase(base)
end

function BaseBuilder:SetBaseRadius(args)
    local chat_tokens = split(args.text, " ")
    local name = chat_tokens[2]
    local radius = chat_tokens[3]

    if not name then
        args.player:SendChatMessage("Specify a Base name!", Color.Red)
        return
    end

    if not radius then
        args.player:SendChatMessage("Specify a radius!", Color.Red)
        return
    end

    local base = Bases:GetBaseByName(name)
    if not base then
        args.player:SendChatMessage("Could not find Base!", Color.Red)
        return
    end
    
    base:SetRadius(tonumber(radius))

    BaseSerialization:SaveBase(base)

    self:SyncDebugBase(base)
end

function BaseBuilder:SaveBase(args)
    local chat_tokens = split(args.text, " ")
    local name = chat_tokens[2]
    if not name then
        args.player:SendChatMessage("Specify a Base name!", Color.Red)
        return
    end
    
    local base = Bases:GetBaseByName(name)
    if not base then
        args.player:SendChatMessage("Could not find base when trying to save!", Color.Red)
        return
    end

    BaseSerialization:SaveBase(base)

    self:SyncDebugBase(base)
end

function BaseBuilder:AddSpawnPoint(args)
    local spawn_point = SpawnPoint()
    spawn_point:InitializeFromJsonData(args.spawn_point_data)

    -- if we get a path name, we need to store the loaded path on the SpawnPoint instance
    if args.path_name then
        local path = PathSerialization:GetFullyLoadedPathFromFile(args.path_name)
        spawn_point:SetPath(path)
    end

    local base_data = BaseSerialization:GetBaseDataFromFile(spawn_point:GetBaseName())
    local base = Base()

    base:InitializeFromJsonData(base_data)
    base:AddSpawnPoint(spawn_point)

    BaseSerialization:SaveBase(base)

    self:SyncDebugBase(base)
end

function BaseBuilder:DeleteSpawnPointFromBase(args)
    local chat_tokens = split(args.text, " ")
    local base_name = chat_tokens[2]
    local spawn_point_name = chat_tokens[3]
    if not base_name then
        args.player:SendChatMessage("Specify a Base name!", Color.Red)
        return
    end

    if not spawn_point_name then
        args.player:SendChatMessage("Specify a spawn point name!", Color.Red)
        return
    end
    
    local base = BaseSerialization:GetFullyLoadedBaseFromFile(base_name)
    if not base then
        args.player:SendChatMessage("Could not find base when trying to delete spawn point!", Color.Red)
        return
    end

    local base = BaseSerialization:GetFullyLoadedBaseFromFile(base_name)
    base:RemoveSpawnPoint(spawn_point_name)
    
    BaseSerialization:SaveBase(base)

    self:SyncDebugBase(base)
end 

if IsTest then
    BaseBuilder = BaseBuilder()
end