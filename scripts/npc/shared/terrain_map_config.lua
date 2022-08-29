local floor, format = math.floor, string.format

function math.round(n, i)
	local m = 10^(i or 0)
	return floor(n * m + 0.5) / m
end

function printf(...)
	return print(format(...))
end

config = {
	cell_size = 512, -- int, power of 2, min 128, max 4096
	xz_step = 4, -- int, power of 2
	y_min_step = 4, -- int, 1 to 4 recommended
	y_max_step = 1100, -- constant, do not change
	ceiling = 2100, -- constant, do not change
	sea_level = 200, -- constant, do not change
	max_slope = 1, -- 1 = 45 deg (via tangent function)
	map_sea_nodes = false, -- whether to map sea-level nodes
	save_sea_cells = false, -- whether to save cells with no land
	solid_sea = true, -- whether to map at sea level or ocean floor
	eight = true, -- whether to implement 8-direction movement
	path_height = 0.5, -- good compromise for pathing
 	graph_color1 = Color.Lime, -- color to use to render graph data
 	graph_color2 = Color.Yellow, -- color to use to render graph data
	path_color = Color.Magenta, -- color to use to render path data
	visited_color = Color.Cyan, -- color to use to render visited nodes
}

-- conditions must be met for proper serialization
local err = 'check configuration'
assert(config.cell_size / config.xz_step <= 256, err)
assert(math.log(config.cell_size, 2) % 1 == 0, err)
assert(math.log(config.xz_step, 2) % 1 == 0, err)
