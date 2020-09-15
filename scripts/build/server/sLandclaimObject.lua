class 'sLandclaimObject'

-- Data container for objects within landclaims
function sLandclaimObject:__init(args)

    self.id = args.id -- Unique object id per claim, changes every reload
    self.model = args.model
    self.collision = args.collision
    self.position = DeserializePosition(args.position)
    self.angle = args.angle
    self.health = args.health
    self.custom_data = args.custom_data -- Special custom data for certain objects

end

function sLandclaimObject:GetSerializable()
    local data = self:GetSyncObject()
    data.angle = SerializeAngle(data.angle)
    data.position = SerializePosition(data.position)
    return data
end

function sLandclaimObject:GetSyncObject()

    return {
        model = self.model,
        collision = self.collision,
        angle = self.angle,
        position = self.position,
        health = self.health,
        custom_data = self.custom_data
    }

end