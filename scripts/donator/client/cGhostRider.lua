class 'GhostRider'

function GhostRider:__init(player)

    self.player = player

    self.skull = ClientStaticObject.Create({
        model = "32x34.flz/key040_1-part_d.lod",
        position = Vector3(),
        angle = Angle()
    })

    self.fx = {}

    table.insert(self.fx, {
        effect = ClientEffect.Create(AssetLocation.Game, {
        position = Vector3(),
        angle = Angle(),
        effect_id = 326
        }),
        offset = Vector3(0, -0.1, 0)
    })
end

function GhostRider:Render(args)

    if not IsValid(self.player) then return end

    for k,v in pairs(self.fx) do
        v.effect:SetPosition(self.player:GetBonePosition("ragdoll_Head") + self.player:GetBoneAngle("ragdoll_Head") * v.offset)
    end

    self.skull:SetPosition(self.player:GetBonePosition("ragdoll_Head") + Vector3(0.01, -0.05, 0))
    self.skull:SetAngle(self.player:GetBoneAngle("ragdoll_Head") * Angle(math.pi, 0.2, 0))

end

function GhostRider:Remove()
    for k,v in pairs(self.fx) do v.effect:Remove() end
    self.skull:Remove()
end

