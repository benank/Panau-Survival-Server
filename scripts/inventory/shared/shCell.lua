function GetCell(pos)
    return math.ceil((pos.x + 16384) / Lootbox.Cell_Size), math.ceil((pos.z + 16384) / Lootbox.Cell_Size)
end

-- Returns a table containing objects with x and y of cells that are adjacent to the one given including the one given
function GetAdjacentCells(cell_x, cell_y) -- X and Y of a cell

    local adjacent = {}

	for x = cell_x - 2, cell_x do

        for y = cell_y - 2, cell_y do

            table.insert(adjacent, {x = x, y = y})

        end

    end

    return adjacent;
end

-- Generates a two dimensional array so that all the loot can be stored in cells
function GenerateCellArray()

    local cells = {}

    for x = 1, math.ceil(32800 / Lootbox.Cell_Size) do
    
        cells[x] = {};
        for y = 1, math.ceil(32800 / Lootbox.Cell_Size) do
        
            cells[x][y] = {}
        end
    end

    return cells
end
