Events:Subscribe("CheckIsTooCloseToLoot", function(args)

    local func = coroutine.wrap(function()
        local pos = args.position
        local too_close = false
        local id = IsValid(args.player) and tostring(args.player:GetSteamId()) or args.id

        local cell = GetCell(pos, Lootbox.Cell_Size)

        if LootCells.Loot[cell.x] and LootCells.Loot[cell.x][cell.y] then
            for _, lootbox in pairs(LootCells.Loot[cell.x][cell.y]) do

                if lootbox.position:Distance(pos) < Lootbox.Safe_Place_Radius then
                    too_close = true
                    break
                end

                Timer.Sleep(1)
            end
        end

        args.too_close = too_close
        Events:Fire("IsTooCloseToLootCheck"..id, args)

    end)()

end)