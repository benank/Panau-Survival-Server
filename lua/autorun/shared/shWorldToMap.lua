function WorldToMap(pos)
    return Vector2(pos.x + 16384, pos.z + 16384)
end

function WorldToMapString(pos)
    local w2m = WorldToMap(pos)
    return string.format("@ X: %.0f Y: %.0f", w2m.x, w2m.y)
end