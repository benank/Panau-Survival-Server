local natural_loot_tiers = 
{
    [Lootbox.Types.Level1] = true,
    [Lootbox.Types.Level2] = true,
    [Lootbox.Types.Level3] = true,
    [Lootbox.Types.Level4] = true,
    [Lootbox.Types.Level5] = true,
    [Lootbox.Types.VendingMachineFood] = true,
    [Lootbox.Types.VendingMachineDrink] = true
}

Events:Subscribe("CheckIsTooCloseToLoot", function(args)

    --Thread(function()
        local pos = args.position
        local too_close = false
        local id = IsValid(args.player) and tostring(args.player:GetSteamId()) or args.id

        local cell = GetCell(pos, Lootbox.Cell_Size)

        if LootCells.Loot[cell.x] and LootCells.Loot[cell.x][cell.y] then
            for _, lootbox in pairs(LootCells.Loot[cell.x][cell.y]) do

                if natural_loot_tiers[lootbox.tier] and lootbox.position:Distance(pos) < Lootbox.Safe_Place_Radius then
                    too_close = true
                    break
                end

                --Timer.Sleep(1)
            end
        end

        args.too_close = too_close
        Events:Fire("IsTooCloseToLootCheck"..id, args)

    --end)

end)