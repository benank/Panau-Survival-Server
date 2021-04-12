class 'cBurstPing'

function cBurstPing:__init()
    
    Network:Subscribe("items/BurstPingHit", self, self.LocalPlayerHit)
    Network:Subscribe("items/BurstPingFX", self, self.CreateFX)
end

function cBurstPing:LocalPlayerHit(args)
    Events:Fire("HitDetection/KnockdownEffect", {
        source = args.position,
        amount = args.amount
    })
    
    Timer.SetTimeout(250, function()
        Events:Fire("HitDetection/KnockdownEffect", {
            source = args.position,
            amount = args.amount
        })
    end)
end

function cBurstPing:CreateFX(args)
    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        angle = Angle(0, math.pi / 2, 0),
        effect_id = args.effect_id
    })
end

cBurstPing = cBurstPing()

