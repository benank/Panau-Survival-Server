        --List of admins STEAM IDS seperated by comma
admins = {
--"STEAM_0:0:107081487",
"STEAM_0:1:82883843",
--"STEAM_0:0:107081487"
}





  local timer = Timer()
 local timert = Timer()
 local ent
class 'Objectloader'
function Objectloader:__init()
	self.models					= {}
    -- Load spawns
    self:LoadSpawns( "objects.txt" )
    Events:Subscribe( "ModuleUnload",       self, self.ModuleUnload )
	Events:Subscribe("PlayerChat", self, self.ChatHandle)
end
-----
function Objectloader:ChatHandle(args) -- MUST USE CMD TO LOAD OBJECTS INTO WORLD
	if args.text == "/objectsload" then
		typerworld = args.player:GetWorld()
		self:LoadSpawns( "objects.txt" )
		args.player:SendChatMessage("Objects Loaded into your world", Color(0, 255, 0))
		return false
	end
end
-----
function Objectloader:LoadSpawns( filename )
    print("Opening " .. filename)
    local file = io.open( filename, "r" )

    if file == nil then
        print( "No objects.txt, aborting loading of staticobjects" )
        return
    end
    local timer = Timer()
    for line in file:lines() do
        if line:sub(1,1) == "M" then
            self:ParseModels( line )
        end
    end
    print( string.format( "Loaded StaticObjects, %.02f seconds",
                            timer:GetSeconds() ) )
    file:close()
end
function Objectloader:ParseModels( line )
    line = line:gsub( "ModelSpawn%(", "" )
    line = line:gsub( "%)", "" )
    line = line:gsub( " ", "" )
    local tokens = line:split( "," )
    local pos_str       = { tokens[4], tokens[5], tokens[6] }
    local ang_str       = { tokens[7], tokens[8], tokens[9] }
	local mdl_str		= tokens[2]
	local col_str		= tokens[3]
    local args = {}
    args.position       = Vector3(   tonumber( pos_str[1] ),
                                    tonumber( pos_str[2] ),
                                    tonumber( pos_str[3] ) )

    args.angle          = Angle(    tonumber( ang_str[1] ),
                                    tonumber( ang_str[2] ),
                                    tonumber( ang_str[3] ))
    args.model			= tostring(mdl_str)
	args.collision 		= tostring(col_str)

	args.world 			= typerworld
    args.enabled = true
    local v = StaticObject.Create(args)
	v:SetStreamDistance(500)
    self.models[ v:GetId() ] = v
end
function Objectloader:ModuleUnload( args )
	for h in Server:GetStaticObjects() do
		h:Remove()
		end
end
objectloader = Objectloader()


function IsAdmin(player)
	if player:GetValue("MoveSpeed") == nil then
		player:SetValue("MoveSpeed", -0.01)
	end
	if player:GetValue("RotationSpeed") == nil then
		player:SetValue("RotationSpeed", -5.625)
	end
	return true
end

bool = false
function GetCoords(args)
	--args.player:SendChatMessage("This feature is currently disabled", Color(0, 255, 0))
	if bool == false then return end
	local splittedText = args.text:split ( " " )
    if ( splittedText ) then
		if(splittedText[1] == "/saveall") then
		if IsAdmin(args.player) then
		local h,err = io.open("objects.txt","w")
		h:close()
		for v in Server:GetStaticObjects() do

		local modelid 	= string.format(" %s", v:GetId(),"," )
			local model 	= string.format(" %s", v:GetModel(),"," )
			local collision = string.format(" %s", v:GetCollision(),"," )
			local position 	= string.format(" %s", v:GetPosition(),"," )
			local angle 	= string.format(" %s", v:GetAngle(), "," )
			local f,err = io.open("objects.txt","a")
		 f:write("\n", "ModelSpawn(", modelid, ",", model, ",", collision, "," , position, ",", angle,  ")")
		f:close()
		end
		args.player:SendChatMessage( "Objects Written to File!", Color( 255, 0, 0 ) )
		end
		end
		if(splittedText[1] == "/removeall") then
		if IsAdmin(args.player) then
		for v in Server:GetStaticObjects() do
		v:Remove()
		end
		args.player:SendChatMessage( "ALL Objects Removed From Server!", Color( 255, 0, 0 ) )
		end
end

		end
		end

function ReloadObjects(args,player)
if IsAdmin(player) then
for v in Server:GetStaticObjects() do
		v:Remove()
		end


    local file = io.open( "objects.txt", "r" )

    if file == nil then
        print( "No objects.txt, aborting loading of staticobjects" )
        return
    end
    local timer = Timer()
    for line in file:lines() do
        if line:sub(1,1) == "M" then
           line = line:gsub( "ModelSpawn%(", "" )
    line = line:gsub( "%)", "" )
    line = line:gsub( " ", "" )
    local tokens = line:split( "," )
    local pos_str       = { tokens[4], tokens[5], tokens[6] }
    local ang_str       = { tokens[7], tokens[8], tokens[9] }
	local mdl_str		= tokens[2]
	local col_str		= tokens[3]
    local args = {}
    args.position       = Vector3(   tonumber( pos_str[1] ),
                                    tonumber( pos_str[2] ),
                                    tonumber( pos_str[3] ) )

    args.angle          = Angle(    tonumber( ang_str[1] ),
                                    tonumber( ang_str[2] ),
                                    tonumber( ang_str[3] ))
    args.model			= tostring(mdl_str)
	args.collision 		= tostring(col_str)

	args.world 			= player:GetWorld()
    args.enabled = true
    local v = StaticObject.Create(args)
	v:SetStreamDistance(500)
    --self.models[ v:GetId() ] = v
        end
    end
    print( string.format( "Loaded StaticObjects, %.02f seconds",
                            timer:GetSeconds() ) )
    file:close()


		-----------------------------------------------------------------------------------------
		player:SendChatMessage( "Objects Reloaded From File!", Color( 255, 0, 0 ) )
end

end




