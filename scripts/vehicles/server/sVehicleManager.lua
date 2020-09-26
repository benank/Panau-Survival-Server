local insert = table.insert
local random = math.random

class 'sVehicleManager'

function sVehicleManager:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS vehicles (vehicle_id INTEGER PRIMARY KEY AUTOINCREMENT, model_id INTEGER, pos VARCHAR, angle VARCHAR, col1 VARCHAR, col2 VARCHAR, decal VARCHAR, template VARCHAR, owner_steamid VARCHAR, health REAL, cost INTEGER, guards INTEGER)")

    self.vehicles = {} -- All vehicles in the server
    self.owned_vehicles = {} -- All owned vehicles in the server

    self.despawning_vehicles = {} -- Owned vehicles that will despawn because the owner got off

    self.spawns = {} -- Spawn positions with their corresponding vehicles and times, etc
    self.spawn_weights = {}

    self.players = {}

    self:SetupSpawnTables()
    self:ReadVehicleSpawnData("spawns/spawns.txt")
    self:SpawnVehicles()

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("LoadFlowFinish", self, self.LoadFlowFinish)
    Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated)
    Events:Subscribe("PlayerExitVehicle", self, self.PlayerExitVehicle)
    Events:Subscribe("PlayerEnterVehicle", self, self.PlayerEnterVehicle)

    Events:Subscribe("MinuteTick", self, self.MinuteTick)
    Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("PlayerChat", self, self.PlayerChat)

    Events:Subscribe("LoadStatus", self, self.LoadStatus)

    Events:Subscribe("Items/PlayerUseVehicleGuard", self, self.PlayerUseVehicleGuard)

    Network:Subscribe("Vehicles/SpawnVehicle", self, self.PlayerSpawnVehicle)
    Network:Subscribe("Vehicles/DeleteVehicle", self, self.PlayerDeleteVehicle)
    Network:Subscribe("Vehicles/TransferVehicle", self, self.TransferVehicle)

    Network:Subscribe("Vehicles/EnterGasStation", self, self.EnterGasStation)
    Network:Subscribe("Vehicles/ExitGasStation", self, self.ExitGasStation)

    Network:Subscribe("Vehicles/VehicleDestroyed", self, self.VehicleDestroyedClient)

    Timer.SetInterval(1000, function()
        self:Tick1000()
    end)


    -- Respawn vehicles loop
    Timer.SetInterval(1000 * 60 * 60, function()
        local random = math.random

        for spawn_type, data_entries in pairs(self.spawns) do
            for index, spawn_data in pairs(data_entries) do

                if not spawn_data.spawned 
                and random() < config.spawn[spawn_type].spawn_chance
                and spawn_data.respawn_timer:GetMinutes() >= config.spawn[spawn_type].respawn_interval then
                    -- Spawn vehicle
                    self:SpawnNaturalVehicle(spawn_type, index)
                end

            end

        end

    end)

    Timer.SetInterval(1000 * 10, function()
        self:CheckForDestroyedVehicles()
    end)

    Timer.SetInterval(1000 * 60, function()
        self:SaveVehicles()
    end)

end

function sVehicleManager:LoadStatus(args)
    if not IsValid(args.player) then return end

    local steam_id = tostring(args.player:GetSteamId())
    for _, vehicle in pairs(self.owned_vehicles) do
        local last_driver_id = vehicle:GetValue("LastDriver")

        if last_driver_id == steam_id and not IsValid(vehicle:GetDriver()) then
            vehicle:SetValue("LastDriver", nil)
            vehicle:SetLinearVelocity(vehicle:GetValue("LastVelo"))
            vehicle:SetValue("LastVelo", nil)
            args.player:EnterVehicle(vehicle, VehicleSeat.Driver)
            return
        end
    end

end

function sVehicleManager:PlayerChat(args)

    if not IsAdmin(args.player) then return end

    local split = args.text:split(" ")

    if split[1] == "/spawnv" and split[2] then

        local model_id = tonumber(split[2])

        if not vCosts[model_id] then
            Chat:Send(args.player, "Vehicle not supported.", Color.Red)
            return
        end
        
        local spawn_args = {}
        spawn_args.position = args.player:GetPosition()
        spawn_args.angle = args.player:GetAngle()
        spawn_args.model_id = model_id

        spawn_args.tone1 = self:GetColorFromHSV(config.colors.default)
        spawn_args.tone2 = spawn_args.tone1 -- Matching tones here so cars look normal. 

        local health = config.spawn.health.min + (config.spawn.health.max - config.spawn.health.min) * random()
        local vehicle = self:SpawnVehicle(spawn_args)
        vehicle:SetHealth(health)
        vehicle:SetStreamDistance(500)

        spawn_args.health = health
        local vehicle_data = self:GenerateVehicleData(spawn_args)

        if tonumber(split[3]) and tonumber(split[3]) >= 0 then
            vehicle_data.cost = tonumber(split[3])
        end
            
        vehicle_data.health = vehicle:GetHealth()
        vehicle_data.position = vehicle:GetPosition()
        vehicle_data.model_id = vehicle:GetModelId()
        vehicle_data.spawned = true
        vehicle_data.vehicle = vehicle

        vehicle:SetNetworkValue("VehicleData", vehicle_data)
        self.vehicles[vehicle:GetId()] = vehicle

    end

