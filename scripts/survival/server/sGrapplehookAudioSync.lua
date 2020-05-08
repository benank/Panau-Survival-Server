class 'GrapplehookAudioSync'

function GrapplehookAudioSync:__init()

    Network:Subscribe("FireGrapplehookSound", self, self.FireGrapplehookSound)
    Network:Subscribe("FireGrapplehookHitSound", self, self.FireGrapplehookHitSound)
end

function GrapplehookAudioSync:FireGrapplehookSound(args, player)
    if not args.position then return end
    Network:SendNearby(player, "SyncedGrapplehookSound", {position = args.position, sound = 214})
end

function GrapplehookAudioSync:FireGrapplehookHitSound(args, player)
    if not args.position then return end
    Network:SendNearby(player, "SyncedGrapplehookSound", {position = args.position, sound = 212})
end

GrapplehookAudioSync = GrapplehookAudioSync()