local players_using_binos = {}

Events:Subscribe("Inventory/UseItem", function(args)

    if args.item.name ~= "Binoculars" then return end

    local binoculars_data = ItemsConfig.usables[args.item.name]

    if not binoculars_data then return end

    local steam_id = tostring(args.player:GetSteamId())

    if players_using_binos[steam_id] then
        players_using_binos[steam_id] = nil
    else
        players_using_binos[steam_id] = args
    end

    Network:Send(args.player, "items/ToggleUsingBinoculars", {using = players_using_binos[steam_id] ~= nil})

end)

-- Player died, stop using binos
Events:Subscribe("PlayerDeath", function(args)
    Network:Send(args.player, "items/ToggleUsingBinoculars", {using = false})
end)

Timer.SetInterval(2000, function()
    for steam_id, args in pairs(players_using_binos) do
        if not IsValid(args.player) then
            players_using_binos[steam_id] = nil
        else
            
            args.item.durability = args.item.durability - ItemsConfig.usables[args.item.name].dura_per_sec
            Inventory.ModifyDurability({
                player = args.player,
                item = args.item
            })

            -- Item broke
            if args.item.durability <= 0 then
                Network:Send(args.player, "items/ToggleUsingBinoculars", {using = false})
                players_using_binos[steam_id] = nil
            end

        end

    end
end)