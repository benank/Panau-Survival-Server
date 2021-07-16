class 'sVehicleStorages'

function sVehicleStorages:__init()
    
    -- Events for when owned vehicles are created/removed
    Events:Subscribe("VehicleCreated", self, self.VehicleCreated)
    Events:Subscribe("VehicleRemoved", self, self.VehicleRemoved)
end

function sVehicleStorages:GetStashIdFromVehicleId(vehicleId)
    if not vehicleId then
        error("No vehicle id given")
    end
    return string.format("v_%d", vehicleId) 
end

function sVehicleStorages:VehicleCreated(args)
    -- Create a new vehicle storage for the vehicle
    if args.vehicle:GetValue("VehicleStorageId") then return end
    
    local vehicle_data = args.vehicle:GetValue("VehicleData")
    if not vehicle_data then return end

    local lootbox_data = Lootbox.Stashes[Lootbox.Types.Workbench]
    local storage_id = self:GetStashIdFromVehicleId(vehicle_data.vehicle_id)
    local capacity = VehicleStorageCapacities[args.vehicle:GetModelId()] or 1

    local lootbox = sStashes:AddStash({
        id = storage_id,
        position = Vector3(50000, 0, 50000), -- Cell far away to prevent it from being automatically unloaded
        angle = Angle(),
        tier = Lootbox.Types.VehicleStorage,
        contents = {},
        owner_id = vehicle_data.owner_steamid,
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