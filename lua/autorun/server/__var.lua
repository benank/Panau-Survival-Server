Network:Subscribe("var_mismatch", function(args, player)
    local reason = ""
    if args.b == 1 then
        -- Encryption failed
        reason = player:GetName() .. " var encryption fail. Val: " .. tostring(args.a)
    else
        -- Var was modified
        reason = player:GetName() .. " var mismatch. Expected: " .. tostring(args.a) .. " Actual: " .. tostring(args._a)
    end
    Events:Fire("BanPlayer", {
        player = player,
        p_reason = "Cheating",
        reason = reason
    })
end)