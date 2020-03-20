class 'cCells'

local CellSyncRequestEvent = var("Cells/NewCellSyncRequest")
local LocalPlayerCellUpdateEvent = var("Cells/LocalPlayerCellUpdate")

function cCells:__init()

    self.current_cell = {}
    self.ready_for_cell = false
    self.CELL_SCAN_INTERVAL = 2000
    self.scan_timer = Timer()

    for _, cell_size in pairs(CELL_SIZES) do
        self.current_cell[cell_size] = {}
    end

    Events:Subscribe(var("Render"):get(), self, self.Render)
    Events:Subscribe(var("ModulesLoad"):get(), self, self.ModulesLoad)

    
    --[[
    To subscribe to cell events, use this:

    Cells/LocalPlayerCellUpdate .. CELL_SIZE

        (CELL_SIZE is a valid number from CELL_SIZES in shCell.lua)

        old_cell: (table of x,y) cell that the player left
        old_adjacent: (table of tables of (x,y)) old adjacent cells that are no longer adjacent to the player
        cell: (table of x,y) cell that the player is now in
        adjacent: (table of tables of (x,y)) cells that are currently adjacent to the player

    Cells use a lazy loading strategy and only load the cells that have been accessed by a player.

    ]]
end

function cCells:CheckIfPlayerInNewCell(cell_size)

    -- Get our current cell
    local cell = GetCell(LocalPlayer:GetPosition(), cell_size)
    local current_cell = self.current_cell[cell_size]

    -- if our cell is different than our previous cell, update it
    if cell.x ~= current_cell.x or cell.y ~= current_cell.y then
    
        local old_adjacent = {}
        local new_adjacent = GetAdjacentCells(cell)

        local updated = GetAdjacentCells(cell)

        if current_cell.x ~= nil and current_cell.y ~= nil then

            old_adjacent = GetAdjacentCells(current_cell)

            -- Filter out old adjacent cells that are still adjacent -- old adjacent only contains old ones that are no longer adjacent
            for old_index, old_adjacent_cell in pairs(old_adjacent) do
                for new_index, new_adjacent_cell in pairs(updated) do
            
                    -- If new adjacent also contains a cell from old adjacent, remove it from old adjacent
                    if old_adjacent_cell.x == new_adjacent_cell.x and old_adjacent_cell.y == new_adjacent_cell.y then
                        old_adjacent[old_index] = nil
                        updated[new_index] = nil
                    end
                    
                end
            end
        end

        -- Fire cell upated event on localplayer
        Events:Fire(LocalPlayerCellUpdateEvent:get() .. tostring(cell_size), {
            old_cell = current_cell,
            old_adjacent = old_adjacent,
            cell = cell,
            adjacent = new_adjacent,
            updated = updated
        })

        -- Update the current cell we are in
        self.current_cell[cell_size] = cell

        return true
    end

end

function cCells:CheckCells()

    local entered_new_cell = false
    
    -- Check if we entered a new cell, if so tell the server
    for _, cell_size in pairs(CELL_SIZES) do
        entered_new_cell = self:CheckIfPlayerInNewCell(cell_size) or cell_check
    end

    -- If we entered at least one new cell, tell the server to update us
    if entered_new_cell then
        Network:Send(CellSyncRequestEvent:get())
    end

end

function cCells:Render(args)
    
    -- If we are not ready to start checking for cells
    if not self.ready_for_cell then return end

    if self.scan_timer:GetMilliseconds() > self.CELL_SCAN_INTERVAL then
        self.scan_timer:Restart()

        -- Check all cell sizes
        self:CheckCells()
    end

end

function cCells:ModulesLoad()
    
    for _, cell_size in pairs(CELL_SIZES) do
        self.current_cell[cell_size] = {}
    end

    self.ready_for_cell = true
end

cCells = cCells()



