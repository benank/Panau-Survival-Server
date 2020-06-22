local print_timer = Timer()
local do_collision_check = false

Events:Subscribe("PostTick", function()
	if do_collision_check then
		local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 2500, false)
		if ray and print_timer:GetSeconds() > 1.5 then
			--Chat:Print(tostring(ray.distance), ray.distance < 240 and Color.LawnGreen or Color.Red)
			print_timer:Restart()
		end
	end
end) 