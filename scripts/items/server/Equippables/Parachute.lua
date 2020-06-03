
local players_with_parachutes = {}

Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Parachute" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    Network:Send(args.player, "items/ToggleEquippedParachute", {equipped = args.item.equipped == true})
    UpdateEquippedItem(args.player, args.item.name, args.item)

    if args.item.equipped then
        args.player:SetValue("ParachutingValue", 0)
        players_with_parachutes[args.player:GetId()] = args.player
    else
        players_with_parachutes[args.player:GetId()] = nil
    end

end)

Events:Subscribe("SecondTick", function()
    log_function_call("players_with_parachutes coroutine")
    for player in Server:GetPlayers() do
        if IsValid(player) and players_with_parachutes[player:GetId()] then
            if player:GetValue("ParachutingValue") and player:GetParachuting() then
                player:SetValue("ParachutingValue", player:GetValue("ParachutingValue") + ItemsConfig.equippables["Parachute"].dura_per_sec)
            end
        elseif IsValid(player) then
            players_with_parachutes[player:GetId()] = nil
        end
    end
    log_function_call("players_with_parachutes coroutine 2")
end)

Thread(function()

    while true do
        log_function_call("Server:GetPlayers() ParachutingValue")
        for player in Server:GetPlayers() do

            if IsValid(player) then
                local parachuting_value = player:GetValue("ParachutingValue")

                if parachuting_value and parachuting_value > 0 then
                    local item = GetEquippedItem("Parachute", player)
                    if not item then return end
                    item.durability = item.durability - parachuting_value
                    Inventory.ModifyDurability({
                        player = player,
                        item = item
                    })
                    UpdateEquippedItem(player, "Parachute", item)
                    player:SetValue("ParachutingValue", 0)

                end
            end

            Timer.Sleep(5)
        end
        log_function_call("Server:GetPlayers() ParachutingValue 2")

        Timer.Sleep(3000)

    end

end)
