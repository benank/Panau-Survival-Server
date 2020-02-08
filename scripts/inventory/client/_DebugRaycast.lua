local debug_on = true
_raycasts = {}
local raycast_time = 2500 -- ms
local PhysRaycast = Physics.Raycast

if debug_on then
	class 'RaycastRenderer'
	
	function RaycastRenderer:__init(raycast_time)
		self.raycast_time = raycast_time
		self.raycast_timer = Timer()
		self.render = Events:Subscribe("GameRender", self, self.Render)
	end
	
	function RaycastRenderer:Render()
		local elapsed = self.raycast_timer:GetMilliseconds()
		local progress = elapsed / self.raycast_time
		
		if progress > 1 then progress = 1 end
		
		for index, raycast_data in ipairs(_raycasts) do
			local raycast = raycast_data.raycast
			local start_pos = raycast_data.start_position
			local direction = raycast_data.direction
			
			--print(raycast.distance)
			
			local p1 = start_pos
			local p2 = start_pos + (direction * (raycast.distance * progress))
			
			Render:DrawLine(p1, p2, raycast.color)
		end
	end
	
	function RaycastRenderer:Remove()
		self.raycast_time = nil
		Events:Unsubscribe(self.render)
	end
	
	--function Physics:Raycast(start_position, direction, min_distance, max_distance)
	--	
	--end
	
	function Raycast(start_position, direction, min_distance, max_distance)
		--print(start_position, direction, min_distance, max_distance)
		local raycast = Physics:Raycast(start_position, direction, min_distance, max_distance)
		table.insert(_raycasts, {raycast = raycast, start_position = start_position, direction = direction})
		
		return raycast
	end
	
	Timer.SetInterval(raycast_time * 1.5, function() 
	
		if raycast_renderer then
			raycast_renderer:Remove()
		end
		raycast_renderer = RaycastRenderer(raycast_time)
	
	end)
end

Events:Subscribe("LocalPlayerChat", function(args)

	if args.text == "/raycast" then
		local raycast = Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 500)
		return false
	end

end)

