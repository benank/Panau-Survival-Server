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

function cLocation:AddOrUpdateObject(args)

    if args.object.object_id and IsValid(self.objects[args.object.object_id]) then
        self.objects[args.object.object_id]:Remove()
    end

    self:SpawnObject(args.object, args.object.object_id)

end

function cLocation:RemoveObject(args)
    if not self.objects[args.object_id] then return end

    if IsValid(self.objects[args.object_id]) then
        self.objects[args.object_id]:Remove()
    end

    self.objects[args.object_id] = nil
end

function cLocation:SpawnObject(args, index)

    local object = ClientStaticObject.Create({
        position = args.position,
        angle = args.angle,
        model = args.model,
        collision = args.collision
    })

    object:SetValue("LocationName", self.name)
    object:SetValue("ObjectIndex", index)

    self.objects[index] = object

end

function cLocation:SpawnObjects()

    if self.spawning or self.spawned then return end

    self.spawning = true

    Thread(function()
    
        for index, object_data in pairs(self.object_data) do

            self:SpawnObject(object_data, index)
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