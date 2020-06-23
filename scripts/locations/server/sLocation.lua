class 'sLocation'

function sLocation:__init(args)

    assert(args.name, "missing name")
    assert(args.radius, "missing radius")
    assert(args.center, "missing center")

    self.name = args.name

    self.radius = args.radius
    self.center = args.center

    self.objects = args.objects or {} -- position, angle, model, collision

end

-- Called during building to update the location after placing an object
function sLocation:AddObject(args)

    if not BUILDING_ENABLED then return end

    if args.position:Distance(self.center) > self.radius then
        Chat:Broadcast("Attempted to place object outside of location!", Color.Red)
        return
    end

    table.insert(self.objects, args)

    -- Sync newly placed object to everyone
    Network:Broadcast("locations/AddObjectToLocation", {
        name = self.name,
        object = args
    })
end

function sLocation:GetSyncData()
    return {
        name = self.name,
        radius = self.radius,
        center = self.center,
        objects = self.objects
    }
end