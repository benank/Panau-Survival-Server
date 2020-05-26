local v = function(p) return IsValid(p) end

NetworkSend = Network.Send
function Network:Send(player, string, object) if not v(player) then return end NetworkSend(self, player, string, object) end