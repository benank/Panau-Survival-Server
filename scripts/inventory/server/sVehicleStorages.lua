class 'sVehicleStorages'

function sVehicleStorages:__init()
    
    -- Events for when owned vehicles are created/removed
    Events:Subscribe("VehicleCreated", self, self.VehicleCreated)
    Events:Subscribe("VehicleRemoved", self, self.VehicleRemoved)
    
    Events:Subscribe("PlayerEnteredVehicle", self, self.PlayerEnteredVehicle)
    Events:Subscribe("PlayerExitVehicle", self, self.PlayerExitVehicle)
    
    Events:Subscribe("Vehicles/VehicleItemsHacked", self, self.VehicleItemsHacked)
    
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    Events:Subscribe("ServerStart", self, self.ModuleLoad)
end

function sVehicleStorages:VehicleItemsHacked(args)
    if not IsValid(args.vehicle) then return end
    
    local storage_id = args.vehicle:GetValue("VehicleStorageId")
    if not storage_id then return end
    
    local stash = sStashes.stashes[storage_id]
    if not stash then return end
    
    local vehicle_data = args.vehicle:GetValue("VehicleData")

    if vehicle_data.owner_steamid then
        Events:Fire("SendPlayerPersistentMessage", {
            steam_id = vehicle_data.owner_steamid,
            message = string.format("Your %s vehicle storage was hacked by %s %s", 
                args.vehicle:GetName(), args.player:GetName(), WorldToMapString(args.player:GetPosition())),
            color = Color(200, 0, 0)
        })
    end
    
    if count_table(stash.lootbox.contents) == 0 then
        Chat:Send(args.player, "Successfully hacked into the vehicle\'s storage, but no items were found.", Color.Green)
        return
    end
    
    Chat:Send(args.player, "Successfully hacked into the vehicle\'s storage.", Color.Green)
    
    -- Empty vehicle storage and put all items in dropbox at player's feet
    Events:Fire("Inventory/CreateDropboxExternal", {
        contents = stash.lootbox:GetContentsData(),
        position = args.player:GetPosition(),
        angle = Angle()
    })
    
    local chat_msg = ""
    for index, stack in pairs(stash.lootbox.contents) do
        chat_msg = chat_msg .. string.format("%s (%s)", tostring(stack:GetProperty("name")), tostring(stack:GetAmount()))

        if stack:GetProperty("durable") then
            for _, item in pairs(stack.contents) do
                chat_msg = chat_msg .. string.format(" [%.0f%%]", item.durability / item.max_durability * 100)
            end
        end

        if index < #stash.lootbox.contents then
            chat_msg = chat_msg .. ", "
        end
    end
    
    Events:Fire("Discord", {
        channel = "Inventory",
        content = string.format("%s [%s] hacked vehicle %d [%s] storage %s: %s", 
            args.player:GetName(), tostring(args.player:GetSteamId()), 
            vehicle_data.vehicle_id, tostring(vehicle_data.owner_steamid), WorldToMapString(args.player:GetPosition()), chat_msg)
    })

    stash.lootbox.contents = {}
    stash.lootbox:UpdateToPlayers()
    
end

function sVehicleStorages:ModuleLoad()
    Events:Fire("RefreshVehicleStorages") 
end

function sVehicleStorages:PlayerExitVehicle(args)
    
    local storage_id = args.vehicle:GetValue("VehicleStorageId")
    if not storage_id then return end
    
    local stash = sStashes.stashes[storage_id]
    if not stash then return end
    
    stash.lootbox:CloseBox(args, args.player)
    stash.lootbox:ForceClose(args.player)
    
end

function sVehicleStorages:PlayerEnteredVehicle(args)
    -- Sync lootbox to player
    local storage_id = args.vehicle:GetValue("VehicleStorageId")
    if not storage_id then return end
    
    local stash = sStashes.stashes[storage_id]
    if not stash then return end
    
    stash.lootbox:SyncToPlayer(args.player)
    stash.lootbox.players_opened[tostring(args.player:GetSteamId())] = args.player
    args.player:SetValue("CurrentLootbox", stash.lootbox:GetSyncData(args.player))
end

function sVehicleStorages:GetStashIdFromVehicleId(vehicleId)
    if not vehicleId then
        error("No vehicle id given")
    end
    return string.format("v_%d", vehicleId) 
end

function sVehicleStorages:VehicleCreated(args)
    -- Create a new vehicle storage for the vehicle
    
    local vehicle_data = args.vehicle:GetValue("VehicleData")
    if not vehicle_data then return end

    local lootbox_data = Lootbox.Stashes[Lootbox.Types.Workbench]
    local storage_id = self:GetStashIdFromVehicleId(args.vehicle:GetId())
    local capacity = VehicleStorageCapacities[args.vehicle:GetModelId()] or 1

    local lootbox = sStashes:AddStash({
        id = storage_id,
        position = Vector3(50000, 0, 50000), -- Cell far away to prevent it from being automatically unloaded
        angle = Angle(),
        tier = Lootbox.Types.VehicleStorage,
        contents = {},
        -- owner_id = vehicle_data.owner_steamid,
        owner_id = "VEHICLE",
        health = 1,
        access_mode = lootbox_data.default_access,
        capacity = capacity,
        vehicle = args.vehicle
    })
    
    args.vehicle:SetNetworkValue("VehicleStorageId", storage_id)

end

function sVehicleStorages:VehicleRemoved(args)
    if not IsValid(args.vehicle) then return end
    
    -- Remove the vehicle storage for the vehicle
    local vehicle_storage_id = args.vehicle:GetValue("VehicleStorageId")
    if not vehicle_storage_id then return end
    
    local stash = sStashes.stashes[vehicle_storage_id]
    if not stash then return end
    
    sStashes.stashes_by_uid[stash.lootbox.uid] = nil
    sStashes.stashes[vehicle_storage_id] = nil
    
    stash.lootbox:Remove()
end



sVehicleStorages = sVehicleStorages()