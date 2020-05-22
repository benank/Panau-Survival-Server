class 'sLoadFlow'

function sLoadFlow:__init()

    self.loads = {}
    self.load_needed = 4 -- Exp, items, inventory, vehicles

    Events:Subscribe("LoadFlowAdd", self, self.LoadFlowAdd)

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

function sLoadFlow:LoadFlowAdd(args)
    if not IsValid(args.player) then return end
    local steam_id = tostring(args.player:GetSteamId())

    if not self.loads[steam_id] then
        self.loads[steam_id] = {player = args.player, count = 1}
    else
        self.loads[steam_id].count = self.loads[steam_id].count + 1
    end

    if self.loads[steam_id].count == self.load_needed then
        Events:Fire("LoadFlowFinish", {player = args.player})
        self.loads[steam_id] = nil
    end
end

sLoadFlow = sLoadFlow()