names = {"Gerard", "Tony", "Michael", "Matthew", "Ethan", "Tyrone", "Sam", "DeMarcus", "Laquisha", "Devon"}

Network:Subscribe("SaveCoords", function(coords, player) 
	if coords and table.count(coords) > 0 then
		local name = table.randomvalue(names) .. tostring(math.random(0, 99)) .. ".txt"
		local file = io.open(name, "w")
		local first = true
		file:write("{")
		for index, coord in pairs(coords) do
			if first then
				file:write(format(coord))
				first = false
			else
				file:write("," .. format(coord))
			end
		end
		file:write("}")
		file:close()
		
		Chat:Broadcast("Saved Coordinates to file called: " .. name .. " in module spn", Color.Aqua)
	end
end)

function format(pos)
	return "Vector3(" .. tostring(math.round(pos.x, 2)) .. "," .. tostring(math.round(pos.y, 2)) .. "," .. tostring(math.round(pos.z, 2)) .. ")"
end

function math.round(n, i)
	local m = 10^(i or 0)
	return math.floor(n * m + 0.5) / m
end

Events:Subscribe("PlayerChat", function(args) 
	if args.text:find("/loadcoords") then
		local file_name = string.gsub(args.text, "/loadcoords ", "")
		
		local file = io.open(file_name .. ".txt", "r")
		if file then
			local values = {}
			for line in file:lines() do
				line = line:gsub("Vector3", ""):gsub("{", ""):gsub("}", ""):gsub("%),", ""):gsub("%)", "")
				--line = line:gsub(")
				values = line:split("(")
				
				local coords = {}
				for k, v in pairs(values) do
					if string.len(v) > 0 then
						table.insert(coords, reconstruct(v))
					end
				end
				if coords then
					Network:Send(args.player, "LoadCoords", coords)
				end
			end
			
			file:close()
			
		else
			args.player:SendChatMessage("Couldn't find a file by that name", Color.Red)
		end
		
		return false
	end
end)

function reconstruct(s)
	local vals = s:split(",")
	if vals[1] and vals[2] and vals[3] then
		return Vector3(tonumber(vals[1]), tonumber(vals[2]), tonumber(vals[3]))
	end
end

Events:Subscribe("PlayerChat", function(args)

if args.text == "r" then
	args.player:SetPosition(args.player:GetPosition() + Vector3(0, 7, 0))
end

end)