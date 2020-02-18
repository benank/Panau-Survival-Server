
function Player:SendErrorMessage( str )
    self:SendChatMessage( str, Color( 255, 0, 0 ) )
end

function Player:SendSuccessMessage( str )
    self:SendChatMessage( str, Color( 0, 255, 0 ) )
end

function Spawnatron:__init()
	
	-- HEY RIGHT HERE! This variable here controls if spawning a new car gets rid of the last one, change it to false if you want this disabled (Not great for big public servers!)
	Deletelast = false

    self.items      = {}
    self.vehicles   = {}
    self.hotspots   = {}
	self.staticobjects = {}
    self.ammo_counts            = {
        [2] = { 12, 60 }, [4] = { 7, 35 }, [5] = { 30, 90 },
        [6] = { 3, 18 }, [11] = { 20, 100 }, [13] = { 6, 36 },
        [14] = { 4, 32 }, [16] = { 3, 12 }, [17] = { 5, 5 },
        [28] = { 26, 130 }, [43] = { 100, 300}, [26] = { 999, 999 },
		[31] = { 999, 999 }, [52] = { 999, 999}, [66] = { 999,999},
		[100] = { 12, 120 }, [101] = { 600, 600 },
  [102] = { 1, 20 }, [103] = { 6, 60 }, [104] = { 8, 24 },
  [105] = { 4, 12 }
    }

    self:CreateItems()

    Events:Fire( "SpawnPoint" )
    Events:Fire( "TeleportPoint" )

    Events:Subscribe( "PlayerJoin", self, self.PlayerJoin )
    Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )

    Events:Subscribe( "SpawnPoint", self, self.AddHotspot )
    Events:Subscribe( "TeleportPoint", self, self.AddHotspot )

    Network:Subscribe( "PlayerFired", self, self.PlayerFired )    

    SQL:Execute( "create table if not exists Spawnatron_players (steamid VARCHAR UNIQUE, model_id INTEGER)")
end

function Spawnatron:IsInHotspot( pos )
    for _, v in ipairs(self.hotspots) do
        if (pos - v):LengthSqr() < 625 then -- 25m deadzone
            return true
        end
    end

    return false
end

function Spawnatron:PlayerJoin( args )
    local qry = SQL:Query( "select model_id from Spawnatron_players where steamid = (?)" )
    qry:Bind( 1, args.player:GetSteamId().id )
    local result = qry:Execute()

    if #result > 0 then
        args.player:SetModelId( tonumber(result[1].model_id) )
    end
end

function Spawnatron:PlayerQuit( args )
    if IsValid( self.vehicles[ args.player:GetId() ] ) then
        self.vehicles[ args.player:GetId() ]:Remove()
        self.vehicles[ args.player:GetId() ] = nil
    end
end

function Spawnatron:ModuleUnload()
    for k, v in pairs(self.vehicles) do
        if IsValid( v ) then
            v:Remove()
        end
    end
end

function Spawnatron:AddHotspot( pos )
    for _, v in ipairs(self.hotspots) do
        if (pos - v):LengthSqr() < 16 then -- 4m error
            return
        end
    end
    
    table.insert( self.hotspots, pos )
end
------    model_id, price, model, collision, name
function Spawnatron:PlayerFired( args, player )
    local category_id       = args[1]
    local subcategory_name  = args[2]
    local index             = args[3]
    local tone1             = args[4]
    local tone2             = args[5]

    local hotspot_categories = {
        self.types.Vehicle
    }

    local item = self.items[category_id][subcategory_name][index]
	
    if item == nil then
        player:SendErrorMessage( "Invalid item!" )
        return
    end

    local success, err    

    if category_id == self.types.Vehicle then
        success, err = self:BuyVehicle( player, item, tone1, tone2 )
    elseif category_id == self.types.Weapon then           
        success, err = self:BuyWeapon( player, item )
    elseif category_id == self.types.Model then
        success, err = self:BuyModel( player, item )
	elseif category_id == self.types.StaticObject then
        success, err = self:BuyStaticObject( player, item )
    end
end

function Spawnatron:BuyVehicle( player, item, tone1, tone2 )
    if player:GetState() == PlayerState.InVehiclePassenger then
        return false, "You cannot s a vehicle while in the passenger seat!"
    end
	
	if Deletelast == true then
		if IsValid( self.vehicles[ player:GetId() ] ) then
			self.vehicles[ player:GetId() ]:Remove()
			self.vehicles[ player:GetId() ] = nil
		end
	end
		
    local args = {}
    args.model_id           = item:GetModelId()
    args.position           = player:GetPosition()
    args.angle              = player:GetAngle()
    args.linear_velocity    = player:GetLinearVelocity() * 1.1
    args.enabled            = true
    args.tone1              = tone1
    args.tone2              = tone2

    local v = Vehicle.Create( args )
	v:SetWorld(player:GetWorld())
    self.vehicles[ player:GetId() ] = v

    v:SetUnoccupiedRespawnTime( nil )
    player:EnterVehicle( v, VehicleSeat.Driver )

    return true, ""
end

------------------------------vik spawn objs--------------------------------------------
function Spawnatron:BuyStaticObject( player, item )
    --if player:GetState() == PlayerState.InVehiclePassenger then
        --return false, "You cannot s a vehicle while in the passenger seat!"
   -- end
		
    local args = {}
-------
local aimt = player:GetAimTarget()
local angl = Angle(0, 0, 0)
	args.position = 	aimt.position + Vector3(0,0.5,0)
	args.angle = 		angl
	args.model = 		item:GetModel()
	args.collision = 	item:GetCollision()
------
    args.world 			= player:GetWorld()
    args.enabled = true
    local v = StaticObject.Create(args)
	--v:SetEnabled(True)
	v:Respawn()
	--v:SetStreamDistance(500)
    self.staticobjects[ v:GetId() ] = v
	
	--local mmodel = string.format(" %s", item:GetName()(),"," )
	
	player:SendChatMessage( "Spawned: "..item:GetName(), Color( 225, 225, 255, 80 ) )
    --return true, ""
end
-------------------------------------------------vik Spawn Objs end----------------------------------------


function Spawnatron:BuyWeapon( player, item )
    player:GiveWeapon( item:GetSlot(), 
        Weapon( item:GetModelId(), 
            self.ammo_counts[item:GetModelId()][1] or 0,
            (self.ammo_counts[item:GetModelId()][2] or 200) * 6 ) )

    return true, ""
end

function Spawnatron:BuyModel( player, item )
    player:SetModelId( item:GetModelId() )

    local cmd = SQL:Command( 
        "insert or replace into Spawnatron_players (steamid, model_id) values (?, ?)" )
    cmd:Bind( 1, player:GetSteamId().id )
    cmd:Bind( 2, item:GetModelId() )
    cmd:Execute()

    return true, ""
end

buy_menu = Spawnatron()