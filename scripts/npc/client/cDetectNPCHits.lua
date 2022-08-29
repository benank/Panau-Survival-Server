class "DetectNPCHits"

function DetectNPCHits:__init()
    Events:Subscribe(var("LocalPlayerBulletDirectHitEntity"):get(), self, self.LocalPlayerBulletDirectHitEntity)
end

function DetectNPCHits:LocalPlayerBulletDirectHitEntity(args)
    --entity_type = raycast.entity.__type,
    --entity_id = raycast.entity:GetId(),
    --entity = raycast.entity,
    --weapon_enum = self.weapon_enum,
    --hit_position = raycast.position,
    --distance_travelled = self.total_distance_covered

    if args.entity_type == "ClientActor" then
        local client_actor = ClientActor.GetById(args.entity_id)
        local actor_profile_instance = client_actor:GetValue("ActorProfileInstance")
        if actor_profile_instance then
            if actor_profile_instance.actor.behaviors.DetectLocalPlayerHitsBehavior then
                actor_profile_instance.actor.behaviors.DetectLocalPlayerHitsBehavior:Hit()
            end
        end
    end
end

DetectNPCHits = DetectNPCHits()