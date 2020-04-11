class "VehiclesServer"
function VehiclesServer:__init()
	--THIS CLASS HANDLES THE MAGIC OF THE MADDNESS
	self.ownedvehs = {}
	self.notownedvehs = {}
	self.vspawns = {}
	self.vtable = {}
	self.prices = {}
	self.prices["CIV_GROUND"] = 500
	self.prices["CIV_WATER"] = 700
	self.prices["CIV_HELI"] = 800
	self.prices["CIV_PLANE"] = 800
	self.prices["MIL_GROUND"] = 1500
	self.prices["MIL_WATER"] = 1700
	self.prices["MIL_HELI"] = 2000
	self.prices["MIL_PLANE"] = 1800
	self.vspawns["CIV_GROUND"] = {}
	self.vspawns["CIV_WATER"] = {}
	self.vspawns["CIV_HELI"] = {}
	self.vspawns["CIV_PLANE"] = {}
	self.vspawns["MIL_GROUND"] = {}
	self.vspawns["MIL_WATER"] = {}
	self.vspawns["MIL_HELI"] = {}
	self.vspawns["MIL_PLANE"] = {}
	self.minutes = 0
	self.timer = {}
	self.maxvehicles = 10
	self.maxplacedistance = 30
	self.spawnEnabled = true --if vehicles can spawn
	self.spawnEnabled2 = false --if you want super increased spawning for testing
	self.vtps = {}
	self.vtps["CIV_GROUND"] = {}
	self.vtps["CIV_WATER"] = {}
	self.vtps["CIV_HELI"] = {}
	self.vtps["CIV_PLANE"] = {}
	self.vtps["MIL_GROUND"] = {}
	self.vtps["MIL_WATER"] = {}
	self.vtps["MIL_HELI"] = {}
	self.vtps["MIL_PLANE"] = {}
	
	self:LoadFile("spawns.txt")
	Events:Subscribe("PlayerChat", self, self.Chat)
	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
	Events:Subscribe("PlayerQuit", self, self.PQuit)
	Events:Subscribe("PlayerAuthenticate", self, self.PJoin)
	Events:Subscribe("TimeChange", self, self.Minute)
	Events:Subscribe("SecondTick", self, self.Second)
	Events:Subscribe("ClientModuleLoad", self, self.SendDataTemp) --VEHICLE PLACING ONLY
	--Events:Subscribe("PlayerEnterVehicle", self, self.EnterVehicle)
	Events:Subscribe("ClientModuleLoad", self, self.SendVehicleTable)
	Network:Subscribe("ClientVehiclePlaceTemp", self, self.ClientVehiclePlaceTempF) --VEHICLE PLACING ONLY
	Network:Subscribe("V_ClientVehicleCreate", self, self.ClientVehicleCreate)
	Network:Subscribe("V_RemoveMyV", self, self.ClientRemoveOwnedVehicle)
	Network:Subscribe("V_ConfirmTransfer", self, self.ClientConfirmTransfer)
	Network:Subscribe("V_BuyVehicle", self, self.ClientPurchaseVehicle)
	
	for name, tabl in pairs(self.vspawns) do
		for pos, angle in pairs(self.vspawns[name]) do
			table.insert(self.vtps[name], pos)
		end
	end
	
	--Events:Subscribe("PlayerChat", self, self.Cha)
end

