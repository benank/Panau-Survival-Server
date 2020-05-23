class "HitDetection"

function HitDetection:__init()
    Network:Subscribe("HitDetection/DetectPlayerHit", self, self.DetectPlayerHit)
end

function HitDetection:DetectPlayerHit(args, player)
    local damage = WeaponDamage:CalculatePlayerDamage(args.weapon_enum, args.bone_enum)
    Chat:Broadcast(tostring(player) .. " hit " .. tostring(BoneEnum:GetDescription(args.bone_enum)) .. " for " .. tostring(damage), Color.Yellow)
end

HitDetection = HitDetection()