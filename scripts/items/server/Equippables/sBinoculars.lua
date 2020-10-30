local players_using_binos = {}

Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Binoculars" then return end

    local binoculars_data = ItemsConfig.equippables[args.item.name]

    if not binoculars_data then return end

    UpdateEquippedItem(args.player, args.item.name, args.item)

    Network:Send(args.player, "items/ToggleBinocularsEquipped", {equipped = args.item.equipped == true})

    if not args.item.equipped then
        players_using_binos[tostring(args.player:GetSteamId())] = nil
    end

end)

Network:Subscribe("items/ToggleUsingBinoculars", function(args, player)

    local steam_id = tostring(player:GetSteamId())
    args.player = player
    args.item = GetEquippedItem("Binoculars", player)

    if args.using then
        players_using_binos[steam_id] = args
    else
        players_using_binos[steam_id] = nil
    end

end)

-- Player died, stop using binos
Events:Subscribe("PlayerDeath", function(args)
    Network:Send(args.player, "items/ToggleUsingBinoculars", {using = false})
    players_using_binos[tostring(args.player:GetSteamId())] = nil
end)

Timer.SetInterval(2000, function()
    for steam_id, args in pairs(players_using_binos) do
        if not IsValid(args.player) then
            players_using_binos[steam_id] = nil
        else
            
            args.item.durability = args.item.durability - ItemsConfig.equippables[args.item.name].dura_per_sec
            Inventory.ModifyDurability({
                player = args.player,
                item = args.item
            })
            UpdateEquippedItem(player, "Binoculars", args.item)

        end

    end
end)