function VehiclesServer:Chat(args)
	--[[self.vspawns["CIV_GROUND"] = {}
	self.vspawns["CIV_WATER"] = {}
	self.vspawns["CIV_HELI"] = {}
	self.vspawns["CIV_PLANE"] = {}
	self.vspawns["MIL_GROUND"] = {}
	self.vspawns["MIL_WATER"] = {}
	self.vspawns["MIL_HELI"] = {}
	self.vspawns["MIL_PLANE"] = {}--]]
	if args.text == "/cvg" then
		local index = args.player:GetValue("CIV_GROUND")
		args.player:SetPosition(self.vtps["CIV_GROUND"][index])
		index = index + 1
		if index > #self.vtps["CIV_GROUND"] then index = 1 end
		args.player:SetValue("CIV_GROUND", index)
	elseif args.text == "/cvw" then
		local index = args.player:GetValue("CIV_WATER")
		args.player:SetPosition(self.vtps["CIV_WATER"][index])
		index = index + 1
		if index > #self.vtps["CIV_WATER"] then index = 1 end
		args.player:SetValue("CIV_WATER", index)
	elseif args.text == "/cvh" then
		local index = args.player:GetValue("CIV_HELI")
		args.player:SetPosition(self.vtps["CIV_HELI"][index])
		index = index + 1
		if index > #self.vtps["CIV_HELI"] then index = 1 end
		args.player:SetValue("CIV_HELI", index)
	elseif args.text == "/cvp" then
		local index = args.player:GetValue("CIV_PLANE")
		args.player:SetPosition(self.vtps["CIV_PLANE"][index])
		index = index + 1
		if index > #self.vtps["CIV_PLANE"] then index = 1 end
		args.player:SetValue("CIV_PLANE", index)
	elseif args.text == "/mig" then
		local index = args.player:GetValue("MIL_GROUND")
		args.player:SetPosition(self.vtps["MIL_GROUND"][index])
		index = index + 1
		if index > #self.vtps["MIL_GROUND"] then index = 1 end
		args.player:SetValue("MIL_GROUND", index)
	elseif args.text == "/miw" then
		local index = args.player:GetValue("MIL_WATER")
		args.player:SetPosition(self.vtps["MIL_WATER"][index])
		index = index + 1
		if index > #self.vtps["MIL_WATER"] then index = 1 end
		args.player:SetValue("MIL_WATER", index)
	elseif args.text == "/mih" then
		local index = args.player:GetValue("MIL_HELI")
		args.player:SetPosition(self.vtps["MIL_HELI"][index])
		index = index + 1
		if index > #self.vtps["MIL_HELI"] then index = 1 end
		args.player:SetValue("MIL_HELI", index)
	elseif args.text == "/mip" then
		local index = args.player:GetValue("MIL_PLANE")
		args.player:SetPosition(self.vtps["MIL_PLANE"][index])
		index = index + 1
		if index > #self.vtps["MIL_PLANE"] then index = 1 end
		args.player:SetValue("MIL_PLANE", index)
	end
end

function VehiclesServer:ClientPurchaseVehicle(args, sender)
	local money = sender:GetMoney()
	local moneyneed = args.vehicle:GetValue("Price")
	local driver = args.vehicle:GetDriver()
	if not moneyneed or not money then return end
	local owner = args.vehicle:GetValue("Owner")
	if owner == sender then Chat:Send(sender, "You already own this vehicle!", Color.Red) return end
	if money - moneyneed < 0 then Chat:Send(sender, "You do not have enough credits to purchase this vehicle!", Color.Red) return end
	if args.vehicle:GetValue("Cursed") then return end
	if driver ~= sender then return end
	if IsValid(owner) then
		local friendString = tostring(sender:GetValue("Friends"))
		local f1 = owner:GetValue("Faction")
		local f2 = sender:GetValue("Faction")
		if f1 ~= nil and tostring(f1) ~= "nil" and tostring(f1) ~= " " then
			if tostring(f1) == tostring(f2) and string.len(tostring(f1)) > 3 then Chat:Send(sender, "You cannot steal this vehicle from another faction member!", Color.Red) return end
		end
		if string.find(friendString, tostring(owner:GetSteamId().id)) then Chat:Send(sender, "You cannot steal this vehicle from your friend!", Color.Red) return end
	end
	if table.count(self.vtable[sender:GetSteamId().id]) >= self.maxvehicles then
		Chat:Send(sender, "You already have the maximum amount of vehicles!", Color.Red)
		return
	end
	sender:SetMoney(money - moneyneed)
	args.vehicle:SetNetworkValue("Owner", sender)
	args.vehicle:SetNetworkValue("OwnerName", sender:GetName())
	args.vehicle:SetNetworkValue("OwnerId", sender:GetSteamId().id)
	if not owner then
		--claiming an unowned vehicle
		self.notownedvehs[args.vehicle:GetId()] = nil
		self.ownedvehs[args.vehicle:GetId()] = args.vehicle
		self:AddOrUpdateToSQL(sender, args.vehicle)
		self.vtable[sender:GetSteamId().id][args.vehicle:GetId()] = args.vehicle
		self:SendClientNewData(sender)
	elseif owner ~= sender and owner then
		-- stealing an owned vehicle
		local cmd = SQL:Command("delete from vehicles where vehicleid = ?")
		cmd:Bind(1, tonumber(args.vehicle:GetValue("VehicleId")))
		cmd:Execute()
		self:AddOrUpdateToSQL(sender, args.vehicle)
		--#################################################
		self.vtable[owner:GetSteamId().id][args.vehicle:GetId()] = nil
		self.vtable[sender:GetSteamId().id][args.vehicle:GetId()] = args.vehicle
		self:SendClientNewData(owner)
		self:SendClientNewData(sender)
	end
	local str1 = "Vehicle Claimed! ("..tostring(table.count(self.vtable[sender:GetSteamId().id])).."/10)"
	Chat:Send(sender, str1, Color.Yellow)
	if IsValid(owner) then
		local str2 = "Your "..tostring(args.vehicle:GetName()).." has been stolen! ("..tostring(table.count(self.vtable[owner:GetSteamId().id])).."/10)"
		Chat:Send(owner, str2, Color.Orange)
	end
