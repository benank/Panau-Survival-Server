class 'Place'
lastplaced = Vector3(0,0,0)
function Place:__init()
	spawns = {}
    ---
    
	for v in Server:GetStaticObjects() do
		if v:GetValue("IsLootbox") then
			if IsValid(v) then v:Remove() end
		end
	end
	--
	local file = io.open("lootspawns.txt", "r") -- read from lootspawns.txt
	if file ~= nil then -- file might not exist
		local args = {}
		args.world = DefaultWorld
		for line in file:lines() do
			line = line:trim()
			if string.len(line) > 0 then -- filter out empty lines
				--Chat:Broadcast(tostring(line), Color(255, 0, 0))
				--Chat:Broadcast("length of line: " .. tostring(string.len(line)), Color(255, 0, 0))
				line = line:gsub(" ", "")
				line = line:trim()
                local tokens = line:split(",")
                local type = tonumber(tokens[1])
				local pos_str = {tokens[2], tokens[3], tokens[4]}
				local ang_str = {tokens[5], tokens[6], tokens[7]}
				local mdl_str = Lootbox.Models[type].model
				local col_str = Lootbox.Models[type].col
				--
				args.position = Vector3(tonumber(pos_str[1]), tonumber(pos_str[2]), tonumber(pos_str[3]))
				args.angle = Angle(tonumber(ang_str[1]), tonumber(ang_str[2]), tonumber(ang_str[3]))
				args.model = tostring(mdl_str)
				args.collision = tostring(col_str)
                local v = StaticObject.Create(args)
                v:SetValue("IsLootbox", true)
                v:SetValue("Tier", type)
				table.insert(spawns, v)
				v:SetStreamDistance(2500) -- configure loot streaming distance here
			end
		end
		file:close()
	end
end
-----
function Place:ChatHandle(args)
	if args.text == "/saveloot" then
		self:SaveLootToFile()
		Chat:Broadcast("All Loot Saved", Color(255, 0, 0))
		return false
	elseif args.text == "/sky" then
		local pos = args.player:GetPosition()
		pos.y = pos.y + 500
		args.player:SetPosition(pos)
	elseif args.text == "/dupes" then
		local dupecounter = 0
		for _, obj in pairs(spawns) do
			if IsValid(obj) then
				local pos = obj:GetPosition()
				for _, obj2 in pairs(spawns) do
					if IsValid(obj2) then
						if obj2 ~= obj then
							if pos == obj2:GetPosition() then
								--args.player:SetPosition(obj2:GetPosition())
								dupecounter = dupecounter + 1
								obj2:Remove()
							end
						end
					end
				end
			end
		end
		Chat:Broadcast("Number of Duplicates: " .. tostring(dupecounter), Color(0, 255, 0))
	end
end

function Place:SpawnBox(args, player)
	local box = StaticObject.Create({
        position = args.pos,
        angle = args.angle,
        model = Lootbox.Models[args.tier].model,
        collision = Lootbox.Models[args.tier].col
    })
    box:SetValue("IsLootbox", true)
    box:SetValue("Tier", args.tier)
	table.insert(spawns, box)
	local iden = box:GetId()
	Network:Send(player, "GetLast", {id = iden})
	Events:Fire("NewSelect", {obj = box, ply = player})
end


-----
function Place:SaveLootToFile(filename) -- save then reload from that file
	local file = io.open("lootspawns.txt", "w") -- completely re-new lootspawns.txt
	--
	for v in Server:GetStaticObjects() do
		if v:GetValue("IsLootbox") then
			local model = string.format(" %s", v:GetModel(), ",")
			local collision = string.format(" %s", v:GetCollision(), ",")
			local position = string.format(" %s", v:GetPosition(), ",")
			local angle = string.format(" %s", v:GetAngle(), ",")
            file:write("\n", string.format("%i, %s, %s",
                v:GetValue("Tier"),
                v:GetPosition(),
                v:GetAngle()))
		end
	end
	file:close()
end
--------
function Place:DeleteLootbox(args)
	local static = StaticObject.GetById(args.id)
	if IsValid(static) then static:Remove() end
end
-----
function Place:CountLoot()
	local counter = 0
	local file = io.open("lootspawns.txt", "r")
	for line in file:lines() do
		counter = counter + 1
	end
	file:close()
	Network:Broadcast("LootCounted", {num = counter})
	local superTable = {}
	for index, v in pairs(spawns) do
		if IsValid(v) then
			superTable[index] = v:GetPosition()
		end
	end
	Events:Fire("BroadcastSuperTable", superTable)
end
place = Place()

--Events:Subscribe("ModuleUnload", SaveLootToFile)
Events:Subscribe("PlayerChat", place, place.ChatHandle)
--
Network:Subscribe("SpawnBox", place, place.SpawnBox)
Network:Subscribe("DeleteLootbox", place, place.DeleteLootbox)
Events:Subscribe("TimeChange", place, place.CountLoot)