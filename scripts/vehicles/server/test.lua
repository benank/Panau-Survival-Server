local vehicle = nil
local index = 1


Events:Subscribe("PlayerChat", function(args)

    local split = args.text:split(" ")

    if split[1] == "/v" then

        if IsValid(vehicle) then vehicle:Remove() end

        vehicle = Vehicle.Create({
            model_id = tonumber(split[2]),
            position = args.player:GetPosition(),
            angle = args.player:GetAngle(),
            template = split[3],
            decal = split[4],
            invulnerable = true
        })

    end

    if args.text == "/posi" then
        local pos = args.player:GetPosition()
        local ang = args.player:GetAngle()
        print(pos.x .. ", " .. pos.y .. ", " .. pos.z .. ", " .. ang.x .. ", " .. ang.y .. ", " .. ang.z)
    end

    if args.text == '/testx' then
        args.player:Teleport(args.player:GetPosition(), args.player:GetAngle())
    end

end)

Events:Subscribe("ModuleUnload", function()
    if IsValid(vehicle) then vehicle:Remove() end
end)