end

function sVehicleManager:PlayerPerksUpdated(args)
    local old_max_vehicles = args.player:GetValue("MaxVehicles")
    local new_max_vehicles = self:GetPlayerMaxVehicles(args.player)

    if old_max_vehicles ~= new_max_vehicles and old_max_vehicles then
        Chat:Send(args.player, string.format("You can now own up to %d vehicles!", new_max_vehicles), Color(0, 255, 255))
    end

    args.player:SetNetworkValue("MaxVehicles", new_max_vehicles)
end

function sVehicleManager:GetPlayerMaxVehicles(player)

    local perks = player:GetValue("Perks")

    if not perks then return 0 end

    local new_max_vehicles = config.player_max_vehicles_base

    for perk_id, bonus in pairs(config.player_max_vehicles) do
        if perks.unlocked_perks[perk_id] then
            new_max_vehicles = new_max_vehicles + bonus
        end
    end

    return new_max_vehicles

end

-- Called every minute, saves all owned vehicles in the server
function sVehicleManager:SaveVehicles()

    local seconds = Server:GetElapsedSeconds()

    for id, v in pairs(self.owned_vehicles) do
        if IsValid(v) then

            local last_update = v:GetValue("VehicleLastUpdate")

            if last_update and seconds - last_update >= 60 then
                self:SaveVehicle(v)
            end

            v:SetValue("VehicleLastUpdate", seconds)
        end
    end

end

function sVehicleManager:PlayerUseVehicleGuard(args)

    local vehicle_data = args.vehicle:GetValue("VehicleData")

    if vehicle_data.guards >= config.max_vehicle_guards then
        Chat:Send(args.player, "This vehicle already has the maximum amount of guards!", Color.Red)

        self:GivePlayerVehicleGuard(args.player)

        return
    end

    local player_owned_vehicles = args.player:GetValue("OwnedVehicles")
    
    if not player_owned_vehicles[vehicle_data.vehicle_id] then
        Chat:Send(player, "You can only use this item on a vehicle that you own!", Color.Red)

        self:GivePlayerVehicleGuard(args.player)

        return
    end


    vehicle_data.guards = vehicle_data.guards + 1

    args.vehicle:SetNetworkValue("VehicleData", vehicle_data)
    self:SaveVehicle(args.vehicle)

    Chat:Send(args.player, string.format("Vehicle guard equipped. (%d/%d)", vehicle_data.guards, config.max_vehicle_guards), Color.Green)

    local msg = string.format("Player %s [%s] added vehicle guard to vehicle %d", 
        args.player:GetName(), args.player:GetSteamId(), vehicle_data.vehicle_id)
    Events:Fire("Discord", {
        channel = "Vehicles",
        content = msg
    })

end

function sVehicleManager:GivePlayerVehicleGuard(player)
    
    local item = deepcopy(Items_indexed["Vehicle Guard"])
    item.amount = 1

    Inventory.AddItem({
        item = item,
        player = player
    })

end

function sVehicleManager:VehicleDestroyed(vehicle, vehicle_data_input)

    -- If vehicle was not passed in, then vehicle_data was passed in
    local vehicle_data = IsValid(vehicle) and vehicle:GetValue("VehicleData") or vehicle_data_input
    vehicle_data.name = Vehicle.GetNameByModelId(vehicle_data.model_id)
    local last_damaged = vehicle:GetValue("LastDamaged")

    -- If this vehicle was owned by someone
    if vehicle_data.vehicle_id then

        self.despawning_vehicles[vehicle_data.vehicle_id] = nil
        self.owned_vehicles[vehicle_data.vehicle_id] = nil

        local cmd = SQL:Command("DELETE FROM vehicles WHERE vehicle_id = (?)")
        cmd:Bind(1, vehicle_data.vehicle_id)
        cmd:Execute()


        local owner = nil

        for p in Server:GetPlayers() do
            if tostring(p:GetSteamId()) == vehicle_data.owner_steamid then
                owner = p
                break
            end
        end

        -- Owner is online
        if IsValid(owner) then

            local player_owned_vehicles = owner:GetValue("OwnedVehicles")
            player_owned_vehicles[vehicle_data.vehicle_id] = nil
            owner:SetValue("OwnedVehicles", player_owned_vehicles)
        
            self.owned_vehicles[vehicle_data.vehicle_id] = nil
        
            self:SyncPlayerOwnedVehicles(owner)

        end

        local additional_info = ""

        if last_damaged then
            additional_info = string.format("by %s [Weapon: %s]", last_damaged.name, last_damaged.weapon_name)
        end
        
        if IsValid(vehicle) then
            Events:Fire("SendPlayerPersistentMessage", {
                steam_id = vehicle_data.owner_steamid,
                message = string.format("Your %s was destroyed %s", vehicle_data.name, additional_info),
                color = Color.Red
            })
        end

        Events:Fire("Discord", {
            channel = "Vehicles",
            content = string.format("[%s]'s %s [ID: %s] was destroyed %s", 
                vehicle_data.owner_steamid, vehicle_data.name, vehicle_data.vehicle_id, additional_info)
        })

    elseif vehicle_data.spawn_type then

        -- Add to respawn list if not owned
        self.spawns[vehicle_data.spawn_type][vehicle_data.spawn_index].spawned = false
        self.spawns[vehicle_data.spawn_type][vehicle_data.spawn_index].respawn_timer:Restart()

    end

    if IsValid(vehicle) then
        vehicle:Remove()
    end

