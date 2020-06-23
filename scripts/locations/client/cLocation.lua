class 'cLocation'

function cLocation:__init(args)
    
    self.name = args.name
    self.object_data = args.objects
    self.radius = args.radius
    self.center = args.center

    self.objects = {} -- Objects that are actually spawned

    self.spawned = false -- If the objects are spawned
    self.spawning = false -- If the objects are currently spawning

end

function cLocation:SpawnObjects()

    if self.spawning or self.spawned then return end

    _debug("SPAWN OBJECTS")

    self.spawning = true

    Thread(function()
    
        for index, object_data in ipairs(self.object_data) do

            local object = ClientStaticObject.Create({
                position = object_data.position,
                angle = object_data.angle,
                model = object_data.model,
                collision = object_data.collision
            })

            object:SetValue("LocationName", self.name)
            object:SetValue("ObjectIndex", index)

            self.objects[index] = object

            Timer.Sleep(1)

        end


        self.spawned = true
        self.spawning = false

    end)

end

-- Creates all objects
function cLocation:CreateObjects()

end

function cLocation:RemoveAllObjects()

    if not self.spawned then return end
    if self.removing_objects then return end

    _debug("REMOVE OBJECTS")

    self.removing_objects = true

    Thread(function()
    
        for _, object in pairs(self.objects) do
            if IsValid(object) then
                object:Remove()
            end

            Timer.Sleep(1)
        end

        self.objects = {}

        self.spawned = false
        self.removing_objects = false

    end)

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