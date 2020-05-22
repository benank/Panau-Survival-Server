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
    
    local func = coroutine.wrap(function()
        
        local pos = args.player:GetPosition()
        local nearby_players = {}

        for p in Server:GetPlayers() do
            if IsValid(p) then
                local exp = p:GetValue("Exp")
                local player_pos = p:GetPosition()
                if p ~= args.player 
                and player_pos:Distance(pos) < range
                and not p:GetValue("Loading") and exp and exp.level > 0 then
                    nearby_players[p:GetId()] = {position = p:GetPosition(), name = p:GetName()}
                end
            end
            Timer.Sleep(1)
        end

        if IsValid(args.player) then
            Network:Send(args.player, "Items/Ping", {range = range, nearby_players = nearby_players})
        end

        Network:Broadcast("Items/PingSound", {position = pos, range = range})

    end)()

end)