end

function sVehicleManager:VehicleDestroyedClient(args, player)
    local vehicle = args.vehicle

    if not IsValid(vehicle) or vehicle:GetValue("Destroyed") then return end

    vehicle:SetNetworkValue("Destroyed", true)
    vehicle:SetHealth(0.1)
end

function sVehicleManager:CheckForDestroyedVehicles()

    for id, vehicle in pairs(self.vehicles) do

        if IsValid(vehicle) and vehicle:GetHealth() <= 0.2 and not vehicle:GetValue("Remove") then
            vehicle:SetValue("Remove", true)
        elseif IsValid(vehicle) and vehicle:GetValue("Remove") then
            -- Remove vehicle
            self:VehicleDestroyed(vehicle)
            self.vehicles[id] = nil
        end

    end

end

function sVehicleManager:EnterGasStation(args, player)

    if not args.index then return end

    local station_pos = gasStations[args.index]

    if not station_pos then return end

    if not player:InVehicle() then return end

    local dist = station_pos:Distance(player:GetVehicle():GetPosition())
    if dist < config.gas_station_radius then
        player:GetVehicle():SetValue("GasStationIndex", args.index)
        player:GetVehicle():SetValue("InGasStation", true)
    end

end

function sVehicleManager:ExitGasStation(args, player)

    if not player:GetVehicle() then return end

    player:GetVehicle():SetValue("GasStationIndex", nil)
    player:GetVehicle():SetValue("InGasStation", nil)

end

function sVehicleManager:Tick1000()
    -- Every 1000 ms, heal vehicles that are at gas stations

    for id, vehicle in pairs(self.owned_vehicles) do

        if IsValid(vehicle) 
        and vehicle:GetValue("InGasStation") 
        and vehicle:GetHealth() < 1 then

            local speed = math.abs(math.floor(vehicle:GetLinearVelocity():Length()))
            local index = vehicle:GetValue("GasStationIndex")

            if vehicle:GetPosition():Distance(gasStations[index]) > config.gas_station_radius then
                vehicle:SetValue("InGasStation", nil)
                vehicle:SetValue("GasStationIndex", nil)
            elseif speed < 1 then
                local hp = math.min(1, vehicle:GetHealth() + config.gas_station_repair_per_second)
                vehicle:SetHealth(hp)
            end

        end

    end

end

function sVehicleManager:MinuteTick()
    for id, time in pairs(self.despawning_vehicles) do

        if count_table(self.owned_vehicles[id]:GetOccupants()) > 0 then
            -- Friend is using vehicle, restart timer
            self.despawning_vehicles[id] = Server:GetElapsedSeconds()

        elseif Server:GetElapsedSeconds() - time >= config.owned_despawn_time * 60 then
            -- Remove vehicle from game
            self.despawning_vehicles[id] = nil

            local vehicle_id = self.owned_vehicles[id]:GetId()
            self.owned_vehicles[id]:Remove()
            self.owned_vehicles[id] = nil

            self.vehicles[vehicle_id] = nil

        end

    end

end

function sVehicleManager:PlayerJoin(args)
    self.players[tostring(args.player:GetSteamId())] = args.player
end

function sVehicleManager:PlayerQuit(args)

    if args.player:InVehicle() then
        local vehicle = args.player:GetVehicle()
        local driver = vehicle:GetDriver()

        if IsValid(driver) and driver == args.player then
            vehicle:SetValue("LastDriver", tostring(args.player:GetSteamId()))
            vehicle:SetValue("LastVelo", vehicle:GetLinearVelocity())
        end
    end

    self.players[tostring(args.player:GetSteamId())] = nil

    local vehicles = args.player:GetValue("OwnedVehicles")
    if not vehicles then return end

    for id, vehicle_data in pairs(vehicles) do
        if IsValid(vehicle_data.vehicle) then
            self:SaveVehicle(vehicle_data.vehicle, args.player)
            self.despawning_vehicles[id] = Server:GetElapsedSeconds()
        end
    end

