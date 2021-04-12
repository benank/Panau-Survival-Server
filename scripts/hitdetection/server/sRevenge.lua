class 'Revenge'

function Revenge:__init()
        
    self.perks = 
    {
        [103] = 0.25,
        [133] = 0.50
    }
    
    Events:Subscribe("PlayerKilled", self, self.PlayerKilled)
end

function Revenge:PlayerKilled(args)
    if not args.killer then return end
    local killer = sHitDetection.players[args.killer]
    if not IsValid(killer) then return end
    if args.player == killer then return end
    
    local perks = args.player:GetValue("Perks")
    local revenge_damage = 0

    for perk_id, revenge_amount in pairs(self.perks) do
        local unlocked = perks.unlocked_perks[perk_id]
        if unlocked then
            revenge_damage = math.max(revenge_damage, revenge_amount)
        end
    end
    
    if revenge_damage == 0 then return end -- No revenge perk
    
    Chat:Send(args.player, string.format("%.0f%% Revenge damage was inflicted to your killer.", revenge_damage * 100), Color(201, 69, 8))
    Chat:Send(killer, string.format("%.0f%% Revenge damage was inflicted upon you.", revenge_damage * 100), Color(201, 69, 8))
    
    Network:Broadcast("HitDetection/Revenge", {
        pos1 = args.player:GetPosition(),
        angle1 = args.player:GetAngle(),
        pos2 = killer:GetPosition(),
        angle2 = killer:GetAngle()
    })
    
    sHitDetection:ApplyDamage({
        player = killer,
        source = DamageEntity.Revenge,
        attacker = args.player,
        damage = revenge_damage
    })

end

Revenge = Revenge()