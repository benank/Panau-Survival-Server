function UpdateCell(old_cell, current_cell)

    -- Get our current cell
    local cell = current_cell
    local current_cell = old_cell

    -- if our cell is different than our previous cell, update it
    if cell.x ~= current_cell.x or cell.y ~= current_cell.y or cell.z ~= current_cell.z then
    
        local old_adjacent = {}
        local new_adjacent = GetAdjacentCells(cell)

        local updated = GetAdjacentCells(cell)

        if current_cell.x ~= nil and current_cell.y ~= nil and current_cell.z ~= nil then

            old_adjacent = GetAdjacentCells(current_cell)

            -- Filter out old adjacent cells that are still adjacent -- old adjacent only contains old ones that are no longer adjacent
            for i, _ in pairs(old_adjacent) do
                for j, _ in pairs(new_adjacent) do
            
                    -- If new adjacent also contains a cell from old adjacent, remove it from old adjacent
                    if old_adjacent[i] and new_adjacent[j]
                    and old_adjacent[i].x == new_adjacent[j].x 
                    and old_adjacent[i].y == new_adjacent[j].y
                    and old_adjacent[i].z == new_adjacent[j].z then
                        old_adjacent[i] = nil
                        updated[j] = nil
                    end
                    
                end
            end
        end

        return {
            old_cell = current_cell,
            old_adjacent = old_adjacent,
            cell = cell,
            adjacent = new_adjacent,
            updated = updated
        }

    end
end