class "RoamBehavior"
RoamBehavior.name = "RoamBehavior"

function RoamBehavior:__init(actor_profile_instance)
    self.actor_profile_instance = actor_profile_instance
    getter_setter(self, "active")
end

function RoamBehavior:FindNextPath() -- requires GetPosition on the actor profile to be accurate at this point in time
    Chat:Broadcast("Started Roaming", Color.Green)
    local current_position = self.actor_profile_instance.actor:GetPosition()
    PathEngineManager:GetRoamPath(current_position, self.PathRequestCallback, self)
end

function RoamBehavior:PathRequestCallback(data)
    if not data or data.error then
        -- TODO: if we fail too many times, we should abort to avoid spamming the path server
        self:FindNextPath()
    else
        self.actor_profile_instance.actor:FireBehaviorEvent("PathAcquired", data.path)
    end
end