function SaveObjectsToFilef (args, player)
if IsAdmin(player) then
		local h,err = io.open("objects.txt","w")
		h:close()
		for v in Server:GetStaticObjects() do

		local modelid 	= string.format(" %s", v:GetId(),"," )
			local model 	= string.format(" %s", v:GetModel(),"," )
			local collision = string.format(" %s", v:GetCollision(),"," )
			local position 	= string.format(" %s", v:GetPosition(),"," )
			local angle 	= string.format(" %s", v:GetAngle(), "," )
			local f,err = io.open("objects.txt","a")
		 f:write("\n", "ModelSpawn(", modelid, ",", model, ",", collision, "," , position, ",", angle,  ")")
		f:close()
		end
		player:SendChatMessage( "Objects Written to File!", Color( 255, 0, 0 ) )
		end


end


function Removeallf (args, player)
player:SendChatMessage("This feature is currently disabled", Color(0, 255, 0))
if bool == false then return end
if IsAdmin(player) then
		for v in Server:GetStaticObjects() do
		v:Remove()
		end
		player:SendChatMessage( "ALL Objects Removed From Server!", Color( 255, 0, 0 ) )
		end


end

function VSaveCarCoordsf (args, player)
--player:SendChatMessage("This feature is currently disabled", Color(0, 255, 0))
if IsAdmin(player) then
--local modelid = string.format(" %s", player:GetVehicle():GetModelId(),"," )
	--	local coords = string.format(" %s", player:GetVehicle():GetPosition(),"," )
		--local angle = string.format(" %s", player:GetVehicle():GetAngle(), "," )
		--local f,err = io.open("cars.txt","a")
		--if not f then return print(err) end
		-- f:write("\n", "VehicleSpawn(", modelid, ",", coords, ",", angle, " , NULL, NULL)")
		--f:close()
		--print("\n", "VehicleSpawn(", modelid, ",", coords, ",", angle, " , NULL, NULL)")
		--print("\n", "Vehicle Location Saved!")
		--player:SendChatMessage("VL Saved @ "..coords ,Color(0, 255, 0, 255))
		end
end

function VikIncreasef (args, player) -- increase moving speed
    if IsAdmin(player) then
	if player:GetState() == PlayerState.OnFoot then
	local movespeed = player:GetValue("MoveSpeed")
	if movespeed <= -163.84 then
		movespeed = -163.84
	end
	movespeed = movespeed * 2
	player:SetValue("MoveSpeed", movespeed)
	local pspeed = movespeed * (-1)
	player:SendChatMessage( "Movespeed Increased to " ..pspeed , Color( 255, 255, 255, 64 ) )


	end
	end
end


function VikDecreasef (args, player)
	if IsAdmin(player) then
	if player:GetState() == PlayerState.OnFoot then
	local movespeed = player:GetValue("MoveSpeed")
	if movespeed >= -0.01 then
	movespeed = -0.01
	end
	movespeed = movespeed / 2
	player:SetValue("MoveSpeed", movespeed)
	local pspeed = movespeed * (-1)
	player:SendChatMessage( "Movespeed Decreased to " ..pspeed , Color( 255, 255, 255, 64 ) )

	end
	end
end
-----------------------------------------Rotationspeed Adjustments------------------------------------------------
function VikIncreaserf (args, player)
    if IsAdmin(player) then
	if player:GetState() == PlayerState.OnFoot then
	local rotationspeed = player:GetValue("RotationSpeed")
	if rotationspeed <= -90 then
	rotationspeed = -90
	end
	rotationspeed = rotationspeed * 2
	player:SetValue("RotationSpeed", rotationspeed)
	local pspeed = rotationspeed * (-1)
	player:SendChatMessage( "Rotationspeed Increased to " ..pspeed , Color( 255, 255, 255, 64 ) )


	end
	end
end

function VikDecreaserf (args, player)
	if IsAdmin(player) then
	if player:GetState() == PlayerState.OnFoot then
	local rotationspeed = player:GetValue("RotationSpeed")
	if rotationspeed >= -0.17578125 then
	rotationspeed = -0.17578125
	end
	rotationspeed = rotationspeed / 2
	player:SetValue("RotationSpeed", rotationspeed)
	local pspeed = rotationspeed * (-1)
	player:SendChatMessage( "Rotationspeed Decreased to " ..pspeed , Color( 255, 255, 255, 64 ) )

	end
	end
end
----------------------------------------------------------SpeedSet Functions end here--------------------------------

function VikSwitchf (args, player)
	if IsAdmin(player) then
	if player:GetState() == PlayerState.OnFoot then
	local ent = GetAT(player)
	if IsValid(ent) then
		player:SetValue("BuildEntity", ent:GetId())
		player:SendChatMessage("Object Selected", Color(0, 255, 0, 175))
	end
	--local getent = StaticObject.GetById(player:GetValue("BuildEntity"))
	end
end
end

function VikDuplicateEntf (args, player)
	if IsAdmin(player) then
	if player:GetState() == PlayerState.OnFoot then
	local ent2 = GetAT(player)
	if IsValid(ent2) then
	player:SetValue("BuildEntity", ent2:GetId())
	spawnArgs = {}

	spawnArgs.position = ent2:GetPosition()
	spawnArgs.angle = ent2:GetAngle()
	spawnArgs.model = ent2:GetModel()
	spawnArgs.collision = ent2:GetCollision()
	spawnArgs.world = player:GetWorld()

	StaticObject.Create(spawnArgs)
	local entstr = string.format(" %s", ent2:GetModel(),"," )
	player:SendChatMessage( "Object" ..entstr.. "Duplicated" , Color( 250, 250, 250, 72 ) )
	end
	end
end
end

function VikDuplicateEntGuif (args, player)
	if IsAdmin(player) then
	if player:GetState() == PlayerState.OnFoot then
	--local T = player:GetAimTarget()
	--ent = T.entity
	if type(player:GetValue("BuildEntity")) ~= "number" then return end
	local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
	if IsValid(ent) then
	spawnArgs = {}

	spawnArgs.position = ent:GetPosition()
	spawnArgs.angle = ent:GetAngle()
	spawnArgs.model = ent:GetModel()
	spawnArgs.collision = ent:GetCollision()
	spawnArgs.world = player:GetWorld()

	StaticObject.Create(spawnArgs)
	local entstr = string.format(" %s", ent:GetModel(),"," )
	player:SendChatMessage( "Object" ..entstr.. "Duplicated" , Color( 250, 250, 250, 72 ) )
	--EyEEditor:StatsToGui()
	end
	end
