class 'cInventoryFX'

function cInventoryFX:__init()

    Network:Subscribe("InventoryFX/ParachuteBreak", self, self.ParachuteBreak)
    Network:Subscribe("InventoryFX/GrapplehookBreak", self, self.GrapplehookBreak)
end

function cInventoryFX:GrapplehookBreak(args)
    if not IsValid(args.player) then return end

    ClientEffect.Play(AssetLocation.Game, {
        position = args.player:GetBonePosition("ragdoll_LeftHand"),
        angle = args.player:GetBoneAngle("ragdoll_LeftHand"),
        effect_id = 28
    })
    
    ClientEffect.Play(AssetLocation.Game, {
        position = args.player:GetBonePosition("ragdoll_LeftHand"),
        angle = args.player:GetBoneAngle("ragdoll_LeftHand"),
        effect_id = 11
    })

    
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 15,
        sound_id = 14,
        position = args.player:GetBonePosition("ragdoll_LeftHand"),
        angle = Angle()
    })

    sound:SetParameter(0,0)
    sound:SetParameter(1,0.75)
    
end

function cInventoryFX:ParachuteBreak(args)
    if not IsValid(args.player) then return end

    ClientEffect.Play(AssetLocation.Game, {
        position = args.player:GetBonePosition("ragdoll_Spine") + args.player:GetBoneAngle("ragdoll_Spine") * Vector3(0, 4, 0),
        angle = args.player:GetBoneAngle("ragdoll_Spine"),
        effect_id = 149
    })
    
    ClientEffect.Play(AssetLocation.Game, {
        position = args.player:GetBonePosition("ragdoll_Spine") + args.player:GetBoneAngle("ragdoll_Spine") * Vector3(-2, 4, 0),
        angle = args.player:GetBoneAngle("ragdoll_Spine"),
        effect_id = 149
    })
    
    ClientEffect.Play(AssetLocation.Game, {
        position = args.player:GetBonePosition("ragdoll_Spine") + args.player:GetBoneAngle("ragdoll_Spine") * Vector3(2, 4, 0),
        angle = args.player:GetBoneAngle("ragdoll_Spine"),
        effect_id = 149
    })
end

cInventoryFX = cInventoryFX()