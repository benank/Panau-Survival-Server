class "DetectLocalPlayerHitsBehavior"
DetectLocalPlayerHitsBehavior.name = "DetectLocalPlayerHitsBehavior"

function DetectLocalPlayerHitsBehavior:__init(actor_profile_instance)
    getter_setter(self, "active")
    
    self.actor_profile_instance = actor_profile_instance
end

function DetectLocalPlayerHitsBehavior:Hit()
    self.actor_profile_instance.actor:FireBehaviorEvent("LocalPlayerHit")
end