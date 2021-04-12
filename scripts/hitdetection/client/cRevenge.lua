class 'Revenge'

function Revenge:__init()
    Network:Subscribe("HitDetection/Revenge", self, self.HitDetectionRevenge)
end

function Revenge:HitDetectionRevenge(args)
    ClientEffect.Play(AssetLocation.Game, {
        position = args.pos1,
        angle = args.angle1,
        effect_id = 429
    })
    
    ClientEffect.Play(AssetLocation.Game, {
        position = args.pos2,
        angle = args.angle2,
        effect_id = 429
    })
end

Revenge = Revenge()