-- counts an associative Lua table (use #table for sequential tables) - Dev_34
function count_table(table)
    local count = 0

    for k, v in pairs(table) do
        count = count + 1
    end

    return count
end
