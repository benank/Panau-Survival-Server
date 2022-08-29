class "PathEngineManager"

function PathEngineManager:__init()
    self.pathservers = {}

    self:DeclarePathServers()

    if IsTest then
        self.debug_callers = {}
        self.path_request_counter = 0
        Events:Subscribe("PlayerChat", self, self.PlayerChatDebug)
    end
end

function PathEngineManager:DeclarePathServers()
    --self:CreatePathServer('127.0.0.1', 7780)
    -- TODO: add slight delays here so we dont make all the handshake requests at once
    self:CreatePathServer({
        ip = '51.161.9.77',
        port = 7780,
        aggregation_delay = 500
    })
end

function PathEngineManager:CreatePathServer(data)
    local pathserver = PathServer()
    pathserver:SetAggregationDelay(data.aggregation_delay)
    pathserver:connect(tostring(data.ip), tonumber(data.port))

    table.insert(self.pathservers, pathserver)
    print("Created pathserver for " .. tostring(data.ip) .. ": " .. tostring(data.port))
end

function PathEngineManager:GetFootPath(start, stop, callback, callback_instance)
    -- TODO: pathserver selection logic
    -- do any pathservers currently have requests queued?
    -- which pathserver has the smallest time until next send?
    -- does a pathserver have too many requests to handle already in one send?
    self.path_request_counter = self.path_request_counter + 1
    local pathserver = self.pathservers[1]
    pathserver:GetFootPath(start, stop, callback, callback_instance)
end

function PathEngineManager:GetRoamPath(start, callback, callback_instance)
    self.path_request_counter = self.path_request_counter + 1
    local pathserver = self.pathservers[1]
    pathserver:GetRoamPath(start, callback, callback_instance)
end

function PathEngineManager:PlayerChatDebug(args)
    if args.text == "/pathtest" then
		local start = args.player:GetPosition()
        local stop =  args.player:GetPosition() + (Angle(args.player:GetAngle().yaw, 0, 0) * (Vector3.Forward * 34))
        
        local test_caller = TestCaller()
        table.insert(self.debug_callers, test_caller)
        self:GetFootPath(start, stop, test_caller.PathCallback, test_caller)
    end
    
    if args.text == "/roamtest" then
        local start = args.player:GetPosition()

        local test_caller = TestCaller()
        table.insert(self.debug_callers, test_caller)
        self:GetRoamPath(start, test_caller.PathCallback, test_caller)
    end
end

PathEngineManager = PathEngineManager()


class "TestCaller"

function TestCaller:__init()

end

function TestCaller:PathCallback(data)
    print("Entered PathCallback with data:")
    if data then
        output_table(data)
    else
        print("nil")
    end
end