end
end


function Viktremoveentf(args, player) -- gets player
if IsAdmin(player) then
if player:GetState() == PlayerState.OnFoot then
if type(player:GetValue("BuildEntity")) ~= "number" then return end
local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
if IsValid(ent) then
local entstr = string.format(" %s", ent:GetModel(),"," )
ent:Remove()
player:SendChatMessage( "Object"..entstr.. " Removed", Color( 255, 255, 255, 128 ) )
end
end
end
end
 function VMoveStaticobjectUpf (args, player)
if IsAdmin(player) then
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			local movespeed = player:GetValue("MoveSpeed")
			if IsValid(ent) then
			local newposx = ent:GetPosition().x
			local newposy = ent:GetPosition().y + (-movespeed)  ----------move object 0.1 untis up -----------
			local newposz = ent:GetPosition().z
			local v1 = Vector3(newposx, newposy, newposz)

			ent:SetPosition(v1)
			end
		end
		end



function VMoveStaticobjectDownf (args, player)
if IsAdmin(player) then
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(tonumber(player:GetValue("BuildEntity")))
			local movespeed = player:GetValue("MoveSpeed")
			if IsValid(ent) then
			local newposx = ent:GetPosition().x
			local newposy = ent:GetPosition().y + (movespeed)  ----------move object 0.1 untis Down -----------
			local newposz = ent:GetPosition().z
			local v2 = Vector3(newposx, newposy, newposz)

			ent:SetPosition(v2)
			end
		end
		end

function VMoveStaticobjectLeftf (args, player)							----------move object Left -----------
if IsAdmin(player) then
			local cam1 = args.angle
			local movespeed = player:GetValue("MoveSpeed")
			local left = cam1 * Vector3(movespeed, 0, 0)

			--local plyang = player:GetAngle()
			--local left = plyang * Vector3(movespeed, 0, 0)

			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			if IsValid(ent) then
			local newpos = ent:GetPosition()
			local v3 = newpos - left
			if player:GetValue("Y-Lock") == true then
				ent:SetPosition(Vector3(v3.x, newpos.y, v3.z))
			else
				ent:SetPosition(v3)
			end
			end
end
end

function VMoveStaticobjectRightf (args, player)				----------move object  Right -----------
if IsAdmin(player) then
			local cam1 = args.angle
			local movespeed = player:GetValue("MoveSpeed")
			local right = cam1 * Vector3(movespeed, 0, 0)
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			if IsValid(ent) then
			local newpos = ent:GetPosition()
			local v4 = newpos + right
			if player:GetValue("Y-Lock") == true then
				ent:SetPosition(Vector3(v4.x, newpos.y, v4.z))
			else
				ent:SetPosition(v4)
			end
			end
end
end

 function VMoveStaticobjectForwardf (args, player)			----------move object Forward -----------
if IsAdmin(player) then
			local cam1 = args.angle
			local movespeed = player:GetValue("MoveSpeed")
			local forward = cam1 * Vector3(0, 0, movespeed)
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			if IsValid(ent) then
			local newpos = ent:GetPosition()
			local v5 = newpos + forward
			if player:GetValue("Y-Lock") == true then
				ent:SetPosition(Vector3(v5.x, newpos.y, v5.z))
			else
				ent:SetPosition(v5)
			end
			end
end
end

function VMoveStaticobjectBackwardf (args, player)			----------move object Backward -----------
if IsAdmin(player) then
			local cam1 = args.angle
			local movespeed = player:GetValue("MoveSpeed")
			local backward = cam1 * Vector3(0, 0, movespeed)
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			if IsValid(ent) then
			local newpos = ent:GetPosition()
			local v6 = newpos - backward
			ent:SetPosition(v6)
			if player:GetValue("Y-Lock") == true then
				ent:SetPosition(Vector3(v6.x, newpos.y, v6.z))
			else
				ent:SetPosition(v6)
			end
			end
end
end







-----------------------------------------------------------------Rotations--------------------------------------------------------


function VRotateStaticobjectRightf (args, player)
if IsAdmin(player) then
			if ObjectSet.Prime == nil then
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			local rotationspeed = player:GetValue("RotationSpeed")
			if IsValid(ent) then
			local newangx = ent:GetAngle().pitch
			local newangy = ent:GetAngle().roll
			local newangz = ent:GetAngle().yaw  -- + 0.010000  ----------Rotate object 0.1 untis Right -----------
			newangz = math.deg(newangz)
			newangz = newangz - rotationspeed
			newangz = math.rad(newangz)
			local v7 = Angle(newangz, newangx, newangy)
			ent:SetAngle(v7)
			end end
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			if IsValid(v) then
			local newangx = v:GetAngle().pitch
			local newangy = v:GetAngle().roll
			local newangz = v:GetAngle().yaw  -- + 0.010000  ----------Rotate object 0.1 untis Right -----------
			newangz = math.deg(newangz)
			newangz = newangz - rotationspeed
			newangz = math.rad(newangz)
			local v7 = Angle(newangz, newangx, newangy)
			v:SetAngle(v7)
			end
			end
			end
		end
		end

 function VRotateStaticobjectLeftf (args, player)
if IsAdmin(player) then
			if ObjectSet.Prime == nil then
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			local rotationspeed = player:GetValue("RotationSpeed")
			if IsValid(ent) then
			local newangx = ent:GetAngle().pitch
			local newangy = ent:GetAngle().roll
			local newangz = ent:GetAngle().yaw   -- 0.010000  ----------Rotate object 0.1 untis Left -----------
			newangz = math.deg(newangz)
			newangz = newangz + rotationspeed
			newangz = math.rad(newangz)
			local v8 = Angle(newangz, newangx, newangy)
			ent:SetAngle(v8)
			end end
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			if IsValid(v) then
			local newangx = v:GetAngle().pitch
			local newangy = v:GetAngle().roll
			local newangz = v:GetAngle().yaw   -- 0.010000  ----------Rotate object 0.1 untis Left -----------
			newangz = math.deg(newangz)
			newangz = newangz + rotationspeed
			newangz = math.rad(newangz)
			local v8 = Angle(newangz, newangx, newangy)
			v:SetAngle(v8)
			end
			end
			end
			end
		end

 function VRotateStaticobjectUpf (args, player)
