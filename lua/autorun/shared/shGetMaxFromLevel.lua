function GetMaxFromLevel(level, data)
    
    local num = nil

    while not num do
        num = data[level]
        level = level - 1
    end

    return num

end
