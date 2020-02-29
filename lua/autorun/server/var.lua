Network:Subscribe("var_mismatch", function(args, player)
    if args.b == 1 then
        -- Encryption failed
        print(player:GetName() .. " var encryption fail. Val: " .. tostring(args.a))
    else
        -- Var was modified
        print(player:GetName() .. " var mismatch. Expected: " .. tostring(args.a) .. " Actual: " .. tostring(args._a))
    end
    player:Kick("Cheating")
    --player:Ban("Cheating")
end)