end
function VehiclesServer:ClientConfirmTransfer(args, sender)
	--WHEN THE CLIENT TRANSFERS A VEHICLE TO ANOTHER CLIENT
	if args.id == sender:GetId() then Chat:Send(sender, "Not a valid player ID!", Color.Red) return end
	local vehicle = nil
	for id, v in pairs(self.vtable[sender:GetSteamId().id]) do
		if args.v == id then
			vehicle = v
		end
	end
	if not IsValid(vehicle) then Chat:Send(sender, "Invalid vehicle!", Color.Red) return end
	local targetp
	for p in Server:GetPlayers() do
		if p:GetId() == args.id then
			targetp = p
		end
	end
	if table.count(self.vtable[targetp:GetSteamId().id]) >= self.maxvehicles then
		Chat:Send(sender, "The player already has too many vehicles!", Color.Red)
		return
	end
	vehicle:SetNetworkValue("Owner", targetp)
	vehicle:SetNetworkValue("OwnerName", targetp:GetName())
	vehicle:SetNetworkValue("OwnerId", targetp:GetSteamId().id)
	self.vtable[sender:GetSteamId().id][vehicle:GetId()] = nil
	self.vtable[targetp:GetSteamId().id][vehicle:GetId()] = vehicle
	self:SendClientNewData(sender)
	self:SendClientNewData(targetp)
	local cmd = SQL:Command("delete from vehicles where vehicleid = ?")
	cmd:Bind(1, tonumber(vehicle:GetValue("VehicleId")))
	cmd:Execute()
	self:AddOrUpdateToSQL(targetp, vehicle)
	Chat:Send(sender, "Successfully transferred "..vehicle:GetName().." to "..targetp:GetName(), Color(0,200,0))
	Chat:Send(targetp, sender:GetName().." has transferred "..vehicle:GetName().." to you", Color(0,200,0))
end
function VehiclesServer:SendClientNewData(player)
	--MAGIC VEHICLE GUI UPDATING THING
	local args = {}
	args.t1 = self.vtable[player:GetSteamId().id]
	args.t2 = {}
	for id, v in pairs(args.t1) do
		args.t2[id] = v:GetPosition()
	end
	args.t3 = self:GetT3Table(player:GetSteamId().id)
	args.t4 = {}
	for id, v in pairs(args.t1) do
		args.t4[id] = v:GetName()
	end
	Network:Send(player, "V_UpdateVTable", args)
end
function VehiclesServer:ClientRemoveOwnedVehicle(id, sender)
	--WHEN THE CLIENT HITS REMOVE ON THE F7 MENU FOR A VEHICLE
	local v = self.vtable[sender:GetSteamId().id][id]
	if IsValid(v) and v:GetValue("Owner"):GetSteamId().id == sender:GetSteamId().id then
		local args = {}
		self.vtable[sender:GetSteamId().id][id] = nil
		self:SendClientNewData(sender)
		local cmd = SQL:Command("delete from vehicles where vehicleid = ?")
		cmd:Bind(1, v:GetValue("VehicleId"))
		cmd:Execute()
		self.ownedvehs[id] = nil
		v:Remove()
	end
end
function VehiclesServer:SendVehicleTable(args)
	--WHEN THE CLIENT CONNECTS, DO DELAYED SEND OF DATA
	self.timer[args.player:GetId()] = {}
	self.timer[args.player:GetId()]["TIME"] = os.time()
	self.timer[args.player:GetId()]["PLAYER"] = args.player
end
function VehiclesServer:PQuit(args)
	--WHEN A CLIENT QUITS, REMOVE THEIR TABLE AND VEHICLES AND UPDATE SQL
	self.vtable[args.player:GetSteamId().id] = {}
	for id, v in pairs(self.ownedvehs) do
		if tonumber(v:GetValue("OwnerId")) == tonumber(args.player:GetSteamId().id) then
			self:AddOrUpdateToSQL(args.player, v)
			if IsValid(v) then
				v:Remove()
			end
			self.ownedvehs[id] = nil
			--print(tostring(args.player).." quit, removing vehicle id "..tostring(id))
		end
	end
