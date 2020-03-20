class 'sCells'

function sCells:__init()

    self.cells = {}

    self:InitializeCells()

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)

    Network:Subscribe("Cells/NewCellSyncRequest", self, self.CellSyncRequest)

    --[[
    To subscribe to cell events, use this:

    Cells/PlayerCellUpdate .. CELL_SIZE

        (CELL_SIZE is a valid number from CELL_SIZES in shCell.lua)

        player: the player whose cell just updated
        old_cell: (table of x,y) cell that the player left
        old_adjacent: (table of tables of (x,y)) old adjacent cells that are no longer adjacent to the player (includes old cell)
        cell: (table of x,y) cell that the player is now in
        adjacent: (table of tables of (x,y)) cells that are currently adjacent to the player (includes current cell)

    Cells use a lazy loading strategy and only load the cells that have been accessed by a player.

    ]]
end

function sCells:ModulesLoad()
    for p in Server:GetPlayers() do
        self:ResetPlayerCellValue(p)
    end
end

function sCells:ClientModuleLoad(args)
    self:ResetPlayerCellValue(args.player)
end

function sCells:ResetPlayerCellValue(player)

    local cell = {}
    for _, cell_size in pairs(CELL_SIZES) do
        cell[cell_size] = {x = nil, y = nil}
    end

	player:SetValue("Cell", cell)

end

function sCells:InitializeCells()

    for _, cell_size in pairs(CELL_SIZES) do
        self.cells[cell_size] = {}
    end

end

function sCells:CellSyncRequest(args, player)

    if not IsValid(player) then return end
    
    for _, cell_size in pairs(CELL_SIZES) do
        self:UpdatePlayerCell(player, cell_size)
    end

end

function sCells:UpdatePlayerCell(player, cell_size)
    
    if not IsValid(player) then return end

    local old_cell = player:GetValue("Cell")[cell_size]
    local new_cell = GetCell(player:GetPosition(), cell_size)

    -- Check if they entered a new cell
    if new_cell.x ~= old_cell.x or new_cell.y ~= old_cell.y or force then

        local old_adjacent = {}
        local new_adjacent = GetAdjacentCells(new_cell)

        -- Adjacent cells that are new
        local updated = GetAdjacentCells(new_cell)

        -- If this wasn't the first sync, then the old cell will be valid
        if old_cell.x ~= nil and old_cell.y ~= nil then
            old_adjacent = GetAdjacentCells(old_cell)

            for i = 1, #old_adjacent do
                for j = 1, #new_adjacent do
                    if old_adjacent[i] and new_adjacent[j] 
                    and old_adjacent[i].x == new_adjacent[j].x and old_adjacent[i].y == new_adjacent[j].y then
                        old_adjacent[j] = nil
                        updated[j] = nil
                    end
                end
            end
        end

        debug(string.format("%s entered cell %s, %s [%s]", player:GetName(), tostring(new_cell.x), tostring(new_cell.y), tostring(cell_size)))
    
        Events:Fire("Cells/PlayerCellUpdate" .. tostring(cell_size), {
            player = player,
            old_cell = old_cell,
            old_adjacent = old_adjacent,
            cell = new_cell,
            adjacent = new_adjacent,
            updated = updated
        })

        local player_cell_total = player:GetValue("Cell")
        player_cell_total[cell_size] = new_cell
        player:SetValue("Cell", player_cell_total)
        
    end

end

sCells = sCells()