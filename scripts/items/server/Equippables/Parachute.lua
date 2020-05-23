
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
    for id, player in pairs(players_with_parachutes) do
        log_function_call("players_with_parachutes coroutine2 ")
        if IsValid(player) then
            log_function_call("players_with_parachutes coroutine 3")
            if player:GetParachuting() then
                log_function_call("players_with_parachutes coroutine 4")
                player:SetValue("ParachutingValue", player:GetValue("ParachutingValue") + ItemsConfig.equippables["Parachute"].dura_per_sec)
            end
        else
            log_function_call("players_with_parachutes coroutine 5")
            players_with_parachutes[id] = nil
        end
    end
    log_function_call("players_with_parachutes coroutine6 ")
end)

local func2 = coroutine.wrap(function()

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

        Timer.Sleep(3000)

    end

end)()
