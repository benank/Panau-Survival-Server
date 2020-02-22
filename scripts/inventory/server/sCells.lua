-- Keep track of all loot in each cell and every player in each cell
LootCells = 
{
    Player = GenerateCellArray(),
    Loot = GenerateCellArray()
}

Events:Subscribe("ClientModuleLoad", function(args)

	args.player:SetValue("LootCell", nil)
	args.player:SetValue("OldLootCell", nil)

end)


Network:Subscribe("Inventory/LootSyncRequest", function(args, player)

    if IsValid(player) and player:GetValue("LootCell") then -- If they are already in a cell, remove them from that one
    
        RemovePlayerFromCell(player);

    end

    if not IsValid(player) then return end -- wat

    player:SetValue("OldLootCell", player:GetValue("LootCell"))

    local new_cell_x, new_cell_y = GetCell(player:GetPosition())

    player:SetValue("LootCell", {x = new_cell_x, y = new_cell_y})

    --debug("[sCells] Player entered new cell: " .. new_cell_x .. " " .. new_cell_y)

    -- Add player to loot cell
    LootCells.Player[new_cell_x][new_cell_y][tostring(player:GetSteamId().id)] = player
    UpdateLootInCells(player);

end)

Events:Subscribe("PlayerQuit", function(args)

    if args.player:GetValue("LootCell") then -- Remove from cell when they leave the server
    
        RemovePlayerFromCell(args.player)

    end

end)

-- Called when a player enters a new cell. Sends player loot data for new adjacent cells.
function UpdateLootInCells(player)

    if not IsValid(player) then return end

    local cell = player:GetValue("LootCell")
    local old_cell = player:GetValue("OldLootCell")

    if not player:GetValue("LootCell") then return end

    --debug('Updating loot in cell for ' .. player:GetName())


    local update_cells = {}

    if not old_cell then -- No old cell, so update all cells adjacent to them
    
        update_cells = GetAdjacentCells(cell.x, cell.y)
    
    else -- Old cell, so only update new adjacent cells
    
        local old_adjacent = GetAdjacentCells(old_cell.x, old_cell.y);
        local new_adjacent = GetAdjacentCells(cell.x, cell.y);

        update_cells = GetAdjacentCells(cell.x, cell.y);

        for i = 1, #old_adjacent do

            for j = 1, #new_adjacent do
        
                if old_adjacent[i].x == new_adjacent[j].x and old_adjacent[i].y == new_adjacent[j].y then

                    update_cells[j] = nil

                end

            end

        end

    end

    -- Sync all lootboxes in cells that need to be updated to the player

    local lootbox_data = {}

    for _, update_cell in pairs(update_cells) do
        for _, lootbox in pairs(LootCells.Loot[update_cell.x][update_cell.y]) do
            table.insert(lootbox_data, lootbox:GetSyncData())
        end
    end
	
	
	-- send the existing lootboxes in the newly streamed cells
    Network:Send(player, "Inventory/LootboxCellsSync", {lootbox_data = lootbox_data})
end

-- return a table indexed 1 - 5 with how many of that tier are in the cell (also includes dropboxes and storages, etc)
function GetLootboxTiersInCell(x, y)
	local tier_data = {}
	
    for _, lootbox in pairs(LootCells.Loot[x][y]) do
        if not tier_data[lootbox.tier] then tier_data[lootbox.tier] = {} end
		tier_data[lootbox.tier] = tier_data[lootbox.tier] + 1
    end
	
	return tier_data
end

function GetLootDataInCell(cell)
    local data = {}

    for _, lootbox in pairs(LootCells.Loot[cell.x][cell.y]) do
        table.insert(data, lootbox:GetSyncData())
    end

    return data
end

-- Removes a player from a cell
function RemovePlayerFromCell(player)
    local cell = player:GetValue("LootCell")

    LootCells.Player[cell.x][cell.y][tostring(player:GetSteamId().id)] = nil
end

