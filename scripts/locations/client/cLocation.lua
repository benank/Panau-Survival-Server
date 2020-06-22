class 'cLocation'

function cLocation:__init(args)
    
    self.name = args.name
    self.object_data = args.objects
    self.radius = args.radius
    self.center = args.center

    self.objects = {} -- Objects that are actually spawned

end

-- Creates all objects
function cLocation:CreateObjects()

end

-- Remove all objects
function cLocation:Remove()
    for _, object in pairs(self.objects) do
        if IsValid(object) then object:Remove() end
    end
end

-- Toggle collision of far objects to reduce lag
function cLocation:ToggleCollisionOfFarObjects()

end