class 'sHitDetection'

function sHitDetection:__init()

    Network:Subscribe("HitDetectionBulletHit", self, self.BulletHit)
end

function sHitDetection:BulletHit(args, player)
    print("hit")
end

sHitDetection = sHitDetection()