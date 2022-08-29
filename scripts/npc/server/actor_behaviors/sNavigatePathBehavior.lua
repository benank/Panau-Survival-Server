class "NavigatePathBehavior"
NavigatePathBehavior.name = "NavigatePathBehavior"

function NavigatePathBehavior:__init(actor_profile_instance)
    self.actor_profile_instance = actor_profile_instance
    getter_setter(self, "active")
    getter_setter(self, "paused")
    getter_setter(self, "path")
    getter_setter(self, "is_pathing")
    getter_setter(self, "speed_multiplier")
end

function NavigatePathBehavior:StartPath()
    print("Entered StartPath")

    self.path_navigation = PathNavigation()
    self.path_navigation:SetPath(self:GetPath())
    self.path_navigation:SetSpeedMultiplier(self:GetSpeedMultiplier())
    self.path_navigation:SetPathFinishedCallback(self.PathFinishedCallback)
    self.path_navigation:SetPathFinishedCallbackInstance(self)
    self.path_navigation:StartPath()
    self.is_pathing = true
end

function NavigatePathBehavior:GetPosition()
    if not self.path_navigation then return nil end
    return self.path_navigation:GetPosition()
end

-- returns 0.0 -> 1.0 path progress
function NavigatePathBehavior:GetProgress()
    if not self.path_navigation then return nil end
    return self.path_navigation:GetPathProgress()
end

function NavigatePathBehavior:PathFinishedCallback()
    self.actor_profile_instance.actor:FireBehaviorEvent("PathFinished")
end

function NavigatePathBehavior:Pause()
    self.paused = true
    self.path_navigation:Pause()
    self.actor_profile_instance.actor:AddStateEvent("PausePath", {})
end

function NavigatePathBehavior:Resume()
    self.paused = false
    self.path_navigation:Resume()
    self.actor_profile_instance.actor:AddStateEvent("ResumePath", {})
end