Events:Subscribe("PlayerChat", function(args)

    if not args.player:GetValue("Admin") then return end

    local words = args.text:split(" ")

    if words[1] == "/invin" then
        local invincible = not args.player:GetValue("Invincible")
        args.player:SetNetworkValue("Invincible", invincible)
        Chat:Send(args.player, "Invincible: " .. tostring(invincible), Color.Yellow)
    elseif words[1] == "/invis" then
        local invisible = not args.player:GetValue("Invisible")
        args.player:SetNetworkValue("Invisible", invisible)
        args.player:SetStreamDistance(invisible and 0 or 1024)
        Chat:Send(args.player, "Invisible: " .. tostring(invisible) .. " (WILL RESET ON DEATH)", Color.Yellow)
    elseif words[1] == "/tpp" and words[2] then
        local target_player = Player.GetById(tonumber(words[2]))

        if IsValid(target_player) then
            args.player:SetPosition(target_player:GetPosition())
            Chat:Send(args.player, "Teleported to " .. target_player:GetName(), Color.Yellow)
        else
            Chat:Send(args.player, string.format("Player with id %d not found", tonumber(words[2])), Color.Yellow)
        end
    elseif words[1] == "/tptome" and words[2] then
        local target_player = Player.GetById(tonumber(words[2]))

        if IsValid(target_player) then
            target_player:SetPosition(args.player:GetPosition())
            Chat:Send(args.player, "Teleported " .. target_player:GetName() .. " to you.", Color.Yellow)
        else
            Chat:Send(args.player, string.format("Player with id %d not found", tonumber(words[2])), Color.Yellow)
        end
    elseif words[1] == "/spec" and words[2] then
        local target_player = Player.GetById(tonumber(words[2]))

        if IsValid(target_player) then
            Network:Send(args.player, "SetCameraPos", {pos = target_player:GetPosition() + Vector3.Up * 3, player = target_player})
            Chat:Send(args.player, "Now spectating " .. target_player:GetName(), Color.Yellow)
        else
            Chat:Send(args.player, string.format("Player with id %d not found", tonumber(words[2])), Color.Yellow)
        end
    elseif words[1] == "/pkill" and words[2] then
        local target_player = Player.GetById(tonumber(words[2]))

        if IsValid(target_player) then
            Events:Fire("Hitdetection/AdminKill", {player = target_player, attacker = args.player})
            Chat:Send(args.player, "Killed " .. target_player:GetName(), Color.Yellow)
        else
            Chat:Send(args.player, string.format("Player with id %d not found", tonumber(words[2])), Color.Yellow)
        end
    end


end)