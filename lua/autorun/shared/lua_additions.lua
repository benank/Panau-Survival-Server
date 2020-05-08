-- counts an associative Lua table (use #table for sequential tables) - Dev_34
function count_table(table)
    local count = 0

    for k, v in pairs(table) do
        count = count + 1
    end

    return count
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function math.round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function output_table(t)
    print("-----", t, "-----")
    for key, value in pairs(t) do
        print("[", key, "]: ", value)
    end
    print("------------------------")
end

-- Dev_34
function random_table_value(t)
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    return t[keys[math.random(#keys)]]
end

function table.compare(tbl1, tbl2)
	for k, v in pairs(tbl1) do
		if tbl2[k] ~= v then
			return false
		end
	end

	for k, v in pairs(tbl2) do
		if tbl1[k] ~= v then
			return false
		end
	end

	return true
end