end

function sVehicleManager:PlayerExitVehicle(args)

    args.vehicle:SetStreamDistance(500)

    local vehicle_data = args.vehicle:GetValue("VehicleData")
    if not vehicle_data then return end

    if vehicle_data.vehicle_id then
        -- Vehicle is owned, update it
        self:SaveVehicle(args.vehicle)

        -- If a friend is using the vehicle, restart the timer
        if self.despawning_vehicles[vehicle_data.vehicle_id] then
            self.despawning_vehicles[vehicle_data.vehicle_id] = Server:GetElapsedSeconds()
        end
    end
end

function sVehicleManager:TransferVehicle(args, player)

    if not args.id then return end
    if not args.vehicle_id then return end

    local target_player = nil

    for p in Server:GetPlayers() do
        if tostring(p:GetSteamId()) == args.id then
            target_player = p
            break
        end
    end

    if not IsValid(target_player) then
        Chat:Send(player, "Player not found!", Color.Red)
        return
    end

    -- Valid player, now transfer vehicle
    local player_owned_vehicles = player:GetValue("OwnedVehicles")
    local target_owned_vehicles = target_player:GetValue("OwnedVehicles")

    local vehicle_data = player_owned_vehicles[args.vehicle_id]

    if count_table(target_owned_vehicles) >= target_player:GetValue("MaxVehicles") then
        Chat:Send(player, "Vehicle transfer failed. Target player has too many vehicles!", Color.Red)
        return
    end

    if not vehicle_data then
        Chat:Send(player, "Vehicle transfer failed. Vehicle ID mismatch.", Color.Red)
        return
    end

    -- Remove vehicle from old owner
    player_owned_vehicles[args.vehicle_id] = nil
    player:SetValue("OwnedVehicles", player_owned_vehicles)
    self:SyncPlayerOwnedVehicles(player)

    -- Now add vehicle to new owner
    vehicle_data.owner_steamid = args.id

    -- Vehicle is live, update its vehicle data
    if IsValid(vehicle_data.vehicle) then

        vehicle_data.vehicle:SetNetworkValue("VehicleData", vehicle_data)

    end

    -- Now transfer the vehicle
    self:SaveVehicle(vehicle_data.vehicle, target_player, vehicle_data)

    local vehicle_name = Vehicle.GetNameByModelId(vehicle_data.model_id)

    Chat:Send(player, string.format("Successfully transferred %s to %s. (%d/%d)", 
    vehicle_name, target_player:GetName(), count_table(player_owned_vehicles), player:GetValue("MaxVehicles")), Color.Green)

    Chat:Send(target_player, string.format("%s transferred %s to you. (%d/%d)", 
        player:GetName(), vehicle_name, count_table(target_owned_vehicles) + 1, target_player:GetValue("MaxVehicles")), Color.Green)

    local msg = string.format("Player %s [%s] transferred vehicle %d to %s [%s]", 
        player:GetName(), player:GetSteamId(), vehicle_data.vehicle_id, target_player:GetName(), target_player:GetSteamId())
    Events:Fire("Discord", {
        channel = "Vehicles",
        content = msg
    })

end

function sVehicleManager:PlayerSpawnVehicle(args, player)

    local player_owned_vehicles = player:GetValue("OwnedVehicles")
    args.vehicle_id = tonumber(args.vehicle_id)

    local vehicle_data = player_owned_vehicles[args.vehicle_id]

    if not vehicle_data then return end
    if vehicle_data.spawned then return end

    local spawn_args = deepcopy(vehicle_data)
    
    spawn_args.tone1 = vehicle_data.col1
    spawn_args.tone2 = vehicle_data.col2

    local vehicle = self:SpawnVehicle(spawn_args)
    vehicle:SetHealth(vehicle_data.health)

    vehicle_data.spawned = true
    vehicle_data.vehicle = vehicle

    player_owned_vehicles[args.vehicle_id] = vehicle_data

    self.owned_vehicles[args.vehicle_id] = vehicle

    vehicle:SetNetworkValue("VehicleData", vehicle_data)
    player:SetValue("OwnedVehicles", player_owned_vehicles)
    self.vehicles[vehicle:GetId()] = vehicle

    Timer.SetTimeout(3000, function()
        self:SyncPlayerOwnedVehicles(player)
    end)
    

    local msg = string.format("Player %s [%s] spawned vehicle %d", 
        player:GetName(), player:GetSteamId(), args.vehicle_id)
    Events:Fire("Discord", {
        channel = "Vehicles",
        content = msg
    })

end

