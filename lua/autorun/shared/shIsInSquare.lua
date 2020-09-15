-- Returns true if pos2 resides within a square with center pos and specified side length
function IsInSquare(pos, side_length, pos2)
    local side_length_half = side_length / 2
    return pos2.x > pos.x - side_length_half and pos2.x < pos.x + side_length_half
    and pos2.z > pos.z - side_length_half and pos2.z < pos.z + side_length_half
end