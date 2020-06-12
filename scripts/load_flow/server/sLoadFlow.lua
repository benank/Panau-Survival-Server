class 'sLoadFlow'

function sLoadFlow:__init()

    self.loads = {}
    self.load_needed = 4 -- Exp, items, inventory, vehicles

    Events:Subscribe("LoadFlowAdd", self, self.LoadFlowAdd)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)

    Events:Subscribe("ModulesLoad", function()
        Timer.SetTimeout(1000, function()
            for p in Server:GetPlayers() do
                if IsValid(p) then
                    Events:Fire("LoadFlowFinish", {player = p})
                end
            end
        end)
    end)

end

function sLoadFlow:PlayerQuit(args)
    local steam_id = tostring(args.player:GetSteamId())

    self.loads[steam_id] = nil
end

function sLoadFlow:LoadFlowAdd(args)
    if not IsValid(args.player) then return end
    local steam_id = tostring(args.player:GetSteamId())

    if not self.loads[steam_id] then
        self.loads[steam_id] = {player = args.player, counts = {}}
    end

    self.loads[steam_id].counts[args.source] = true

    local total_count = 0
    for source, done in pairs(self.loads[steam_id].counts) do
        if done then total_count = total_count + 1 end
    end

    if total_count == self.load_needed then
        Events:Fire("LoadFlowFinish", {player = args.player})
        self.loads[steam_id] = nil
    end
end

sLoadFlow = sLoadFlow()