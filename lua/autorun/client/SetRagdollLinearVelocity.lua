function LocalPlayer:SetRagdollLinearVelocity(v, delay)

    LocalPlayer:SetBaseState(AnimationState.SSkydive)
    LocalPlayer:SetLinearVelocity(v or Vector3())

    Timer.SetTimeout(delay or 70, function()
        LocalPlayer:SetBaseState(AnimationState.SAirborneRagdoll)
    end)

end