function sVehicleManager:PlayerDeleteVehicle(args, player)
    if not args.vehicle_id then return end

    args.vehicle_id = tonumber(args.vehicle_id)
    
    local player_owned_vehicles = player:GetValue("OwnedVehicles")

    local vehicle_data = player_owned_vehicles[args.vehicle_id]

    if not vehicle_data then return end
    
    local cmd = SQL:Command("DELETE FROM vehicles WHERE vehicle_id = (?)")
    cmd:Bind(1, args.vehicle_id)
    cmd:Execute()

    if IsValid(vehicle_data.vehicle) then
        vehicle_data.vehicle:Remove()
    end

    player_owned_vehicles[args.vehicle_id] = nil
    player:SetValue("OwnedVehicles", player_owned_vehicles)

    self.owned_vehicles[args.vehicle_id] = nil

    self:SyncPlayerOwnedVehicles(player)

    Chat:Send(player, string.format("Vehicle deleted. (%s/%s)", 
        tostring(count_table(player_owned_vehicles)), tostring(player:GetValue("MaxVehicles"))), Color.Green)

    local msg = string.format("Player %s [%s] deleted vehicle %d", 
        player:GetName(), player:GetSteamId(), args.vehicle_id)
    Events:Fire("Discord", {
        channel = "Vehicles",
        content = msg
    })

end


function sVehicleManager:PlayerEnterVehicle(args)

    args.vehicle:SetStreamDistance(1000)

    local data = args.vehicle:GetValue("VehicleData")
    args.data = data

    if data.owner_steamid ~= tostring(args.player:GetSteamId()) 
    and not AreFriends(args.player, data.owner_steamid) then
        -- If this is not the owner and they are not a friend of the owner
        self:TryBuyVehicle(args)
    else
        -- This is an owned vehicle, so update it in the DB
        self:SaveVehicle(args.vehicle)

        -- If a friend is using the vehicle, restart the timer
        if self.despawning_vehicles[data.vehicle_id] then
            self.despawning_vehicles[data.vehicle_id] = Server:GetElapsedSeconds()
        end
    end

end

-- When a player enters an unowned vehicle or owned (not by a friend or themself)
function sVehicleManager:TryBuyVehicle(args)

    local player_lockpicks = Inventory.GetNumOfItem({player = args.player, item_name = "Lockpick"})
    local owned_vehicles = args.player:GetValue("OwnedVehicles")

    if not player_lockpicks or not args.data.cost or player_lockpicks < args.data.cost then
        Chat:Send(args.player, "You do not have enough lockpicks to purchase this vehicle!", Color.Red)
        self:RemovePlayerFromVehicle(args)
        self:RestoreOldDriverIfExists(args)
        args.vehicle:SetLinearVelocity(Vector3.Zero)
        return
    end

    if count_table(owned_vehicles) >= args.player:GetValue("MaxVehicles") then
        Chat:Send(args.player, "You already own the maximum amount of vehicles!", Color.Red)
        self:RemovePlayerFromVehicle(args)
        self:RestoreOldDriverIfExists(args)
        args.vehicle:SetLinearVelocity(Vector3.Zero)
        return
    end

    -- If they tried to steal it while there was someone inside
    if IsValid(args.old_driver) then
        self:RemovePlayerFromVehicle(args)
        self:RestoreOldDriverIfExists(args)
        args.vehicle:SetLinearVelocity(Vector3.Zero)
        return
    end

    local orig_cost = args.data.cost

    if args.data.cost > 0 then
        local item_cost = CreateItem({
            name = "Lockpick",
            amount = args.data.cost
        })
        
        Inventory.RemoveItem({
            item = item_cost:GetSyncObject(),
            player = args.player
        })
    end

    if args.data.guards > 0 then
        args.data.guards = args.data.guards - 1

        Events:Fire("HitDetection/VehicleGuardActivate", {
            player = args.player,
            attacker_id = args.data.owner_steamid
        })

        args.vehicle:SetNetworkValue("VehicleData", args.data)

        local owner = nil

        for p in Server:GetPlayers() do
            if tostring(p:GetSteamId()) == args.data.owner_steamid then
                owner = p
                break
            end
        end

        self:SaveVehicle(args.vehicle, owner)

        Network:Send(args.player, "Vehicles/VehicleGuardActivate", {position = args.player:GetPosition()})
        Network:SendNearby(args.player, "Vehicles/VehicleGuardActivate", {position = args.player:GetPosition()})

        return
    end

    if args.data.vehicle_id then
        owned_vehicles[args.data.vehicle_id] = args.data
        args.player:SetValue("OwnedVehicles", owned_vehicles)
        self:SyncPlayerOwnedVehicles(args.player)
    end

    -- Check if vehicle is owned or unowned
    if not args.data.owner_steamid then
        -- Not owned previously
        args.data.cost = (vCosts[args.vehicle:GetModelId()] or 50) * config.cost_multiplier_on_purchase

        Chat:Send(args.player, string.format("Vehicle successfully purchased! (%s/%s)", 
            tostring(count_table(owned_vehicles) + 1), tostring(args.player:GetValue("MaxVehicles"))), Color.Green)
    
        local msg = string.format("Player %s [%s] purchased %s for %d", 
            args.player:GetName(), args.player:GetSteamId(), args.vehicle:GetName(), orig_cost)
        Events:Fire("Discord", {
            channel = "Vehicles",
            content = msg
        })
    
    elseif args.data.vehicle_id then
        
        -- Remove vehicle from old owner's list
        local old_owner = nil

        for p in Server:GetPlayers() do
            if tostring(p:GetSteamId()) == args.data.owner_steamid then
                old_owner = p
                break
            end
        end

        if IsValid(old_owner) then
            local player_owned_vehicles = old_owner:GetValue("OwnedVehicles")
            player_owned_vehicles[args.data.vehicle_id] = nil
            old_owner:SetValue("OwnedVehicles", player_owned_vehicles)
            self:SyncPlayerOwnedVehicles(old_owner)
        end

        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = args.data.owner_steamid,
            message = string.format("%s stole your vehicle [%s]", args.player:GetName(), args.vehicle:GetName()),
            color = Color.Red
        })

        Chat:Send(args.player, string.format("Vehicle successfully stolen! (%s/%s)", 
            tostring(count_table(owned_vehicles)), tostring(args.player:GetValue("MaxVehicles"))), Color.Green)
    
        self.despawning_vehicles[args.data.vehicle_id] = nil

        local msg = string.format("Player %s [%s] stole vehicle %d [%s] from [%s] for %d", 
            args.player:GetName(), args.player:GetSteamId(), args.data.vehicle_id, args.vehicle:GetName(), 
            args.data.owner_steamid, orig_cost)
        Events:Fire("Discord", {
            channel = "Vehicles",
            content = msg
        })
    end

    -- Now buy the vehicle
    args.data.owner_steamid = tostring(args.player:GetSteamId())

    args.vehicle:SetNetworkValue("VehicleData", args.data)
    args.vehicle:SetStreamDistance(1000)

    self:SaveVehicle(args.vehicle, args.player)

    if args.data.spawn_index and args.data.spawn_type then
        self.spawns[args.data.spawn_type][args.data.spawn_index].respawn_timer:Restart()
        self.spawns[args.data.spawn_type][args.data.spawn_index].spawned = false
    end

