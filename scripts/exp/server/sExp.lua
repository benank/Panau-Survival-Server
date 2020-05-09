class 'sExp'

function sExp:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS exp (steamID VARCHAR(20), level INTEGER, exp REAL)")


end

sExp = sExp()