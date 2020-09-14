class 'sLandclaim'

function sLandclaim:__init(args)

    self.radius = args.radius
    self.position = args.position
    self.owner_id = args.owner_id
    self.name = args.name
    self.expiry_date = args.expiry_date
    self.access_mode = args.access_mode
    self.objects = args.objects
    self.id = args.id

end

-- Called when a player tries to place an object in the landclaim
function sLandclaim:PlaceObject(args, player)

end

-- Called when a a player tries to remove an object in the landclaim
function sLandclaim:RemoveObject(args, player)

end

-- Called when an object on the landclaim is damaged
function sLandclaim:DamageObject(args, player)

end

-- Called when the owner tries to rename the landclaim
function sLandclaim:Rename(name, player)

end

function sLandclaim:SyncToPlayer(player)
    if not IsValid(player) then return end
    Network:Send(player, "build/SyncLandclaim", self:GetSyncObject())
end

function sLandclaim:GetSyncObject()

    return {
        radius = self.radius,
        position = self.position,
        owner_id = self.owner_id,
        name = self.name,
        expiry_date = self.expiry_date,
        access_mode = self.access_mode,
        objects = self.objects,
        id = self.id
    }

end