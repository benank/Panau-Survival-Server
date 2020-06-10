Events:Subscribe("GetNearbyLoot", function(args)
    -- Gets nearby loot to a position

    local cell = GetCell(args.position, Lootbox.Cell_Size)
    local adjacent_cells = GetAdjacentCells(cell)

    local nearby_loot = {}

    for index, adj_cell in pairs(adjacent_cells) do

        VerifyCellExists(LootCells.Loot, adj_cell)

        for uid, lootbox in pairs(LootCells.Loot[adj_cell.x][adj_cell.y]) do

            if lootbox.active and not lootbox.in_sz then
                nearby_loot[uid] = {
                    position = lootbox.position,
                    tier = lootbox.tier
                }
            end

        end

    end

    Events:Fire("GetNearbyLoot" .. tostring(args.position), nearby_loot)
end)