if IsAdmin(player) then
			if ObjectSet.Prime == nil then
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			local rotationspeed = player:GetValue("RotationSpeed")
			if IsValid(ent) then
			local newangx = ent:GetAngle().pitch	--+ 0.010000  ----------Rotate object 0.1 untis Left -----------
			newangx = math.deg(newangx)
			newangx = newangx - rotationspeed
			newangx = math.rad(newangx)
			local newangy = ent:GetAngle().roll
			local newangz = ent:GetAngle().yaw
			local v9 = Angle(newangz, newangx, newangy)
			ent:SetAngle(v9)
			end end
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			if IsValid(v) then
			local newangx = v:GetAngle().pitch	--+ 0.010000  ----------Rotate object 0.1 untis Left -----------
			newangx = math.deg(newangx)
			newangx = newangx - rotationspeed
			newangx = math.rad(newangx)
			local newangy = v:GetAngle().roll
			local newangz = v:GetAngle().yaw
			local v9 = Angle(newangz, newangx, newangy)
			v:SetAngle(v9)
			end
			end
			end
			end
		end

 function VRotateStaticobjectDownf (args, player)
if IsAdmin(player) then
			if ObjectSet.Prime == nil then
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			local rotationspeed = player:GetValue("RotationSpeed")
			if IsValid(ent) then
			local newangx = ent:GetAngle().pitch	--- 0.010000  ----------Rotate object 0.1 untis Right -----------
			newangx = math.deg(newangx)
			newangx = newangx + rotationspeed
			newangx = math.rad(newangx)
			local newangy = ent:GetAngle().roll
			local newangz = ent:GetAngle().yaw
			local v10 = Angle(newangz, newangx, newangy)
			ent:SetAngle(v10)
			end end

			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			if IsValid(v) then
			local newangx = v:GetAngle().pitch	--- 0.010000  ----------Rotate object 0.1 untis Right -----------
			newangx = math.deg(newangx)
			newangx = newangx + rotationspeed
			newangx = math.rad(newangx)
			local newangy = v:GetAngle().roll
			local newangz = v:GetAngle().yaw
			local v10 = Angle(newangz, newangx, newangy)
			v:SetAngle(v10)
			end
			end end
			end
		end

function VRotateStaticobjectRollf (args, player)
if IsAdmin(player) then
			if ObjectSet.Prime == nil then
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			local rotationspeed = player:GetValue("RotationSpeed")
			if IsValid(ent) then
			local newangx = ent:GetAngle().pitch
			local newangy = ent:GetAngle().roll   --+ 0.010000  ----------Roll object 0.1 untis Left -----------
			newangy = math.deg(newangy)
			newangy = newangy - rotationspeed
			newangy = math.rad(newangy)

			local newangz = ent:GetAngle().yaw
			local v11 = Angle(newangz, newangx, newangy)
			ent:SetAngle(v11)
			end
			end

		if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			if IsValid(v) then
			local newangx = v:GetAngle().pitch
			local newangy = v:GetAngle().roll   --+ 0.010000  ----------Roll object 0.1 untis Left -----------
			newangy = math.deg(newangy)
			newangy = newangy - rotationspeed
			newangy = math.rad(newangy)

			local newangz = v:GetAngle().yaw
			local v11 = Angle(newangz, newangx, newangy)
			v:SetAngle(v11)

		end
		end
		end
		end
		end
function VRotateStaticobjectRollnf (args, player)
if IsAdmin(player) then
			if ObjectSet.Prime == nil then
			if type(player:GetValue("BuildEntity")) ~= "number" then return end
			local ent = StaticObject.GetById(player:GetValue("BuildEntity"))
			local rotationspeed = player:GetValue("RotationSpeed")
			if IsValid(ent) then
			local newangx = ent:GetAngle().pitch
			local newangy = ent:GetAngle().roll   -- 0.010000  ----------Roll object 0.1 untis Right -----------
			newangy = math.deg(newangy)
			newangy = newangy + rotationspeed
			newangy = math.rad(newangy)
			local newangz = ent:GetAngle().yaw
			local v12 = Angle(newangz, newangx, newangy)

			ent:SetAngle(v12)
			end end

			--debug
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			if IsValid(v) then
			local newangx = v:GetAngle().pitch
			local newangy = v:GetAngle().roll   -- 0.010000  ----------Roll object 0.1 untis Right -----------
			newangy = math.deg(newangy)
			newangy = newangy + rotationspeed
			newangy = math.rad(newangy)
			local newangz = v:GetAngle().yaw
			local v12 = Angle(newangz, newangx, newangy)

			v:SetAngle(v12)

			end
			end
			end
			end
		    end


		------------------------------SETS----------------------------------------------
		-------------------------------------------------------------------------------
ObjectSet = {}
ObjectSet.Prime = nil
local offsetpos = Vector3()
local primeposition = Vector3()
-------------------------------------Move Sets------------------------------------------------

function VMoveStaticobjectsetUpf (args, player)

if IsAdmin(player) then
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			if IsValid(v) then
			local newposx = v:GetPosition().x
			local newposy = v:GetPosition().y + (-movespeed)  ----------move object 0.1 untis up -----------
			local newposz = v:GetPosition().z
			local v1 = Vector3(newposx, newposy, newposz)

			v:SetPosition(v1)
			ObjectSet[v] = v
		end
		end
		end
		end
		end


function VMoveStaticobjectsetDownf (args, player)
if IsAdmin(player) then
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			if IsValid(v) then
			local newposx = v:GetPosition().x
			local newposy = v:GetPosition().y + (movespeed)  ----------move object 0.1 untis Down -----------
			local newposz = v:GetPosition().z
			local v2 = Vector3(newposx, newposy, newposz)

			v:SetPosition(v2)
			end
		end
		end
		end
		end
