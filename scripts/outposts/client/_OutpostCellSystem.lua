-- returns cell x, y
function GetCell(x, z)
	return math.floor((x + 16384) / outpost_cell_size), math.floor((z + 16384) / outpost_cell_size)
end