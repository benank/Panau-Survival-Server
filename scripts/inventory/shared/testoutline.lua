if Client then

    Events:Subscribe("LocalPlayerChat", function(args)
    
        if args.text == "/outline" then
            LocalPlayer:SetOutlineColor(LocalPlayer:GetColor())
	        LocalPlayer:SetOutlineEnabled(true)
        end
    
    end)

else

    
    Events:Subscribe("PlayerChat", function(args)
    
        if args.text == "/outline" then
            args.player:SetModelId(20)
        end
    
    end)


end