function VMoveStaticobjectsetLeftf (args, player)							----------move object Left -----------
if IsAdmin(player) then
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			local cam1 = args.angle
			local left = cam1 * Vector3(movespeed, 0, 0)

			--local plyang = player:GetAngle()
			--local left = plyang * Vector3(movespeed, 0, 0)
			if IsValid(v) then
			local newpos = v:GetPosition()
			local v3 = newpos - left
			if player:GetValue("Y-Lock") == true then
				v:SetPosition(v3.x, newpos.y, v3.z)
			else
				v:SetPosition(v3)
			end
			end
			end
			end
end
end

function VMoveStaticobjectsetRightf (args, player)				----------move object  Right -----------
if IsAdmin(player) then
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			local cam1 = args.angle
			local right = cam1 * Vector3(movespeed, 0, 0)
			if IsValid(v) then
			local newpos = v:GetPosition()
			local v4 = newpos + right
			if ylock == true then
				v:SetPosition(v4.x, newpos.y, v4.z)
			else
				v:SetPosition(v4)
			end
			end
end
end
end
end

 function VMoveStaticobjectsetForwardf (args, player)			----------move object Forward -----------
if IsAdmin(player) then
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			local cam1 = args.angle
			local forward = cam1 * Vector3(0, 0, movespeed)
			if IsValid(v) then
			local newpos = v:GetPosition()
			local v5 = newpos + forward
			if ylock == true then
				v:SetPosition(v5.x, newpos.y, v5.z)
				Chat:Broadcast("Entered", Color(0, 255, 0))
			else
				v:SetPosition(v5)
				Chat:Broadcast("Entered", Color(0, 255, 0))
			end
			end
			end
			end
end
end

function VMoveStaticobjectsetBackwardf (args, player)			----------move object Backward -----------
if IsAdmin(player) then
			if ObjectSet ~= nil then
			ObjectSet.Prime = nil -------remove prime because already exist as secent
			for i, v in pairs(ObjectSet) do
			local cam1 = args.angle
			local backward = cam1 * Vector3(0, 0, movespeed)
			if IsValid(v) then
			local newpos = v:GetPosition()
			local v6 = newpos - backward
			if ylock == true then
				v:SetPosition(v6.x, newpos.y, v6.z)
				Chat:Broadcast("Entered", Color(0, 255, 0))
			else
				v:SetPosition(v6)
				Chat:Broadcast("Entered", Color(0, 255, 0))
			end
			end
end
end
end
end



-----------------------------------------------------------------------------------------------------
-------------------------------------Move sets Ends--------------------------------------------------

 function Getsecent(args, player)
  se = GetAT(player)
  return se
  end
 function SaveSet (args, player)





 end

function Addtosetf (args, player)
if IsAdmin(player) then
primeent = GetAT(player)
--primeent = ent

if ObjectSet.Prime == nil then
if IsValid(primeent) then
ObjectSet.Prime = primeent
primeposition = primeent:GetPosition()
player:SendChatMessage( "Set Started , Start Picking!", Color( 0, 255, 0 ) )
--ObjectSet[1] = primeent
--ObjectSet[primeent:GetId()] = primeent
 end
end
local sectarget = primetarget
local secent = primetarget.entity

---get prime out of table ---
if ObjectSet.Prime ~= nil then
secent = GetAT(player)


if secent == nil then
secent = primeent
end
if secent ~= nil then
local secent = sectarget.entity
ObjectSet[secent:GetId()] = secent
player:SendChatMessage( "Object Added To set", Color( 0, 128, 0,64 ) )
end
 --[[
local primeentc = ObjectSet.Prime
primepos = primeentc:GetPosition()
local secpos = secent:GetPosition()
--offsetpos = primepos:Distance(secpos)

local primeposx = primeentc:GetPosition().x
local primeposy = primeentc:GetPosition().y
local primeposz = primeentc:GetPosition().z

local secposx = secent:GetPosition().x
local secposy = secent:GetPosition().y
local secposz = secent:GetPosition().z

local offsetposx = 0
local offsetposy = 0
local offsetposz = 0


if primeposx > secposx then
offsetposx	= primeposx - secposx
end

if primeposx < secposx then
offsetposx = secposx - primeposx
end
        -----position Y------
if primeposy > secposy then
offsetposy	= primeposy - secposy
end
if primeposy < secposy then
offsetposy = secposy - primeposy
end
         -----Position z ---------
if primeposz > secposz then
offsetposz	= primeposz - secposz
end
if primeposz < secposz then
offsetposz = secposz - primeposz
end
--Vector3(number x, number y, number z)
--local offsetpos = Vector3()
--local offsetpos = Vector3(offsetposx, offsetposy, offsetposz)
offsetpos.x = offsetposx
offsetpos.y = offsetposy
offsetpos.z = offsetposz



----create offsetposition---------
 --offsetpos = (offsetposx, offsetposy, offsetposz)


local strprimepos = string.format(" %s", primepos, "," )
local strsecpos = string.format(" %s", secpos, "," )
local stroffsetpos 	= string.format(" %s", offsetpos, ",")
print("the Prime position is : "..strprimepos)
print("the Picked position is : "..strsecpos)
print("the Offsetposition is : "..stroffsetpos)
--secent = secent

local secang = secent:GetAngle()
local secmodel = secent:GetModel()
local seccol = secent:GetCollision()

spawnArgs = {}
	spawnArgs.position = (primepos + offsetpos)
	spawnArgs.angle = secang
	spawnArgs.model = secmodel
	spawnArgs.collision = seccol
	spawnArgs.world = DefaultWorld

	local copysecent = StaticObject.Create(spawnArgs)
     copysecent:SetEnabled(false)]]
--copysecent:SetPosition(offsetpos)


end






--ObjectSet[secent] = secent
--ObjectSet[secent:GetId()] = secent

end
end


function Clearsetf (args, player)
if IsAdmin(player) then
for k,v in pairs(ObjectSet) do ObjectSet[k]=nil end
player:SendChatMessage( "Set Cleared", Color( 255, 0, 0 ) )
print("set Cleared!!!")
end
end


-------------Stats to gui-------------------
class 'EyEEditor'

function EyEEditor:__init()

end
function EyEEditor:StatsToGui ()
local args = {}

