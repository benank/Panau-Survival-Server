class 'Serializer'

function Serializer:__init()
    --local pos = Vector3(1.1234, 2.2345, 3.3456)
    --local serialized_pos = Serializer:SerializeVector3(pos, 2)
    --print("serialized_pos: ", serialized_pos)
    --print("deserialized_pos: ", Serializer:DeserializeVector3(serialized_pos))

    --local ang = Angle(1.1234, 2.2345, 3.3456, 4.456)
    --local serialized_ang = Serializer:SerializeAngle(ang, 3)
    --print("serialized_ang: ", serialized_ang)
    --print("deserialized_ang: ", Serializer:DeserializeAngle(serialized_ang))
end

function Serializer:SerializeVector3(pos, num_decimal_places)
    return "(" .. tostring(math.round(pos.x, num_decimal_places)) .. "," .. tostring(math.round(pos.y, num_decimal_places)) .. "," .. tostring(math.round(pos.z, num_decimal_places)) .. ")"
end

function Serializer:SerializeAngle(ang, num_decimal_places)
    return "(" .. tostring(math.round(ang.x, num_decimal_places)) .. "," .. tostring(math.round(ang.y, num_decimal_places)) .. "," .. tostring(math.round(ang.z, num_decimal_places)) .. "," .. tostring(math.round(ang.z, num_decimal_places)) .. ")"
end

function Serializer:DeserializeVector3(s)
    local deserialized = s:gsub("[()]", "") -- remove parentheses
    pos_tokens = split(deserialized, ",")
    return Vector3(tonumber(pos_tokens[1]), tonumber(pos_tokens[2]), tonumber(pos_tokens[3]))
end

function Serializer:DeserializeAngle(s)
    local deserialized = s:gsub("[()]", "") -- remove parentheses
    ang_tokens = split(deserialized, ",")
    return Angle(tonumber(ang_tokens[1]), tonumber(ang_tokens[2]), tonumber(ang_tokens[3]), tonumber(ang_tokens[4]))
end

Serializer = Serializer()