end

function sVehicleManager:RemovePlayerFromVehicle(args)
    args.player:Teleport(args.player:GetPosition(), args.player:GetAngle())
end

-- If the vehicle was somehow hijacked from someone, put old driver back in the vehicle
function sVehicleManager:RestoreOldDriverIfExists(args)
    if args.old_driver then args.old_driver:EnterVehicle(args.vehicle, VehicleSeat.Driver) end
end

function sVehicleManager:LoadFlowFinish(args)

    if not args.player:GetValue("Exp") then
        args.player:SetValue("InventoryWaitingForExp", true)
        return
    end
    
    args.player:SetNetworkValue("MaxVehicles", self:GetPlayerMaxVehicles(args.player))

    local result = SQL:Query("SELECT * FROM vehicles WHERE owner_steamid = (?)")
    result:Bind(1, tostring(args.player:GetSteamId()))
    result = result:Execute()

    local owned_vehicles = {}

    if result and count_table(result) > 0 then
        -- Send player vehicle data
        for i, v in ipairs(result) do
            v.model_id = tonumber(v.model_id)
            v.spawned = false
            v.guards = tonumber(v.guards)
            v.cost = tonumber(v.cost)
            v.position = self:DeserializePosition(v.pos)
            v.angle = self:DeserializeAngle(v.angle)
            v.col1 = self:DeserializeColor(v.col1)
            v.col2 = self:DeserializeColor(v.col2)
            v.vehicle_id = tonumber(v.vehicle_id)
            v.health = tonumber(v.health)
            owned_vehicles[v.vehicle_id] = v

            if IsValid(self.owned_vehicles[v.vehicle_id]) then
                v.spawned = true
                v.vehicle = self.owned_vehicles[v.vehicle_id]
                self.despawning_vehicles[v.vehicle_id] = nil
            end
        end
    end

    args.player:SetValue("OwnedVehicles", owned_vehicles)
    self:SyncPlayerOwnedVehicles(args.player)

end

-- Syncs a player's owned vehicles to them for use in the vehicle menu
function sVehicleManager:SyncPlayerOwnedVehicles(player)
    if not IsValid(player) then return end
    Network:Send(player, "Vehicles/SyncOwnedVehicles", player:GetValue("OwnedVehicles"))
end

-- Read spawn data from file
function sVehicleManager:ReadVehicleSpawnData(filename)

    print("Opening " .. filename)
    local file = io.open(filename, "r")

    if not file then
        print("No spawns.txt, aborting loading of spawns")
        return
    end

    -- For each line, handle appropriately
    for line in file:lines() do
        if line:sub(1,1) == "X" then
            self:ParseVehicle(line)
		end
    end
    
    file:close()

end

