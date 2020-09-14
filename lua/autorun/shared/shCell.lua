function GetCell(pos, cell_size)
    return {x = math.floor(pos.x / cell_size), y = math.floor(pos.z / cell_size)}
end

function VerifyCellExists(cell_table, cell)
    if not cell_table[cell.x] then cell_table[cell.x] = {} end
    if not cell_table[cell.x][cell.y] then cell_table[cell.x][cell.y] = {} end
end

-- Returns a table containing objects with x and y of cells that are adjacent to the one given including the one given
function GetAdjacentCells(cell)

    local adjacent = {}

	for x = cell.x - 1, cell.x + 1 do

        for y = cell.y - 1, cell.y + 1 do

            table.insert(adjacent, {x = x, y = y})

        end

    end

    return adjacent
end

CELL_SIZES = {256, 512, 1024, 2048, 4096}