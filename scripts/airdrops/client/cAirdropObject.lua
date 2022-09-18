class 'cAirdropObject'
MeasureMemory("airdrops")
-- Class for handling all the objects that comprise the actual airdrop container
function cAirdropObject:__init(args)

    self.position = args.position
    self.angle = args.angle

    self.objects = {}

    self:Create()

end

function cAirdropObject:SetPosition(pos)
    self.position = pos
    for _, object in pairs(self.objects) do
        object:SetPosition(self.position + self.angle * AirdropObjectData[_].offset)
    end
end

function cAirdropObject:RemoveKey(k)
    for key, object in pairs(self.objects) do
        if key:find(k) then
            object:Remove()
            self.objects[key] = nil
        end
    end
end

function cAirdropObject:Create()

    for key, object_data in pairs(AirdropObjectData) do
        self.objects[key] = ClientStaticObject.Create({
            model = object_data.model,
            collision = object_data.collision,
            position = self.position + self.angle * object_data.offset, -- Possibly use angle_offset here
            angle = self.angle * object_data.angle_offset
        })
    end

end

function cAirdropObject:Remove()
    for _, object in pairs(self.objects) do
        if IsValid(object) then
            object:Remove()
        end
    end
end

