class 'cStashPlacement'

function cStashPlacement:__init()

    Network:Subscribe("items/StartStashPlacement", self, self.StartStashPlacement)

end

function cStashPlacement:StartStashPlacement(args)

    Events:Fire("build/StartObjectPlacement", {
        model = args.model_data.model,
        disable_walls = true
    })

    self.place_subs = 
    {
        --Events:Subscribe("ObjectPlacerGameRender", self, self.Render),
        Events:Subscribe("build/PlaceObject", self, self.PlaceObject),
        Events:Subscribe("build/CancelObjectPlacement", self, self.CancelObjectPlacement)
    }

    self.placing_stash = true
end

function cStashPlacement:PlaceObject(args)
    if not self.placing_stash then return end

    if args.entity and args.entity.__type == "ClientStaticObject" then
        args.model = args.entity:GetModel()
    else
        args.model = nil
    end

    Network:Send("items/PlaceStash", {
        position = args.position,
        angle = args.angle,
        model = args.model
    })
    self:StopPlacement()
end

function cStashPlacement:CancelObjectPlacement()
    Network:Send("items/CancelStashPlacement")
    self:StopPlacement()
end

function cStashPlacement:StopPlacement()
    for k, v in pairs(self.place_subs) do
        Events:Unsubscribe(v)
    end

    self.place_subs = {}
    self.placing_stash = false
end

cStashPlacement = cStashPlacement()