end
function VehiclesServer:PJoin(args)   
	--WHEN A PLAYER JOINS, FIND ALL THEIR VEHICLES, UPDATE AND SPAWN ETC ETC
	self.vtable[args.player:GetSteamId().id] = {}
	local result, newVehicle = SQL:Query( "select * from vehicles" ):Execute(), nil
    if #result > 0 then
        for i, v in ipairs(result) do
			local spawn = false
			if tonumber(args.player:GetSteamId().id) == tonumber(v.ownerid) then
				spawn = true
			end
			if spawn == true then
				if tonumber(v.health) > 0.2 then
					--print("[Vehicle] Spawning ID " .. v.vehicleid)
					local psplit = v.pos:split(",")
					local asplit = v.angle:split(",")
					local vector = Vector3(tonumber(psplit[1]),tonumber(psplit[2]),tonumber(psplit[3]))
					local angle = Angle(tonumber(asplit[1]),tonumber(asplit[2]),tonumber(asplit[3]))
					newVehicle = self:SpawnVehicle(vector, angle, tonumber(v.modelid))
					local c1split = v.col1:split(",")
					local c2split = v.col2:split(",")
					local col1 = Color(tonumber(c1split[1]),tonumber(c1split[2]),tonumber(c1split[3]))
					local col2 = Color(tonumber(c2split[1]),tonumber(c2split[2]),tonumber(c2split[3]))
					newVehicle:SetColors(col1,col2)
					newVehicle:SetHealth(tonumber(v.health))
					newVehicle:SetNetworkValue("Price", tonumber(v.price))
					newVehicle:SetNetworkValue("Owner", args.player)
					newVehicle:SetNetworkValue("OwnerName", tostring(args.player:GetName()))
					newVehicle:SetNetworkValue("OwnerId", tonumber(args.player:GetSteamId().id))
					newVehicle:SetNetworkValue("VehicleId", tonumber(v.vehicleid))
					self.ownedvehs[newVehicle:GetId()] = newVehicle
					self.vtable[args.player:GetSteamId().id][newVehicle:GetId()] = newVehicle
				else
					local cmd = SQL:Command("delete from vehicles where vehicleid = ?")
					cmd:Bind(1, v.vehicleid)
					cmd:Execute()
					--print("Deleted owned vehicle with id "..v.vehicleid.." due to death on spawn")
				end
			end
        end
    end
end
--[[function VehiclesServer:EnterVehicle(args)
	--WHEN A PLAYER ENTERS A VEHICLE DO ALL CHECKS OWNER, PRICE, ETC ETC
	local owner = args.vehicle:GetValue("Owner")
	if args.vehicle:GetValue("Cursed") then return end
	if owner == args.player then return end
	if not args.is_driver then return end
	if IsValid(owner) then
		local friendString = tostring(args.player:GetValue("Friends"))
		local f1 = owner:GetValue("Faction")
		local f2 = args.player:GetValue("Faction")
		if f1 ~= nil and tostring(f1) ~= "nil" and tostring(f1) ~= " " then
			if tostring(f1) == tostring(f2) and string.len(tostring(f1)) > 3 then return end
		end
		if string.find(friendString, tostring(owner:GetSteamId().id)) then return end
	end
	if table.count(self.vtable[args.player:GetSteamId().id]) >= self.maxvehicles then
		args.player:SetPosition(args.player:GetPosition() + Vector3(0,1.5,0))
		Chat:Send(args.player, "You already have the maximum amount of vehicles!", Color.Red)
		return
	end
	local moneyneed = args.vehicle:GetValue("Price")
	local money = args.player:GetMoney()
	if not moneyneed or money - moneyneed < 0 then
		Chat:Send(args.player, "You do not have enough credits to buy this vehicle!", Color.Red)
		args.player:SetPosition(args.player:GetPosition() + Vector3(0,1.5,0))
		return
	end
	args.player:SetMoney(money - moneyneed)
	args.vehicle:SetNetworkValue("Owner", args.player)
	args.vehicle:SetNetworkValue("OwnerName", args.player:GetName())
	args.vehicle:SetNetworkValue("OwnerId", args.player:GetSteamId().id)
	if not owner then
		--claiming an unowned vehicle
		self.notownedvehs[args.vehicle:GetId()] = nil
		self.ownedvehs[args.vehicle:GetId()] = args.vehicle
		self:AddOrUpdateToSQL(args.player, args.vehicle)
		self.vtable[args.player:GetSteamId().id][args.vehicle:GetId()] = args.vehicle
		self:SendClientNewData(args.player)
	elseif owner ~= args.player and owner then
		-- stealing an owned vehicle
		local cmd = SQL:Command("delete from vehicles where vehicleid = ?")
		cmd:Bind(1, tonumber(args.vehicle:GetValue("VehicleId")))
		cmd:Execute()
		self:AddOrUpdateToSQL(args.player, args.vehicle)
		--#################################################
		self.vtable[owner:GetSteamId().id][args.vehicle:GetId()] = nil
		self.vtable[args.player:GetSteamId().id][args.vehicle:GetId()] = args.vehicle
		self:SendClientNewData(owner)
		self:SendClientNewData(args.player)
	end
	local str1 = "Vehicle Claimed! ("..tostring(table.count(self.vtable[args.player:GetSteamId().id])).."/10)"
	Chat:Send(args.player, str1, Color.Yellow)
	if owner then
		local str2 = "Your "..tostring(args.vehicle:GetName()).." has been stolen! ("..tostring(table.count(self.vtable[owner:GetSteamId().id])).."/10)"
		Chat:Send(owner, str2, Color.Orange)
	end
end--]]
function VehiclesServer:GetT3Table(pid)
	--CONVENIENCE FUNCTION BECAUSE IM LAZY
	local tb = {}
	--print(pid)
	--print(self.vtable[pid])
	for id, v in pairs(self.vtable[pid]) do
		tb[id] = v:GetHealth()*100
		--print(v:GetHealth()*100)
	end
	return tb
