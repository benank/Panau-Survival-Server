current_outpost = {}

render_radius = false

Events:Subscribe("LocalPlayerChat", function(args)

	if args.text == "/renderradius" then
		render_radius = not render_radius
	end
	
	if args.text == "/reloadoutpost" then
		local outpost = LocalPlayer:GetValue("BuildingOutpost")
		if outpost then
			current_outpost = Copy(outpost)
			LocalPlayer:SetValue("BuildingOutpost", current_outpost)
			Network:Send("ReloadOutpostFromClient", current_outpost)
			Chat:Print("Reloaded Outpost", Color.LawnGreen)
		else
			Chat:Print("Could not reload outpost", Color.Red)
		end
	end
	
	if args.text == "/recordoutpost" then
		current_outpost = {}
		LocalPlayer:SetValue("BuildingOutpost", current_outpost)
	end

end)

Events:Subscribe("Render", function()

	if not current_outpost then return end
	
	if render_radius then
		--print(current_outpost.basepos, "basepos")
		--print(current_outpost.radius, "radius")
	
		if current_outpost.basepos and current_outpost.radius then
			Render:DrawCircle(current_outpost.basepos, current_outpost.radius, Color.LawnGreen)
			
			local i = 0
			while (i < 3.1415926543) do
				local transform = Transform3()
				transform:Translate(current_outpost.basepos)
				transform:Rotate(Angle(0, i, 0))
				Render:SetTransform(transform)
				Render:DrawCircle(Vector3.Zero, current_outpost.radius, Color.LawnGreen)
				Render:ResetTransform()
				
				i = i + .075
			end
		end
	end

end)

Network:Subscribe("OutpostBuildSync", function(data)
	current_outpost[data.name] = data.value
	LocalPlayer:SetValue("BuildingOutpost", current_outpost)
end)

Events:Subscribe("UpdateAIManeuvers", function(new_maneuvers)
	local maneuvers = Copy(new_maneuvers)
	current_outpost.ai_maneuvers = maneuvers
	Network:Send("UpdateOutpostAIManeuvers", current_outpost.ai_maneuvers)
end)