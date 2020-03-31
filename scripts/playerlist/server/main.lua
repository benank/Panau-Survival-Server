class 'ListHandler'

function ListHandler:__init()
	self.PingList = {}
	self.LastTick = 0

	Network:Subscribe("SendPingList", self, self.SendPingList)

	Events:Subscribe("PostTick", self, self.PostTick)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
end

function ListHandler:PlayerQuit(args)
	self.PingList[tostring(args.player:GetId())] = nil
end

function ListHandler:SendPingList(player)
	Network:Send(player, "UpdatePings", self.PingList)
end

function ListHandler:PostTick(args)
	if Server:GetElapsedSeconds() - self.LastTick >= 4 then
		for player in Server:GetPlayers() do
			self.PingList[tostring(player:GetSteamId())] = player:GetPing()
		end

		self.LastTick = Server:GetElapsedSeconds()
	end
end

handler = ListHandler()