

local current_cell_x = -1
local current_cell_y = -1
local ready_for_cell = false;

Events:Subscribe("ModulesLoad", function(args)

    ready_for_cell = true

end)

Timer.SetInterval(Lootbox.Scan_Interval, function()

    if not ready_for_cell then return end

    local cell_x, cell_y = GetCell(LocalPlayer:GetPosition())

    if cell_x ~= current_cell_x or cell_y ~= current_cell_y then
    
        local old_adjacent = GetAdjacentCells(current_cell_x, current_cell_y)
        local new_adjacent = GetAdjacentCells(current_cell_x, current_cell_y)

        local update_cells = GetAdjacentCells(current_cell_x, current_cell_y);

        if current_cell_x > -1 and current_cell_y > -1 then

            for i = 1, #old_adjacent do

                for j = 1, #new_adjacent do
            
                    if old_adjacent[i].x == new_adjacent[j].x and old_adjacent[i].y == new_adjacent[j].y then

                        update_cells[i] = nil

                    end
					
                end

            end

        end

        for _, cell in pairs(update_cells) do
            LootManager:ClearCell(cell)
        end

        current_cell_x = cell_x; current_cell_y = cell_y;
        Network:Send("Inventory/LootSyncRequest")

    end

end)