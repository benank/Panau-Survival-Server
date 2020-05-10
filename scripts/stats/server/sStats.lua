class 'sStats'

function sStats:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS server_stats ()")

end

sStats = sStats()