class 'cExp'

function cExp:__init()

    Events:Subscribe("NetworkObjectValueChange", self, self.NetworkObjectValueChange)
    Events:Subscribe("ModulesLoaded", self, self.ModulesLoaded)

end

function cExp:ModulesLoaded()

    if LocalPlayer:GetValue("Perks") then
        Events:Fire("PlayerPerksUpdated", args.value)
    end

    if LocalPlayer:GetValue("Exp") then
        Events:Fire("PlayerExpUpdated", args.value)
    end

end

function cExp:NetworkObjectValueChange(args)

    if args.object.__type ~= "LocalPlayer" then return end

    self:CheckForExpChange(args)
    self:CheckForPerkChange(args)

end

function cExp:CheckForExpChange(args)

    if args.key ~= "Exp" then return end
    Events:Fire("PlayerExpUpdated", args.value)

    if self.level and self.level ~= args.value.level then
        self:CreateLevelupEffect()
    end

    self.level = args.value.level

end

function cExp:CreateLevelupEffect()
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 19,
        sound_id = 28,
        position = LocalPlayer:GetPosition(),
        angle = Angle()
    })

    sound:SetParameter(0,1)

    ClientEffect.Play(AssetLocation.Game, {
        position = LocalPlayer:GetPosition(),
        angle = Angle(),
        effect_id = 89
    })

    local sub
    Events:Subscribe("Render", function(args)
        if IsValid(sound) then
            sound:SetPosition(Camera:GetPosition())
        end
    end)

    Timer.SetTimeout(10 * 1000, function()
        sound:Remove()
    end)
end

function cExp:CheckForPerkChange(args)

    if args.key ~= "Perks" then return end
    Events:Fire("PlayerPerksUpdated", args.value)

end

cExp = cExp()