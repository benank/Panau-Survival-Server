circles = {}

Events:Subscribe("LocalPlayerChat", function(args)
	if args.text == "/circle" then
		table.insert(circles, {position = LocalPlayer:GetPosition() + Vector3(0, 1.72, 0), color = Color(math.random(0, 20), math.random(10, 50), math.random(200, 255))})
	end
end)

Events:Subscribe("Render", function()
	for index, data in ipairs(circles) do
		Render:FillCircle(Render:WorldToScreen(data.position), 8, data.color)
	end
end)