end
function VehiclesServer:CheckForDeadVehs()
	--CHECKS FOR DEAD VEHICLES EVERY SECOND AND REMOVES THEM AFTER 7 SECONDS AND TABLES TOO ETC
	for k,v in pairs(self.ownedvehs) do
		if IsValid(v) and v:GetHealth() <= 0 then
			if not v:GetValue("DeathT") then
				v:SetValue("DeathT", os.time())
			elseif os.time() - tonumber(v:GetValue("DeathT")) > 8 then
				--DELETE VEHICLE ON DEATH
				local cmd = SQL:Command("delete from vehicles where vehicleid = ?")
				cmd:Bind(1, v:GetValue("VehicleId"))
				cmd:Execute()
				self.ownedvehs[k] = nil
				local oid = v:GetValue("Owner"):GetSteamId().id
				--print("Deleted owned vehicle with id "..v:GetId().." due to death")
				self.vtable[oid][v:GetId()] = nil
				self:SendClientNewData(v:GetValue("Owner"))
				v:Remove()
			end
		end
	end
	for k,v in pairs(self.notownedvehs) do
		if IsValid(v) and v:GetHealth() <= 0 then
			if not v:GetValue("DeathT") then
				v:SetValue("DeathT", os.time())
			elseif os.time() - v:GetValue("DeathT") > 6 then
				self.notownedvehs[k] = nil
				--print("Deleted not owned vehicle with id "..v:GetId().." due to death")
				v:Remove()
			end
		end
	end
end
function VehiclesServer:Second()
	self:CheckForDeadVehs()
	for id, tbl in pairs(self.timer) do
		if os.time() - tbl["TIME"] > 1 then
			self:SendClientNewData(tbl["PLAYER"])
			self.timer[id] = nil
		end
	end
	if self.spawnEnabled2 then
		self:SpawnRandomVehicles()
	end
end
function VehiclesServer:Minute()
	--FIRES EVERY MINUTE
	if self.minutes >= math.random(10,30) then
		self.minutes = 0
		if self.spawnEnabled then
			self:SpawnRandomVehicles()
		end
	end
end
function VehiclesServer:IsSpawned(pos)
	--CHECK IF A NOT OWNED VEHICLE IS SPAWNED AT ITS SPAWNPOINT
	for id, v in pairs(self.notownedvehs) do
		local dist = Vector3.Distance(v:GetPosition(), pos)
		if dist < 7 then
			return true
		end
	end
	return false
