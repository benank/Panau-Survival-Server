
local players_with_parachutes = {}

Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Parachute" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    Network:Send(args.player, "items/ToggleEquippedParachute", {equipped = args.item.equipped == true})
    UpdateEquippedItem(args.player, args.item.name, args.item)

    if args.item.equipped then
        args.player:SetValue("ParachutingValue", 0)
        table.insert(players_with_parachutes, args.player)
    else
        for k,v in pairs(players_with_parachutes) do
            if v:GetId() == args.player:GetId() then
                table.remove(players_with_parachutes, k)
                break
            end
        end
    end

end)


local func = coroutine.wrap(function()

    while true do

        for k,v in pairs(players_with_parachutes) do
            if IsValid(v) then
                if v:GetParachuting() then
                    v:SetValue("ParachutingValue", v:GetValue("ParachutingValue") + ItemsConfig.equippables["Parachute"].dura_per_sec)
                end
            else
                players_with_parachutes[k] = nil
            end
        end

        Timer.Sleep(1000)

    end
end)()


local func2 = coroutine.wrap(function()

    while true do

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