args.model = tostring(ent:GetModel())
args.collision = tostring(ent:GetCollision())
args.position = tostring(ent:GetPosition())
args.angle = tostring(ent:GetAngle())

Network:Send( "Stats", args, player )

end
eyeeditor = EyEEditor()

function randpos()
local t = {90, 180, 360, 720, 45}
return table.randomvalue(t)
end

function randrot()
local t = {90, 45, 22.5, 11.25, 5.626, 2.8125}
return table.randomvalue(t)
end

function joinTables(t1, t2)

        for k,v in ipairs(t2) do table.insert(t1, v) end return t1

end



function SpawnArrayf(args)
--if IsAdmin(player) then
for k,v in pairs(ObjectSet) do ObjectSet[k]=nil   ---clear the set before starting a new one
end
ytable ={}
local entities = {}
local numtimes = tonumber(args.NumberOfObjects)

local numtimesx = tonumber (args.NumberOfObjX)
--local numtimesxdup = numtimesx
local numtimesy = tonumber (args.NumberOfObjY)
--local numtimesydup = numtimesy
local numtimesz = tonumber (args.NumberOfObjZ)
--local numtimeszdup = numtimesz



 while numtimes ~= 0 do
local ent2 = ent

local position = ent2:GetPosition()


if args.randposx == 0 then
position.x = position.x + tonumber(args.OffsetX) /10
position.y = position.y + tonumber(args.OffsetY) /10
position.z = position.z + tonumber(args.OffsetZ) /10
end
if args.randposx == 1 then position.x = position.x + randpos() end
if args.randposy == 1 then position.y = position.y + randpos() end
if args.randposz == 1 then position.z = position.z + randpos() end


local angle = ent:GetAngle()

local angp = ent2:GetAngle().pitch
local angy = ent2:GetAngle().yaw
local angr = ent2:GetAngle().roll
			angp = math.deg(angp)
			if args.randrotp == 1 then angp = angp + randrot() end
			if args.randrotp == 0 then angp = angp + tonumber(args.OffsetPitch) end
			angp = math.rad(angp)
			angy = math.deg(angy)
			if args.randroty == 1 then angy = angy + randrot() end
			if args.randroty == 0 then angy = angy + tonumber(args.OffsetYaw) end
			angy = math.rad(angy)
			angr = math.deg(angr)
			if args.randrotr == 1 then angr = angr + randrot() end
			if args.randrotr == 0 then angr = angr + tonumber(args.OffsetRoll) end
			angr = math.rad(angr)

	angle = Angle(angy, angp, angr)

	spawnArgs = {}
	spawnArgs.position = position
	spawnArgs.angle = angle
	spawnArgs.model = ent2:GetModel()
	spawnArgs.collision = ent2:GetCollision()
	spawnArgs.world = player:GetWorld()
	ent2 = StaticObject.Create(spawnArgs)
	ent2:SetPosition(position)
	ent2:SetAngle(angle)
	ent = ent2
    ObjectSet[ent2] = ent2
	numtimes = numtimes - 1

end				-----------------Numtimes Loop Ends-------------------


---------------------Create along X Axis -------------------------------


if numtimesx ~= 0 then
if numtimesx ~= nil then
xtable = {}
numtimes = 0
while numtimesx ~= 0 do


entx = ent
entxpos = entx:GetPosition()


if args.randposx == 0 then entxpos.x = entxpos.x + tonumber(args.OffsetX) /10 end
if args.randposx == 1 then entxpos.x = entxpos.x + randpos() /10 end

local angle = entx:GetAngle()

local angp = entx:GetAngle().pitch
local angy = entx:GetAngle().yaw
local angr = entx:GetAngle().roll
			angp = math.deg(angp)
			if args.randrotp == 1 then angp = angp + randrot() end
			if args.randrotp == 0 then angp = angp + tonumber(args.OffsetPitch) end
			angp = math.rad(angp)
			angy = math.deg(angy)
			if args.randroty == 1 then angy = angy + randrot() end
			if args.randroty == 0 then angy = angy + tonumber(args.OffsetYaw) end
			angy = math.rad(angy)
			angr = math.deg(angr)
			if args.randrotr == 1 then angr = angr + randrot() end
			if args.randrotr == 0 then angr = angr + tonumber(args.OffsetRoll) end
			angr = math.rad(angr)

	angle = Angle(angy, angp, angr)

	----angle = Angle(angy, angp, angr)
	spawnArgsx = {}
	spawnArgsx.position = entxpos
	spawnArgsx.angle = angle
	spawnArgsx.model = entx:GetModel()
	spawnArgsx.collision = entx:GetCollision()
	spawnArgsx.world = player:GetWorld()
	entx = StaticObject.Create(spawnArgsx)
	entx:SetPosition(entxpos)
	entx:SetAngle(angle)
	numtimesx = numtimesx -1
	ent = entx
	xtable[entx] = entx
	ytable[entx] = entx
	ObjectSet[entx] = entx

					----------------Loop X ends------------------------
end
end
      ------------------------Create along Z axis---------------------------


if numtimesz ~= 0 then
if numtimesz ~= nil then
ztable = {}  --------create a table to hold our objects
numtimes = 0
--local entz = entx
local locoffsetz = 0
while numtimesz ~= 0 do


for i, v in pairs(xtable) do

--local entz = v
local entzpos = v:GetPosition()
local entzang = v:GetAngle()

if args.randposz == 0 then entzpos.z = entzpos.z + tonumber(args.OffsetZ) /10 + locoffsetz end
if args.randposz == 1 then entzpos.z = entzpos.z + randpos() /10 + locoffsetz end

