
NetworkSend = Network.Send
function Network:Send(player, string, object) if not v(player) then return end NetworkSend(self, player, string, object) end


class 'fakesql'

function fakesql:__init()

end

function fakesql:Bind()
end

function fakesql:Execute()
    return {}
end

SQLCommand = SQL.Command
function SQL:Command(string) return fakesql() end

SQLQuery = SQL.Query
function SQL:Query(string) return fakesql() end