function sVehicleManager:ParseVehicle(line)
    -- Remove start, spaces
	line = string.trim(line)
    line = line:gsub("X", "")
    line = line:gsub(" ", "")

    -- Split into tokens
    local tokens = line:split(",")

    -- Create vector
    local vector = Vector3(tonumber(tokens[1]),tonumber(tokens[2]),tonumber(tokens[3]))
    local angle  = Angle(tonumber(tokens[4]),tonumber(tokens[5]),tonumber(tokens[6]))

    -- Save to table
    if not self.spawns[tokens[7]] then
        print("Unable to find vehicle type " .. tokens[7])
        return
    end

    insert(self.spawns[tokens[7]], {position = vector, angle = angle, spawned = false, respawn_timer = Timer()})
	
end

function sVehicleManager:SetupSpawnTables()

    for k,v in pairs(vIds) do
        self.spawns[k] = {}

        self.spawn_weights[k] = {total = 0, individual = {}}

        for id, weight in pairs(v) do
            self.spawn_weights[k].total = self.spawn_weights[k].total + weight
            insert(self.spawn_weights[k].individual, {id = id, weight = self.spawn_weights[k].total}) -- Running totals
        end
    end

end

-- Spawns all vehicles at their spawns around the world when the server starts up
function sVehicleManager:SpawnVehicles()

    -- Start a timer to measure load time
    local timer = Timer()
    local cnt = 0
    local total_cnt = 0

    local random = math.random

    for spawn_type, data_entries in pairs(self.spawns) do
        for index, spawn_data in pairs(data_entries) do

            if random() < config.spawn[spawn_type].spawn_chance then
                self:SpawnNaturalVehicle(spawn_type, index)
                cnt = cnt + 1
            end
            
            total_cnt = total_cnt + 1

        end
    end

    print(string.format("Spawned %d/%d vehicles, %.02f seconds", cnt, total_cnt, timer:GetSeconds()))

end

-- Spawns/respawns a natural vehicle 
function sVehicleManager:SpawnNaturalVehicle(spawn_type, index)

    local spawn_data = self.spawns[spawn_type][index]
    self.spawns[spawn_type][index].spawned = true

    local spawn_args = self:GetVehicleFromType(spawn_type)
    spawn_args.position = spawn_data.position
    spawn_args.angle = spawn_data.angle
    
    spawn_args.spawn_type = spawn_type
    
    spawn_args.tone1 = self:GetColorFromHSV(config.colors.default)
    spawn_args.tone2 = spawn_args.tone1 -- Matching tones here so cars look normal. 

    local health = config.spawn.health.min + (config.spawn.health.max - config.spawn.health.min) * random()
    local vehicle = self:SpawnVehicle(spawn_args)
    vehicle:SetHealth(health)
    vehicle:SetStreamDistance(500)

    spawn_args.health = health
    local vehicle_data = self:GenerateVehicleData(spawn_args)
    vehicle_data.health = vehicle:GetHealth()
    vehicle_data.position = vehicle:GetPosition()
    vehicle_data.model_id = vehicle:GetModelId()
    vehicle_data.spawned = true
    vehicle_data.vehicle = vehicle
    vehicle_data.spawn_type = spawn_type
    vehicle_data.spawn_index = index

    vehicle:SetNetworkValue("VehicleData", vehicle_data)
    self.vehicles[vehicle:GetId()] = vehicle

end

function sVehicleManager:GenerateVehicleData(args)

    return 
    {
        cost = self:GetVehicleCost(args),
        owner_steamid = nil,
        vehicle_id = nil,
        guards = 0
    }

end

function sVehicleManager:GetVehicleCost(args)

    local base_cost = vCosts[args.model_id] or 999
    local cost = base_cost * config.spawn.cost_modifier

    cost = cost * args.health -- Scale cost based on health

    if random() < config.spawn.half_off_chance then
        cost = cost * 0.5
    end

    cost = math.ceil(cost)

    return cost

end

function sVehicleManager:GetColorFromHSV(hsv)
    return Color.FromHSV(random(hsv.h_min, hsv.h_max), random(hsv.s_min, hsv.s_max) / 100, random(hsv.v_min, hsv.v_max) / 100)
end

function sVehicleManager:GetVehicleFromType(type)

    local args = {}

    -- First get model id
    local random_num = random()
    local target_weight = self.spawn_weights[type].total * random_num
    for index, data in ipairs(self.spawn_weights[type].individual) do

        if target_weight <= data.weight then
            args.model_id = data.id
            break
        end

    end

    -- Get random decal
    if random() <= config.decal_chance then
        args.decal = table.randomvalue(config.decals)
    end

    -- Now get template, if it exists
    if config.templates[args.model_id] then
        local sum = 0
        local rand = random()

        for template, chance in pairs(config.templates[args.model_id]) do
            sum = sum + chance
            if rand <= sum then
                args.template = template
                break
            end
        end
    end

    return args

end

-- Using a function for now incase we need to do future compatibility stuff
function sVehicleManager:SpawnVehicle(args)
    local v = Vehicle.Create(args)
    return v