local zangp = v:GetAngle().pitch
local zangy = v:GetAngle().yaw
local zangr = v:GetAngle().roll
			zangp = math.deg(zangp)
			if args.randrotp == 1 then zangp = zangp + randrot() end
			if args.randrotp == 0 then zangp = zangp + tonumber(args.OffsetPitch) end
			zangp = math.rad(zangp)
			zangy = math.deg(zangy)
			if args.randroty == 1 then zangy = zangy + randrot() end
			if args.randroty == 0 then zangy = zangy + tonumber(args.OffsetYaw) end
			zangy = math.rad(zangy)
			zangr = math.deg(zangr)
			if args.randrotr == 1 then zangr = zangr + randrot() end
			if args.randrotr == 0 then zangr = zangr + tonumber(args.OffsetRoll) end
			zangr = math.rad(zangr)

	entzang = Angle(zangy, zangp, zangr)
	spawnArgsz = {}
	spawnArgsz.position = entzpos
	spawnArgsz.angle = entzang
	spawnArgsz.model = v:GetModel()
	spawnArgsz.collision = v:GetCollision()
	spawnArgsz.world = player:GetWorld()
	entz = StaticObject.Create(spawnArgsz)
	entz:SetPosition(entzpos)
	entz:SetAngle(entzang)

	entz = entz
	ztable[entz] = entz
	ytable[entz] = entz
	ObjectSet[entz] = entz
end-------------for loop ends-----------------

if args.randposz == 0 then locoffsetz = locoffsetz + tonumber(args.OffsetZ) / 10 end
if args.randposz == 1 then locoffsetz = locoffsetz + randpos() /10 end
numtimesz = numtimesz -1



end  -------------While Loop ends
end
end

				 ------------------------Create along Y axis   UP---------------------------

if numtimesy ~= 0 then
if numtimesy ~= nil then

--for k,v in pairs(ztable) do xtable[k] = return ytable end
--for k,v in ipairs(xtable) do table.insert(ztable, v) end
--ytable = {}  --------create a table to hold our objects
--ytable =

--ytable = joinTables ( ztable, xtable)
numtimes = 0
--local entz = entx
local locoffsety = 0
while numtimesy ~= 0 do


for i, v in pairs(ytable) do

--local entz = v
local entypos = v:GetPosition()
local entyang = v:GetAngle()

if args.randposy == 0 then entypos.y = entypos.y + tonumber(args.OffsetY) /10 + locoffsety end
if args.randposy == 1 then entypos.y = entypos.y + randpos() + locoffsety /10 end

local yangp = v:GetAngle().pitch
local yangy = v:GetAngle().yaw
local yangr = v:GetAngle().roll
			yangp = math.deg(yangp)
			if args.randrotp == 1 then yangp = yangp + randrot() end
			if args.randrotp == 0 then yangp = yangp + tonumber(args.OffsetPitch) end
			yangp = math.rad(yangp)
			yangy = math.deg(yangy)
			if args.randroty == 1 then yangy = yangy + randrot() end
			if args.randroty == 0 then yangy = yangy + tonumber(args.OffsetYaw) end
			yangy = math.rad(yangy)
			yangr = math.deg(yangr)
			if args.randrotr == 1 then yangr = yangr + randrot() end
			if args.randrotr == 0 then yangr = yangr + tonumber(args.OffsetRoll) end
			yangr = math.rad(yangr)

	entyang = Angle(yangy, yangp, yangr)
spawnArgsy = {}
	spawnArgsy.position = entypos
	spawnArgsy.angle = entyang
	spawnArgsy.model = v:GetModel()
	spawnArgsy.collision = v:GetCollision()
	spawnArgsy.world = player:GetWorld()
	entz = StaticObject.Create(spawnArgsy)
	entz:SetPosition(entypos)
	entz:SetAngle(entyang)
	--ztable[entz:GetId()] = entz
	enty = enty
	ObjectSet[entz] = entz

end -------------for loop ends-----------------

if args.randposy == 0 then locoffsety = locoffsety + tonumber(args.OffsetY) /10 end
if args.randposy == 1 then locoffsety = locoffsety + randpos() /10 end
numtimesy = numtimesy -1



end  -------------While Loop ends
end
end
end -------------checkadmin end
end            ---------------Function ends--------------
----
proxitems = {}
function GetAT(player)
	AT = player:GetAimTarget()
	--if not AT.entity then -- if not AT then get nearest staticobject
		--local plypos = player:GetPosition()
		--closestobjectdistance = 999999
		--for object in Server:GetStaticObjects() do
		--	if plypos:Distance(object:GetPosition()) < closestobjectdistance then
		--		--Chat:Broadcast("plypos:Distance(objectpos) < closestobjectdistance", Color(0, 255, 0))
		--		closestobjectdistance = plypos:Distance(object:GetPosition())
		--		AT = object
		--		--Chat:Broadcast("New closestobjectdistance: " .. tostring(closestobjectdistance), Color(0, 255, 0))
		--	end
	--	end
		--player:SetPosition(AT:GetPosition())
--	else
		AT = AT.entity
		--Chat:Broadcast("Entity Found: " .. tostring(AT.entity), Color(0, 255, 0))
	--end
	--Chat:Broadcast("Closest Object is " .. tostring(closestobjectdistance) .. " meters away", Color(0, 255, 0))
	--player:SendChatMessage("Object Selected", Color(0, 255, 0))
	return AT
end
-----------
function OverrideEnt(args, player)
	player:SetValue("BuildEntity", args.myobject:GetId())
	player:SendChatMessage("Object Selected", Color(0, 255, 0, 175))
end
Network:Subscribe("ChangeEnt", OverrideEnt)
---------
function OverrideEntLootPlacer(args)
	local player2 = args.ply
	player2:SetValue("BuildEntity", args.obj:GetId())
end
Events:Subscribe("NewSelect", OverrideEntLootPlacer)
---------

function CHandle(args)
	if args.text == "/y" then
		if args.player:GetValue("Y-Lock") ~= nil then
			local ylock = args.player:GetValue("Y-Lock")
			ylock = not ylock
			args.player:SetValue("Y-Lock", ylock)
			args.player:SendChatMessage("Y-Axis Lock: " .. tostring(ylock), Color(0, 255, 0))
		else
			args.player:SetValue("Y-Lock", false)
			local ylock = false
			args.player:SendChatMessage("Y-Axis Lock: " .. tostring(ylock), Color(0, 255, 0))
		end
		return false
	end
