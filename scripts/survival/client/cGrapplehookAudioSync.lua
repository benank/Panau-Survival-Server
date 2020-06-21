class 'GrapplehookAudioSync'

function GrapplehookAudioSync:__init()

    self.fire_timer = Timer()
    self.hit_timer = Timer()
    self.ray = nil
    
    Events:Subscribe("FireGrapplehook", self, self.FireGrapplehook)
    Events:Subscribe("FireGrapplehookPre", self, self.FireGrapplehookPre)
    Events:Subscribe("FireGrapplehookHit", self, self.FireGrapplehookHit)

    Network:Subscribe("SyncedGrapplehookSound", self, self.SyncedGrapplehookSound)
end

function GrapplehookAudioSync:FireGrapplehookPre()
    self.ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 1024)
end

function GrapplehookAudioSync:SyncedGrapplehookSound(args)

    if Camera:GetPosition():Distance(args.position) > 100 then return end

    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        angle = Angle(),
        effect_id = args.sound
    })

end

function GrapplehookAudioSync:FireGrapplehook()
    if self.fire_timer:GetSeconds() > 0.5 then
        Network:Send("FireGrapplehookSound", {position = LocalPlayer:GetBonePosition("ragdoll_AttachHandLeft")})
        self.fire_timer:Restart()
    end
end

function GrapplehookAudioSync:FireGrapplehookHit()
    if self.ray.position and self.ray.distance < 1024 and self.hit_timer:GetSeconds() > 0.5 then
        Network:Send("FireGrapplehookHitSound", {position = self.ray.position})
        self.hit_timer:Restart()
        self.ray = nil
    end
end

GrapplehookAudioSync = GrapplehookAudioSync()