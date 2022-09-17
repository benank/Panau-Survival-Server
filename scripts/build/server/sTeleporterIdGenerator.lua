local function RandomString(length)
    local res = ""
    for i = 1, length do
        res = res .. string.char(math.random(65, 90))
    end
    return res
end


function GenerateNewTeleporterId()
    math.randomseed(os.clock() ^ 5)
    local tp_id = RandomString(5)

    -- check to make sure it doesn't exist already
    if sLandclaimManager.teleporters[tp_id] == nil then
        return tp_id
    else
        return GenerateNewTeleporterId()
    end
end