class 'cInventoryFX'

function cInventoryFX:__init()

    Network:Subscribe("InventoryFX/ParachuteBreak", self, self.ParachuteBreak)
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