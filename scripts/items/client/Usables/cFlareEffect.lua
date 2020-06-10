class 'cFlareEffects'

function cFlareEffects:__init()

    Events:Subscribe("Flare", self, self.Add)

end

--[[
    Creates a new flare effect. 

    args (in table):
        position: position to launch flare up from (flare will be ~80m above this)
        time: time in seconds that the flare lasts. 
]]
function cFlareEffects:Add(args)

    -- Play initial flare effect
    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        angle = Angle(0, -math.pi / 12, 0),
        effect_id = 266
    })
    
    Timer.SetTimeout(1000, function()
        ClientLight.Play({
            position = args.position + Vector3(0, 110, 0),
            angle = Angle(),
            color = Color(252, 73, 60),
            multiplier = 10,
            radius = 500,
            timeout = args.time
        })
    end)

    local timer = Timer()

    Thread(function()
    
        while timer:GetSeconds() < args.time do
            Timer.Sleep(7000)
            self:ReplayFlare(args.position + Vector3(0, 81, 5))
        end

    end)

end

function cFlareEffects:ReplayFlare(pos)

    ClientParticleSystem.Play(AssetLocation.Game, {
        position = pos,
        timeout = 8,
        angle = Angle(),
        path = "fx_flare_02.psmb"
    })

end

cFlareEffects = cFlareEffects()

