class 'ListHandler'

function ListHandler:__init()
	self.PingList = {}
    self.LastTick = 0
    
    Timer.SetInterval(4000, function()
        for player in Server:GetPlayers() do
            self.PingList[tostring(player:GetSteamId())] = {
                ping = player:GetPing(), 
                level = player:GetValue("Exp") and player:GetValue("Exp").level or "..."
            }
        end
    end)

	Network:Subscribe("SendPingList", self, self.SendPingList)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
end

function ListHandler:PlayerQuit(args)
	self.PingList[tostring(args.player:GetId())] = nil
end

function ListHandler:SendPingList(player)
	Network:Send(player, "UpdatePings", self.PingList)
end

handler = ListHandler()