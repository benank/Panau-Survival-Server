Events:Subscribe("PlayerChat", function(args) 

    if (args.text == "/storm") then

        local pos = args.player:GetPosition() + Vector3(2000, 0, 2000)
        pos.y = 0
        local storm = sStorm(pos)

        Chat:Send(args.player, "You created storm", Color(0,255,0))
        print("Created storm")

        return false

    elseif (args.text == "/day") then

        DefaultWorld:SetTime(12)
        DefaultWorld:SetTimeStep(0)
        Chat:Send(args.player, "Set to day", Color(0,255,0))

    elseif args.text == "/pos" then

        print(args.player:GetPosition())

    end

end)