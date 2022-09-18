class 'cDroneContainer'

function cDroneContainer:__init()

    self.cso_id_to_drone = {}

    Events:Subscribe("drones/UpdateDroneCSO", self, self.CreateDroneCSO)
    Events:Subscribe("drones/CreateDroneCSO", self, self.CreateDroneCSO)
    Events:Subscribe("drones/RemoveDroneCSO", self, self.DestroyDroneCSO)

    Events:Fire("drones/RefreshDroneCSOs")

end
MeasureMemory("items")
function cDroneContainer:CSOIdToDrone(cso_id)
    return self.cso_id_to_drone[cso_id]
end

function cDroneContainer:CreateDroneCSO(args)
    self.cso_id_to_drone[args.cso_id] = args
end

function cDroneContainer:DestroyDroneCSO(args)
    self.cso_id_to_drone[args.cso_id] = nil
end

cDroneContainer = cDroneContainer()