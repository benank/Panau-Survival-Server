-- Serializes all objects in a landclaim into a string
function SerializeObjects(objects)

end

-- Deserializes the string of objects from DB to a table 
function DeserializeObjects(objects)

end


function SerializeAngle(ang)
    return math.round(ang.x, 5) .. "," .. math.round(ang.y, 5) .. "," .. math.round(ang.z, 5) .. "," .. math.round(ang.w, 5)
end

function DeserializeAngle(ang)
    local split = ang:split(",")
    return Angle(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), tonumber(split[4]) or 0)
end

function SerializePosition(pos)
    return string.format("%.5f,%.5f,%.5f", pos.x, pos.y, pos.z)
end

function DeserializePosition(pos)
    local split = pos:split(",")
    return Vector3(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
end