end
function VehiclesServer:SpawnRandomVehicles(num)
	--SUPER COMPLEX ALGORITHM TO RANDOMLY SPAWN VEHICLES
	local numvspawns = 0
	for vtype, _ in pairs(self.vspawns) do
		for pos, angle in pairs(self.vspawns[vtype]) do
			numvspawns = numvspawns + 1
			local percent = 25
			if string.find(vtype, "MIL") then
				percent = 10
			end
			local model = vIds[vtype][math.random(#vIds[vtype])]
			if model == 64 then
				if math.random(100) <= 1 then
					model = vIds[vtype][math.random(3)]
				end
				percent = 1
			end
			if num then percent = 100 end
			if math.random(100) <= percent and not self:IsSpawned(pos) then
				local price = self.prices[vtype] + (math.random(-self.prices[vtype]/4,self.prices[vtype]))
				price = tonumber(string.format("%.0f",tostring(price)))
				local vehicle = self:SpawnVehicle(pos, angle, model)
				local col1 = table.randomvalue(colors)
				local col2 = table.randomvalue(colors)
				vehicle:SetColors(col1,col2)
				vehicle:SetNetworkValue("Price", price)
				self.notownedvehs[vehicle:GetId()] = vehicle
			end
		end
	end
	local pcent = numvspawns / table.count(self.notownedvehs)
	--Chat:Broadcast(string.format("%.0f total vehicles spawned", table.count(self.notownedvehs)), Color.Yellow)
	print(string.format("%.0f total vehicles spawned", table.count(self.notownedvehs)))
end
function VehiclesServer:SendDataTemp(args)
	--FOR PLACING VEHICLE SPAWN DATA ONLY
	args.player:SetValue("CIV_GROUND", 1)
	args.player:SetValue("CIV_WATER", 1)
	args.player:SetValue("CIV_HELI", 1)
	args.player:SetValue("CIV_PLANE", 1)
	args.player:SetValue("MIL_GROUND", 1)
	args.player:SetValue("MIL_WATER", 1)
	args.player:SetValue("MIL_HELI", 1)
	args.player:SetValue("MIL_PLANE", 1)
	args.player:SetValue("CIV_GROUND", 1)
	args.player:SetValue("CIV_GROUND", 1)
	Network:Send(args.player, "UpdateVehicleTablesTemp", self.vspawns)
end
function VehiclesServer:LoadFile(filename)
    -- Open up the spawns
    print("Opening " .. filename)
    local file = io.open( filename, "r" )

    if file == nil then
        print( "No spawns.txt, aborting loading of spawns" )
        return
    end
    -- Start a timer to measure load time
    local timer = Timer()

    -- For each line, handle appropriately
    for line in file:lines() do
        if line:sub(1,1) == "X" then
            self:ParseVehicle(line)
		end
    end
    
    print( string.format( "Loaded spawns, %.02f seconds", 
                            timer:GetSeconds() ) )

    file:close()
	
    local file = io.open( filename, "r" )
	local str = ""
    for line in file:lines() do
		str = str..line.."\n"
	end
	for vtype, _ in pairs(self.vspawns) do
		for pos, angle in pairs(self.vspawns[vtype]) do
			for vtype2, _2 in pairs(self.vspawns) do
				for pos2, angle2 in pairs(self.vspawns[vtype2]) do
					if Vector3.Distance(pos, pos2) < 5 and pos ~= pos2 then
						self.vspawns[vtype][pos] = nil
						Chat:Broadcast("REMOVED ONE SPAWN", Color.Red)
					end
				end
			end
		end
	end
	local str = ""
	for vtype, _ in pairs(self.vspawns) do
		for pos, angle in pairs(self.vspawns[vtype]) do
			str = str .. "\nX "..tostring(pos)..", "..tostring(angle)..", "..tostring(vtype)
		end
	end
	local file = io.open("spawns.txt", "w")
	file:write(str)
	file:close()

end
function VehiclesServer:ParseVehicle(line)
    -- Remove start, spaces
	line = string.trim(line)
    line = line:gsub( "X", "" )
    line = line:gsub( " ", "" )

    -- Split into tokens
    local tokens        = line:split( "," )
    -- Create vector
    local vector        = Vector3(tonumber(tokens[1]),tonumber(tokens[2]),tonumber(tokens[3]))
    local angle        = Angle(tonumber(tokens[4]),tonumber(tokens[5]),tonumber(tokens[6]))
	self.vspawns[tokens[7]][vector] = angle
	
    -- Save to table
end
function VehiclesServer:RemoveTrap(key, sender)
	--FOR REMOVING VEHICLE SPAWNS ONLY
		local pos1 = sender:GetPosition()
		local maxdist = 4
		for vtype, v in pairs(self.vspawns) do
			for location, angle in	 pairs(self.vspawns[vtype]) do
				local dist = Vector3.Distance(pos1, location)
				if dist < maxdist then
					local str = "X "..tostring(location)..", "..tostring(angle)..", "..tostring(vtype)
					--print(str)
					local num = 0
					local inf = assert(io.open("spawns.txt", "r"), "Failed to open input file") -- what textfile to read
					local lines = ""
					while(true) do
						local line = inf:read("*line")
						if not line then break end
						--[[if not string.find(line, str, 1) then --if string not found
							num = num + 1
							lines = lines .. line .. "\n"
						end--]]
						if tostring(line) ~= tostring(str) then
							num = num + 1
							lines = lines .. "\n" .. line
						else
							print("removed")
						end
					end
					inf:close()
					file = io.open("spawns.txt", "w") --what textfile to write
					file:write(lines)
					file:close()
					self.vspawns[vtype][location] = nil
					Chat:Send(sender, "Vehicle spawn type "..tostring(vtype).." removed at "..tostring(location), Color(255,0,0))

					for p in Server:GetPlayers() do
						Network:Send(p, "UpdateVehicleTablesTemp", self.vspawns)
					end
				end
			end
		end
end

function VehiclesServer:ClientVehiclePlaceTempF(key,sender)
	--FOR PLACING VEHICLE SPAWNS ONLY
	if key == 82 then
		self:RemoveTrap(key, sender)
		return
	end
	local vType = "CIV_GROUND"
	if key == 49 then vType = "CIV_GROUND"
	elseif key == 50 then vType = "CIV_WATER"
	elseif key == 51 then vType = "CIV_HELI"
	elseif key == 52 then vType = "CIV_PLANE"
	elseif key == 53 then vType = "MIL_GROUND"
	elseif key == 54 then vType = "MIL_WATER"
	elseif key == 55 then vType = "MIL_HELI"
	elseif key == 56 then vType = "MIL_PLANE"
	else return	end
	Chat:Send(sender, "Set type "..vType.." car spawn at "..tostring(sender:GetPosition()), Color(0,255,255))
	local str = "\nX "..tostring(sender:GetPosition())..", "..tostring(sender:GetAngle())..", "..tostring(vType)
	local file = io.open("spawns.txt", "a")
	file:write(str)
	file:close()
	local tablenum = table.count(self.vspawns[vType])
	self.vspawns[vType][sender:GetPosition()] = sender:GetAngle()
	for p in Server:GetPlayers() do
		Network:Send(p, "UpdateVehicleTablesTemp", self.vspawns)
	end
end
function VehiclesServer:ModuleLoad()
	--CHECK FOR PEOPLE ALREADY ON THE SERVER AND SPAWN THEIR VEHICLES, ETC
	self:SpawnRandomVehicles(1)
	local players = {}
	for p in Server:GetPlayers() do
		self.vtable[p:GetSteamId().id] = {}
		players[p:GetId()] = p
	end
	-- Uncomment this line below if you want to delete all vehicles
	 --SQL:Execute("DROP TABLE IF EXISTS vehicles")
	SQL:Execute("create table if not exists vehicles (vehicleid INTEGER PRIMARY KEY AUTOINCREMENT, modelid INTEGER, pos VARCHAR, angle VARCHAR, col1 VARCHAR, col2 VARCHAR, ownerid INTEGER, ownername VARCHAR, health FLOAT, price FLOAT)" )
    local result, newVehicle = SQL:Query( "select * from vehicles" ):Execute(), nil
    if #result > 0 then
        for i, v in ipairs(result) do
			local spawn = false
			for id, player in pairs(players) do
				if tonumber(player:GetSteamId().id) == tonumber(v.ownerid) then
					spawn = true
				end
			end
			if spawn == true then
				if tonumber(v.health) > 0 then
					--print("[Vehicle] Spawning ID " .. v.vehicleid)
					local psplit = v.pos:split(",")
					local asplit = v.angle:split(",")
					local vector = Vector3(tonumber(psplit[1]),tonumber(psplit[2]),tonumber(psplit[3]))
					local angle = Angle(tonumber(asplit[1]),tonumber(asplit[2]),tonumber(asplit[3]))
					newVehicle = self:SpawnVehicle(vector, angle, tonumber(v.modelid))
					local c1split = v.col1:split(",")
					local c2split = v.col2:split(",")
					local col1 = Color(tonumber(c1split[1]),tonumber(c1split[2]),tonumber(c1split[3]))
					local col2 = Color(tonumber(c2split[1]),tonumber(c2split[2]),tonumber(c2split[3]))
					newVehicle:SetColors(col1,col2)
					newVehicle:SetHealth(tonumber(v.health))
					newVehicle:SetNetworkValue("Price", tonumber(v.price))
					local names = Player.Match(v.ownername)
					local owner
					for id,p in pairs(names) do
						if tonumber(p:GetSteamId().id) == tonumber(v.ownerid) then
							owner = p
						end
					end
					newVehicle:SetNetworkValue("Owner", owner)
					newVehicle:SetNetworkValue("OwnerName", tostring(v.ownername))
					newVehicle:SetNetworkValue("OwnerId", tonumber(v.ownerid))
					newVehicle:SetNetworkValue("VehicleId", tonumber(v.vehicleid))
					self.ownedvehs[newVehicle:GetId()] = newVehicle
					self.vtable[owner:GetSteamId().id][newVehicle:GetId()] = newVehicle
				else
					local cmd = SQL:Command("delete from vehicles where vehicleid = ?")
					cmd:Bind(1, v.vehicleid)
					cmd:Execute()
					--print("Deleted owned vehicle with id "..v.vehicleid.." due to death on spawn reload")
				end
			end
        end
    end
end
function VehiclesServer:ModuleUnload()	
	--REMOVE ALL VEHICLES AND UPDATE OWNED VEHICLES TO SQL ETC
	for k,v in pairs(self.ownedvehs) do
		if IsValid(v) then
			self:AddOrUpdateToSQL(v:GetValue("Owner"), v)
			v:Remove()
		end
	end
	for k,v in pairs(self.notownedvehs) do
		if IsValid(v) then
			v:Remove()
		end
	end
	self.ownedvehs = {}
	self.notownedvehs = {}
end
function VehiclesServer:ClientVehicleCreate(args, sender)
	--WHEN A CLIENT USES A "VEHICLE" ITEM AND MAKES ONE
	if table.count(self.vtable[sender:GetSteamId().id]) >= self.maxvehicles then
		Chat:Send(sender, "Vehicle creation failed; you have too many vehicles already!", Color.Red)
		Network:Send(sender, "V_RefundVehicleCreate", args.id)
		return
	end
	if Vector3.Distance(args.pos, sender:GetPosition()) > self.maxplacedistance then
		Chat:Send(sender, "Vehicle creation failed; too far away!", Color.Red)
		Network:Send(sender, "V_RefundVehicleCreate", args.id)
		return
	end
	local v = self:SpawnVehicle(args.pos + Vector3(0,0.25,0), Angle(math.pi/2,0,0) * args.angle, args.id)
	if not IsValid(v) then Chat:Send(sender, "Vehicle creation failed; invalid vehicle!", Color.Red) return end
	v:SetNetworkValue("Owner", sender)
	v:SetNetworkValue("OwnerId", sender:GetSteamId().id)
	v:SetNetworkValue("OwnerName", sender:GetName())
	local price = math.random(500,1500)
	for vtype, _ in pairs(vIds) do
		for index, vid in pairs(_) do
			if vid == args.id then
				price = self.prices[vtype] + (math.random(-self.prices[vtype]/4,self.prices[vtype]))
			end
		end
	end
	v:SetNetworkValue("Price", price)
	local col1 = table.randomvalue(colors)
	local col2 = table.randomvalue(colors)
	v:SetColors(col1,col2)
	self.vtable[sender:GetSteamId().id][v:GetId()] = v
	self.ownedvehs[v:GetId()] = v
	self:AddOrUpdateToSQL(sender, v)
	self:SendClientNewData(sender)
end
function VehiclesServer:AddOrUpdateToSQL(player, vehicle)
	--SUPER MAGIC FUNCTION THAT UPDATES A VEHICLE TO SQL
	local name = player:GetName()
	local id = player:GetSteamId().id
	local cmd
	if not IsValid(vehicle) or vehicle:GetHealth() == 0 then return end
	local query = SQL:Query( "select * from vehicles where vehicleid = ? LIMIT 1" )
	if vehicle:GetValue("VehicleId") then
		query:Bind(1, vehicle:GetValue("VehicleId"))
	else
		query:Bind(1, 0)
	end
	local result = query:Execute(), nil
    if #result > 0 then
		--print("UPDATE")
		cmd = SQL:Query("update vehicles set modelid=?,pos=?,angle=?,col1=?,col2=?,ownerid=?,ownername=?,health=?,price=? where vehicleid = ?")	
		cmd:Bind( 10, vehicle:GetValue("VehicleId"))
	else
		--print("INSERT")
		cmd = SQL:Query("insert into vehicles (modelid,pos,angle,col1,col2,ownerid,ownername,health,price) values (?,?,?,?,?,?,?,?,?)")
	end
	local col1, col2 = vehicle:GetColors()
	cmd:Bind( 1, vehicle:GetModelId())
	cmd:Bind( 2, tostring(vehicle:GetPosition()))
	cmd:Bind( 3, tostring(vehicle:GetAngle()))
	cmd:Bind( 4, tostring(col1))
	cmd:Bind( 5, tostring(col2))
	cmd:Bind( 6, id)
	cmd:Bind( 7, name)
	cmd:Bind( 8, vehicle:GetHealth())
	cmd:Bind( 9, vehicle:GetValue("Price"))
	--###################################@@@@@@@@@@@ ADD ACCESS TYPE AND OWNERSHIP TYPE
	cmd:Execute()
	--print("SQL updated for vehicleid "..tostring(vehicle:GetValue("VehicleId")))
	
	cmd = SQL:Query("SELECT last_insert_rowid() as insert_id FROM vehicles")
	local result = cmd:Execute()
	if #result > 0 then
		vehicle:SetValue("VehicleId", tonumber(result[1].insert_id))
	end
end
function VehiclesServer:SpawnVehicle(pos, angle, model)
	--SPAWNS A VEHICLE LEL
	local veh, vehSpawnPos = {}, xyz
	veh.model_id = model
	veh.position = pos
	veh.angle = angle
	veh.enabled = true
	return Vehicle.Create(veh)
end

VehiclesServer = VehiclesServer()