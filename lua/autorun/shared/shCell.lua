function GetCell(pos, cell_size)
    return math.floor((pos.x + 16384) / cell_size), math.floor((pos.z + 16384) / cell_size)
end

function VerifyCellExists(cell_table, cell)
    if not cell_table[cell.x] then cell_table[cell.x] = {} end
    if not cell_table[cell.x][cell.y] then cell_table[cell.x][cell.y] = {} end
end

-- Returns a table containing objects with x and y of cells that are adjacent to the one given including the one given
function GetAdjacentCells(cell_x, cell_y) -- X and Y of a cell

    local adjacent = {}

	for x = cell_x - 1, cell_x + 1 do

        for y = cell_y - 1, cell_y + 1 do

            table.insert(adjacent, {x = x, y = y})

        end

    end

    return adjacent
end

CELL_SIZES = {256, 512, 1024}