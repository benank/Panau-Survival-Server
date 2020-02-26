class 'Place'
lastplaced = Vector3(0,0,0)
function Place:__init()
	spawns = {}
    ---
    

	tier1 = {}
	tier1.model = "mod.heavydrop.grenade.eez/wea00-c.lod"
	tier1.collision = "mod.heavydrop.grenade.eez/wea00_lod1-c_col.pfx"
	tier1.angle = Angle(0, 0, 0)
	tier2 = {}
	tier2.model = "f1m03airstrippile07.eez/go164_01-a.lod"
	tier2.collision = "f1m03airstrippile07.eez/go164_01_lod1-a_col.pfx"
	tier2.angle = Angle(0, 0, 0)
	tier3 = {}
	tier3.model = "mod.heavydrop.beretta.eez/wea00-b.lod"
	tier3.collision = "mod.heavydrop.beretta.eez/wea00_lod1-b_col.pfx"
	tier3.angle = Angle(0, 0, 0)
	tier4 = {}
	tier4.model = "mod.heavydrop.assault.eez/wea00-a.lod"
	tier4.collision = "mod.heavydrop.assault.eez/wea00_lod1-a_col.pfx"
    tier4.angle = Angle(0, 0, 0)
    
    self.tiers = {}
    self.tiers[1] = tier1
    self.tiers[2] = tier2
    self.tiers[3] = tier3
    self.tiers[4] = tier4
    self.tiers[tier1.model] = 1
    self.tiers[tier2.model] = 2
    self.tiers[tier3.model] = 3
    self.tiers[tier4.model] = 4

	--
	for v in Server:GetStaticObjects() do
		local model = v:GetModel()
		if model == tier1.model or model == tier2.model or model == tier3.model or model == tier4.model then
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
				local mdl_str = self.tiers[type].model
				local col_str = self.tiers[type].collision
				--
				args.position = Vector3(tonumber(pos_str[1]), tonumber(pos_str[2]), tonumber(pos_str[3]))
				args.angle = Angle(tonumber(ang_str[1]), tonumber(ang_str[2]), tonumber(ang_str[3]))
				args.model = tostring(mdl_str)
				args.collision = tostring(col_str)
				local v = StaticObject.Create(args)
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
-----
function Place:SpawnTier1(args, player)
	if player:GetValue("TrapPlacingMode") == 1 then return end
    tier1.position = args.pos
    tier1.angle = args.angle
	local t1 = StaticObject.Create(tier1)
	table.insert(spawns, t1)
	local iden = t1:GetId()
	Network:Send(player, "GetLast", {id = iden})
	Events:Fire("NewSelect", {obj = t1, ply = player})
end
-----
function Place:SpawnTier2(args, player)
	if player:GetValue("TrapPlacingMode") == 1 then return end
	tier2.position = args.pos
    tier2.angle = args.angle
	local t2 = StaticObject.Create(tier2)
	table.insert(spawns, t2)
	local iden = t2:GetId()
	Network:Send(player, "GetLast", {id = iden})
	Events:Fire("NewSelect", {obj = t2, ply = player})
end
-----
function Place:SpawnTier3(args, player)
	if player:GetValue("TrapPlacingMode") == 1 then return end
	local dist = Vector3.Distance(args.pos, lastplaced)
	print(tostring(player).." placed T3 "..tostring(dist).."m away from the last one at "..tostring(args.pos))
	lastplaced = args.pos
	tier3.position = args.pos
    tier3.angle = args.angle
	local t3 = StaticObject.Create(tier3)
	table.insert(spawns, t3)
	local iden = t3:GetId()
	Network:Send(player, "GetLast", {id = iden})
	Events:Fire("NewSelect", {obj = t3, ply = player})
end
-----
function Place:SpawnTier4(args, player)
	if player:GetValue("TrapPlacingMode") == 1 then return end
	local dist = Vector3.Distance(args.pos, lastplaced)
	print(tostring(player).." placed T4 "..tostring(dist).."m away from the last one at "..tostring(args.pos))
	lastplaced = args.pos
	tier4.position = args.pos
    tier4.angle = args.angle
	local t4 = StaticObject.Create(tier4)
	table.insert(spawns, t4)
	local iden = t4:GetId()
	Network:Send(player, "GetLast", {id = iden})
	Events:Fire("NewSelect", {obj = t4, ply = player})
end
-----
function Place:SaveLootToFile(filename) -- save then reload from that file
	local file = io.open("lootspawns.txt", "w") -- completely re-new lootspawns.txt
	--
	for v in Server:GetStaticObjects() do
		local model = v:GetModel()
		if model == tier1.model or model == tier2.model or model == tier3.model or model == tier4.model then
			local model = string.format(" %s", v:GetModel(), ",")
			local collision = string.format(" %s", v:GetCollision(), ",")
			local position = string.format(" %s", v:GetPosition(), ",")
			local angle = string.format(" %s", v:GetAngle(), ",")
            file:write("\n", string.format("%i, %s, %s",
                self.tiers[v:GetModel()],
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
Network:Subscribe("SpawnTier1", place, place.SpawnTier1)
Network:Subscribe("SpawnTier2", place, place.SpawnTier2)
Network:Subscribe("SpawnTier3", place, place.SpawnTier3)
Network:Subscribe("SpawnTier4", place, place.SpawnTier4)
Network:Subscribe("DeleteLootbox", place, place.DeleteLootbox)
Events:Subscribe("TimeChange", place, place.CountLoot)