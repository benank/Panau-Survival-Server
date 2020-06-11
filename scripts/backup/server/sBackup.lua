Timer.SetInterval(1000 * 60 * 60 * 6, function()
    print("Creating backup...")
    os.execute(string.format('sqlite3 server.db -cmd ".backup ./db_backups/%s.db" ".exit"', GetLogDate()))
    print("Backup created!")
end)

function GetLogDate()

    local timeTable = os.date("*t", os.time())
    
    return string.format("%s-%s-%s-%s-%s-%s",
        timeTable.year, timeTable.month, timeTable.day, timeTable.hour, timeTable.min, timeTable.sec)
        
end