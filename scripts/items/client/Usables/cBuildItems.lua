class 'cBuildItems'

function cBuildItems:__init(args)

    self.placing_object = false

    Network:Subscribe(var("items/StartObjectPlacement"):get(), self, self.StartObjectPlacement)

end

function cBuildItems:StartObjectPlacement(args)

    Events:Fire("build/StartLandclaimObjectPlacement", {
        model = ItemsConfig.build[args.name].model,
        disable_walls = ItemsConfig.build[args.name].disable_walls == true,
        angle = ItemsConfig.build[args.name].angle,
        offset = ItemsConfig.build[args.name].offset,
        name = args.name
    })

    self.place_subs = 
    {
        Events:Subscribe("build/PlaceLandclaimObject", self, self.PlaceObject),
        Events:Subscribe("build/CancelLandclaimObjectPlacement", self, self.CancelObjectPlacement)
    }
    
    self.placing_object = true
end

function cBuildItems:PlaceObject(args)
    if not self.placing_object then return end

    if args.entity and args.entity.__type == "ClientStaticObject" then
        args.model = args.entity:GetModel()
    end

    Network:Send("items/PlaceLandclaimBuildObject", {
        position = args.position,
        angle = args.angle,
        model = args.model
    })
    self:StopPlacement()
end

function cBuildItems:CancelObjectPlacement()
    Network:Send("items/CancelLandclaimObjectPlacement")
    self:StopPlacement()
end

function cBuildItems:StopPlacement()
    for k, v in pairs(self.place_subs) do
        Events:Unsubscribe(v)
    end

    self.place_subs = {}
    self.placing_object = false
end

cBuildItems = cBuildItems()