end

function sVehicleManager:ModuleUnload()
    for k,v in pairs(self.vehicles) do
        if IsValid(v) then v:Remove() end
    end
end

-- Call this to update/insert a vehicle to SQL. Will automatically assign VehicleData if it does not exist
function sVehicleManager:SaveVehicle(vehicle, player, vehicle_data)

    local vehicle_data = vehicle_data or vehicle:GetValue("VehicleData") -- Vehicle data will always exist
    if not vehicle_data then return end

    if not player then
        player = vehicle_data.owner_steamid and self.players[vehicle_data.owner_steamid] or nil
    end

    local health = IsValid(vehicle) and vehicle:GetHealth() or vehicle_data.health
    if health <= 0.2 then return end

    local cmd = SQL:Command("UPDATE vehicles SET model_id = ?, pos = ?, angle = ?, col1 = ?, col2 = ?, decal = ?, template = ?, owner_steamid = ?, health = ?, cost = ?, guards = ? where vehicle_id = ?")
    if not vehicle_data.vehicle_id and player then -- New vehicle

        if not IsValid(player) then return end -- How can we insert if the player isn't valid
        cmd = SQL:Command("INSERT INTO vehicles (model_id, pos, angle, col1, col2, decal, template, owner_steamid, health, cost, guards) values (?,?,?,?,?,?,?,?,?,?,?)")

        vehicle_data.owner_steamid = tostring(player:GetSteamId())

    end

    if IsValid(vehicle) then

        local color1, color2 = vehicle:GetColors()

        cmd:Bind(1, vehicle:GetModelId())
        cmd:Bind(2, self:SerializePosition(vehicle:GetPosition()))
        cmd:Bind(3, self:SerializeAngle(vehicle:GetAngle()))
        cmd:Bind(4, self:SerializeColor(color1))
        cmd:Bind(5, self:SerializeColor(color2))
        cmd:Bind(6, tostring(vehicle:GetDecal()))
        cmd:Bind(7, tostring(vehicle:GetTemplate()))
        cmd:Bind(9, math.round(vehicle:GetHealth(), 5))
        
    else

        cmd:Bind(1, vehicle_data.model_id)
        cmd:Bind(2, self:SerializePosition(vehicle_data.position))
        cmd:Bind(3, self:SerializeAngle(vehicle_data.angle))
        cmd:Bind(4, self:SerializeColor(vehicle_data.col1))
        cmd:Bind(5, self:SerializeColor(vehicle_data.col2))
        cmd:Bind(6, tostring(vehicle_data.decal))
        cmd:Bind(7, tostring(vehicle_data.template))
        cmd:Bind(9, vehicle_data.health)
        
    end

	cmd:Bind(8, vehicle_data.owner_steamid)
	cmd:Bind(10, vehicle_data.cost)
    cmd:Bind(11, vehicle_data.guards)
    
    -- If we are updating the vehicle
    if vehicle_data.vehicle_id then
        cmd:Bind(12, tonumber(vehicle_data.vehicle_id))
    end

    cmd:Execute()

    -- Newly purchased vehicle
    if not vehicle_data.vehicle_id then
        cmd = SQL:Query("SELECT last_insert_rowid() as insert_id FROM vehicles")
        local result = cmd:Execute()
        vehicle_data.vehicle_id = tonumber(result[1].insert_id)
    end

    if IsValid(vehicle) then
        vehicle_data.spawned = true
        vehicle_data.position = vehicle:GetPosition()
        vehicle:SetNetworkValue("VehicleData", vehicle_data)
        self.owned_vehicles[vehicle_data.vehicle_id] = vehicle
    end

    if IsValid(player) then
        local owned_vehicles = player:GetValue("OwnedVehicles")
        if not owned_vehicles then return end
        owned_vehicles[vehicle_data.vehicle_id] = vehicle_data
        player:SetValue("OwnedVehicles", owned_vehicles)
        self:SyncPlayerOwnedVehicles(player)
    end

end

function sVehicleManager:SerializePosition(pos)
    return math.round(pos.x, 2) .. "," .. math.round(pos.y, 2) .. "," .. math.round(pos.z, 2)
end

function sVehicleManager:DeserializePosition(pos)
    local split = pos:split(",")
    return Vector3(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
end

function sVehicleManager:SerializeAngle(ang)
    return math.round(ang.x, 5) .. "," .. math.round(ang.y, 5) .. "," .. math.round(ang.z, 5) .. "," .. math.round(ang.w, 5)
end

function sVehicleManager:DeserializeAngle(ang)
    local split = ang:split(",")
    return Angle(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]), tonumber(split[4]))
end

function sVehicleManager:SerializeColor(col)
    return col.r .. "," .. col.g .. "," .. col.b
end

function sVehicleManager:DeserializeColor(col)
    local split = col:split(",")
    return Color(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
end

VehicleManager = sVehicleManager()