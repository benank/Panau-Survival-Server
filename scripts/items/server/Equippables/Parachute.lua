
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
    for player in Server:GetPlayers() do
        if IsValid(player) and players_with_parachutes[player:GetId()] then
            if player:GetValue("ParachutingValue") and player:GetParachuting() then
                player:SetValue("ParachutingValue", player:GetValue("ParachutingValue") + ItemsConfig.equippables["Parachute"].dura_per_sec)
            end
        elseif IsValid(player) then
            players_with_parachutes[player:GetId()] = nil
        end
    end
end)

local parachute_perks =
{
    [43] = 1 - (0.10 / 2), -- 10%
    [89] = 1 - (0.25 / 2), -- 25%
    [130] = 1 - (0.50 / 2), -- 50%
    [156] = 1 - (0.75 / 2), -- 75%
    [175] = 1 - (1.00 / 2) -- 100% extra
}

Timer.SetInterval(5000, function()

    for player in Server:GetPlayers() do

        if IsValid(player) then
            local parachuting_value = player:GetValue("ParachutingValue")

            if parachuting_value and parachuting_value > 0 then
                local item = GetEquippedItem("Parachute", player)
                if not item then return end

                local perks = player:GetValue("Perks")
                local perk_mod = 1

                for perk_id, dura_mod in pairs(parachute_perks) do
                    if perks.unlocked_perks[perk_id] then
                        perk_mod = math.min(perk_mod, dura_mod)
                    end
                end

                item.durability = item.durability - math.max(1, math.floor(parachuting_value * perk_mod))
                Inventory.ModifyDurability({
                    player = player,
                    item = item
                })
                UpdateEquippedItem(player, "Parachute", item)
                player:SetValue("ParachutingValue", 0)

            end
        end

    end

end)
