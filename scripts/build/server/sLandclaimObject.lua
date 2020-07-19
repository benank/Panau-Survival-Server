class 'sLandclaimObject'

-- Data container for objects within landclaims
function sLandclaimObject:__init(args)

    self.model = args.model
    self.collision = args.collision
    self.position = args.position
    self.angle = args.angle
    self.health = args.health
    self.custom_data = args.custom_data -- Special custom data for certain objects

end

function sLandclaimObject:Serialize()

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