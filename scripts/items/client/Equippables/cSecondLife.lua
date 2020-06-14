class 'cSecondLife'

function cSecondLife:__init()

    self.fx = {}

    Network:Subscribe("Hitdetection/SecondLifeActivate", self, self.SecondLifeActivate)
    Network:Subscribe("Hitdetection/SecondLifeDectivate", self, self.SecondLifeDectivate)

    Events:Subscribe("LoadingFinished", self, self.LoadingFinished)

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function cSecondLife:LoadingFinished()

    -- Recreate effects on player death because they disappear
    for id, fx in pairs(self.fx) do
        local pos = fx[1]:GetPosition()
        for _, effect in pairs(fx) do
            if IsValid(effect) then
                effect:Remove()
            end
        end
        self:SecondLifeActivate({id = id, position = pos})
    end

end

function cSecondLife:ModuleUnload()

    for id, fx in pairs(self.fx) do
        for _, effect in pairs(fx) do
            if IsValid(effect) then
                effect:Remove()
            end
        end
    end

end

function cSecondLife:SecondLifeDectivate(args)

    if args.id == tostring(LocalPlayer:GetSteamId()) then
        Game:FireEvent("ply.pause")
    end

    Thread(function()
        Timer.Sleep(3000)
        if not self.fx[args.id] then return end

        ClientEffect.Play(AssetLocation.Game, {
            position = args.position,
            angle = Angle(),
            effect_id = 285
        })

        Timer.Sleep(500)

        for _, effect in pairs(self.fx[args.id]) do
            if IsValid(effect) then effect:Remove() end
        end

        self.fx[args.id] = nil

        if args.id == tostring(LocalPlayer:GetSteamId()) then
            Game:FireEvent("ply.unpause")
        end
    end)

end

function cSecondLife:SecondLifeActivate(args)

    local fx = {}

    table.insert(fx, ClientEffect.Create(AssetLocation.Game, {
        position = args.position,
        angle = Angle(),
        effect_id = 118
    }))

    table.insert(fx, ClientEffect.Create(AssetLocation.Game, {
        position = args.position,
        angle = Angle(),
        effect_id = 262
    }))

    self.fx[args.id] = fx

    if args.id == tostring(LocalPlayer:GetSteamId()) then
        Game:FireEvent("ply.pause")
    end

end

cSecondLife = cSecondLife()