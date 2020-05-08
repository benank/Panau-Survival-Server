local pos = Vector3(-10415.34, 220.45, -2997.92)
Network:Subscribe("PlayerDiedEffect", function()
    if LocalPlayer:GetPosition():Distance(pos) < 1500 then
        ClientEffect.Play(AssetLocation.Game, {
            position = pos,
            angle = Angle(),
            effect_id = 137
        })
    end
end)