end
Events:Subscribe("PlayerChat", CHandle)
--[[
	local ent3 = ent2
	local ent4 = ent2
	local ent5 = ent2
	--if numtimesx ~=0 then
	--------------------------------Along X Axis---------------------------
	while numtimesx ~= 0 do

	--local ent4pos = ent3:GetPosition()
	local position3 = position
	if args.randposx == 0 then
	position3.x = position3.x + tonumber(args.OffsetX)
	end
	if args.randposx == 1 then position3.x = position3.x + randpos() end
	angle = Angle(angy, angp, angr)
	spawnArgs2 = {}
	spawnArgs2.position = position3
	spawnArgs2.angle = angle
	spawnArgs2.model = ent:GetModel()
	spawnArgs2.collision = ent:GetCollision()
	spawnArgs2.world = DefaultWorld
	ent3 = StaticObject.Create(spawnArgs2)
	ent3:SetPosition(position3)
	ent3:SetAngle(angle)
	--ent4 = ent3
	numtimesx = numtimesx -1
	end
	ent5 = ent3

	-------------------------------------Along Z Axis ------------------------------------
	while numtimesz ~= 0 do

	--local ent4pos = ent3:GetPosition()
	local position5 = position
	if args.randposz == 0 then
	position5.z = position5.z + tonumber(args.OffsetZ)
	end
	if args.randposz == 1 then position5.z = position5.z + randpos() end
	angle = Angle(angy, angp, angr)
	spawnArgs4 = {}
	spawnArgs4.position = position5
	spawnArgs4.angle = angle
	spawnArgs4.model = ent:GetModel()
	spawnArgs4.collision = ent:GetCollision()
	spawnArgs4.world = DefaultWorld
	ent5 = StaticObject.Create(spawnArgs4)
	ent5:SetPosition(position5)
	ent5:SetAngle(angle)
	--ent4 = ent3
	numtimesz = numtimesz -1
	end
	ent4 = ent5
	--------------------------Along Y Axis --------------------------------------
	while numtimesy ~= 0 do

	--local ent4pos = ent3:GetPosition()
	local position4 = position
	if args.randposy == 0 then
	position4.y = position4.y + tonumber(args.OffsetY)
	end
	if args.randposy == 1 then position4.y = position4.y + randpos() end
	angle = Angle(angy, angp, angr)
	spawnArgs3 = {}
	spawnArgs3.position = position4
	spawnArgs3.angle = angle
	spawnArgs3.model = ent:GetModel()
	spawnArgs3.collision = ent:GetCollision()
	spawnArgs3.world = DefaultWorld
	ent4 = StaticObject.Create(spawnArgs3)
	ent4:SetPosition(position4)
	ent4:SetAngle(angle)
	--ent4 = ent3
	numtimesy = numtimesy -1
	end

	numtimesz = numtimeszdup
	numtimesy = numtimesydup
	numtimesx = numtimesxdup


]]--
-----------------------------------------------------------------------------------
------------------------------------------New Array-----------------------------------
-----------------------------------------------------------------------------------
--[[x = {}
z = {}
y = {}
function SpawnEntity(args)



	args.position = pos
	args.angle = angle
	args.model = ent:GetModel()
	args.collision = ent:GetCollision()
	args.world = DefaultWorld
	v = StaticObject.Create(args)
	v:SetPosition(pos)
	v:SetAngle(angle)
return v
end

--------------------Along X Axis--------------------------------
]]

----sets-------

Network:Subscribe( "Addtoset", Addtosetf)
Network:Subscribe( "Clearset", Clearsetf)
--------array--------

Network:Subscribe( "SpawnArray", SpawnArrayf)
----for gui-------

Network:Subscribe( "ReloadFromFile", ReloadObjects)
Network:Subscribe( "SaveToFile", SaveObjectsToFilef)
Network:Subscribe( "RemoveAll", Removeallf)
 ---------------------Value Changing functions-----------
 Network:Subscribe( "Increase", VikIncreasef)
 Network:Subscribe( "Decrease", VikDecreasef)
 Network:Subscribe( "Increaser", VikIncreaserf)
 Network:Subscribe( "Decreaser", VikDecreaserf)
 Network:Subscribe( "Savedupref", VikSwitchf)
 Network:Subscribe( "DuplicateEnt", VikDuplicateEntf)
 Network:Subscribe( "DuplicateEntGui", VikDuplicateEntGuif)

 Network:Subscribe( "RemoveEnt", Viktremoveentf)

---------------------Movements---------------------------
Network:Subscribe( "ObjectDown", VMoveStaticobjectDownf)
Network:Subscribe( "ObjectUp", VMoveStaticobjectUpf)
Network:Subscribe( "ObjectLeft", VMoveStaticobjectLeftf)
Network:Subscribe( "ObjectRight", VMoveStaticobjectRightf)
Network:Subscribe( "ObjectForward", VMoveStaticobjectForwardf)
Network:Subscribe( "ObjectBackward", VMoveStaticobjectBackwardf)

-----------------------move sets-------------------------------
Network:Subscribe( "ObjectsetDown", VMoveStaticobjectsetDownf)
Network:Subscribe( "ObjectsetUp", VMoveStaticobjectsetUpf)
Network:Subscribe( "ObjectsetLeft", VMoveStaticobjectsetLeftf)
Network:Subscribe( "ObjectsetRight", VMoveStaticobjectsetRightf)
Network:Subscribe( "ObjectsetForward", VMoveStaticobjectsetForwardf)
Network:Subscribe( "ObjectsetBackward", VMoveStaticobjectsetBackwardf)


----------------------Save Car Coordinates to Cars.txt file---------------
Network:Subscribe( "SaveCarCoords", VSaveCarCoordsf)
---------------------StaticObject Commands------------------------
Events:Subscribe("PlayerChat", GetCoords)
-------------------------Rotations------------------------------------

Network:Subscribe( "ObjectRotYawn", VRotateStaticobjectRightf)
Network:Subscribe( "ObjectRotYaw", VRotateStaticobjectLeftf)
Network:Subscribe( "ObjectRotPitchn", VRotateStaticobjectUpf)
Network:Subscribe( "ObjectRotPitch", VRotateStaticobjectDownf)
Network:Subscribe( "ObjectRotRolln", VRotateStaticobjectRollf)
Network:Subscribe( "ObjectRotRoll", VRotateStaticobjectRollnf)
--------------------------------------------------------------
