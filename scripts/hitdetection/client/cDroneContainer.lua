class 'cDroneContainer'

function cDroneContainer:__init()

    self.cso_id_to_drone_id = {}

    Events:Subscribe("drones/CreateDroneCSO", self, self.CreateDroneCSO)
    Events:Subscribe("drones/RemoveDroneCSO", self, self.DestroyDroneCSO)

end

function cDroneContainer:CSOIdToDrone(cso_id)
    if cso_id and self.cso_id_to_drone_id[cso_id] and IsValid(self.cso_id_to_drone_id[cso_id].cso) then
        return self.cso_id_to_drone_id[cso_id]
    end
end

function cDroneContainer:CreateDroneCSO(args)
    self.cso_id_to_drone_id[args.cso_id] = args
end

function cDroneContainer:DestroyDroneCSO(args)
    self.cso_id_to_drone_id[args.cso_id] = nil
end

cDroneContainer = cDroneContainer()