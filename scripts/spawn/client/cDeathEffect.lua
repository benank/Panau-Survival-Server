local pos = Vector3()
Network:Subscribe("PlayerDiedEffect", function()
    ClientEffect.Play(AssetLocation.Game, {
        position = Vector3(-10415.34, 220.45, -2997.92),
        angle = Angle(),
        effect_id = 137
    })
end)