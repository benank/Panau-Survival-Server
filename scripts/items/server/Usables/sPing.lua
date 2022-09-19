local PingPerks = 
{
    [87] = {[1] = 0.20, [2] = 0.2},
    [153] = {[1] = 0.20, [2] = 0.2},
    [187] = {[1] = 0.20, [2] = 0.2}
}

local function GetPerkMods(player)

    local perks = player:GetValue("Perks")

    if not perks then return end

    local perk_mods = {[1] = 0, [2] = 0}

    for perk_id, perk_mod_data in pairs(PingPerks) do
        local choice = perks.unlocked_perks[perk_id]
        if choice and perk_mod_data[choice] then
            perk_mods[choice] = perk_mods[choice] + perk_mod_data[choice]
        end
    end

    return perk_mods

end

Events:Subscribe("Inventory/UseItem", function(args)

    if args.item.name ~= "Ping" and args.item.name ~= "Combat Ping" then return end

    local ping_data = ItemsConfig.usables[args.item.name]

    if not ping_data then return end

    Inventory.RemoveItem({
        item = args.item,
        index = args.index,
        player = args.player
    })

    local range = math.min(1, args.player:GetPosition().y / ping_data.max_height) * ping_data.max_distance
    
    if args.item.name == "Ping" then
        local player_perks = GetPerkMods(args.player)
        
        range = range * (1 + player_perks[1]) -- Increase range perks
    end
    
    local pos = args.player:GetPosition()
    local nearby_players = {}

    for p in Server:GetPlayers() do
        if IsValid(p) then
            local exp = p:GetValue("Exp")
            local player_pos = p:GetPosition()

            player_pos.y = pos.y -- 2D distance
            
            local hidden_chance = 0
            
            if args.item.name == "Ping" then
                local player_perks = GetPerkMods(p)
                if player_perks then
                    hidden_chance = player_perks[2]
                end
            end

            if p ~= args.player 
            and player_pos:Distance(pos) < range
            and IsPlayerActive(p)
            and not p:GetValue("Invisible")
            and not p:GetValue("StealthEnabled")
            and math.random() > hidden_chance then
                nearby_players[p:GetId()] = {position = p:GetPosition(), name = p:GetName()}
            end
        end
    end

    local occupants = args.player:InVehicle() and args.player:GetVehicle():GetOccupants() or {}

    -- Don't show any passengers in the ping
    for index, player in pairs(occupants) do
        nearby_players[player:GetId()] = nil
    end

    -- Send ping to player who used it
    if IsValid(args.player) then
        Network:Send(args.player, "Items/Ping", {range = range, nearby_players = nearby_players})
    end

    -- Send ping to passengers in vehicle, if any
    for index, player in pairs(occupants) do
        if player ~= args.player then
            Network:Send(player, "Items/Ping", {range = range, nearby_players = nearby_players})
        end
    end

    Network:Broadcast("Items/PingSound", {position = pos, range = range})

end)