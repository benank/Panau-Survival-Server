function GetCenterOfCell(cell_x, cell_y)
	local size = Lootbox.Cell_Size
	local x = cell_x * size + 0.5 * size - 16384
	local z = cell_y * size + 0.5 * size - 16384
	local pos = Vector3(x, 0, z)
	pos.y = math.max(Physics:GetTerrainHeight(pos), 200)
	return pos
end

function GetCellCorners(cell_x, cell_y)
	local step = 4 -- ??? config.xz_step
	local size = Lootbox.Cell_Size
	local x_start = size * cell_x - 16384
	local x_stop = x_start + size - step
	local z_start = size * cell_y - 16384
	local z_stop = z_start + size - step
	
	return x_start, x_stop, z_start, z_stop
end

function RadialGetAdjacentCell()

end