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
    local cell_x, cell_y = GetCell(LocalPlayer:GetPosition(), cell_size)

    -- if our cell is different than our previous cell, update it
    if cell_x ~= self.current_cell.x or cell_y ~= self.current_cell.y then
    
        local old_adjacent = {}
        local new_adjacent = GetAdjacentCells(cell_x, cell_y)

        local updated = GetAdjacentCells(cell_x, cell_y)

        if self.current_cell.x ~= nil and self.current_cell.y ~= nil then

            old_adjacent = GetAdjacentCells(self.current_cell.x, self.current_cell.y)

            -- Filter out old adjacent cells that are still adjacent -- old adjacent only contains old ones that are no longer adjacent
            for i = 1, #old_adjacent do
                for j = 1, #new_adjacent do
            
                    -- If new adjacent also contains a cell from old adjacent, remove it from old adjacent
                    if old_adjacent[i].x == new_adjacent[j].x and old_adjacent[i].y == new_adjacent[j].y then
                        old_adjacent[i] = nil
                        updated[j] = nil
                    end
                    
                end
            end
        end

        -- Fire cell upated event on localplayer
        Events:Fire(LocalPlayerCellUpdateEvent:get() .. tostring(cell_size), {
            old_cell = self.current_cell[cell_size],
            old_adjacent = old_adjacent,
            cell = {x = cell_x, y = cell_y},
            adjacent = new_adjacent,
            updated = updated
        })

        -- Update the current cell we are in
        self.current_cell[cell_size] = {x = cell_x, y = cell_y}

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
    self.ready_for_cell = true
end

cCells = cCells()



