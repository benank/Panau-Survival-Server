
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
