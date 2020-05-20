local sound = ClientSound.Create(AssetLocation.Game, {
    bank_id = 8,
    sound_id = 0,
    position = LocalPlayer:GetPosition(),
    angle = Angle()
})

sound:SetParameter(0,0)
sound:SetParameter(1,0)
sound:SetParameter(2,0.75)
