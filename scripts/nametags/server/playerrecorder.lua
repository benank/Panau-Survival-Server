function join(args)
	Write(args.player)
end
function Write(p)
	local word = "sp[\""..tostring(p:GetSteamId()).."\"] = \"[Beta]\" --"..p:GetName()
	if word then
		local inf = assert(io.open("betas.txt", "r"), "Failed to open input file") -- what textfile to read
		local lines = ""
		while(true) do
			local line = inf:read("*line")
			if not line then break end
			line = string.trim(line)
			if not string.find(tostring(line), (tostring(p:GetSteamId()))) then --if string not found
				lines = lines .. line .."\n"
			end
		end
		inf:close()
		file = io.open("betas.txt", "w") --what textfile to write
		file:write(lines)
		file:close()
		local str = tostring(word).."\n"
		local file = io.open("betas.txt", "a")
		file:write(str)
		file:close()
	end
end
--Events:Subscribe("PlayerJoin", join)