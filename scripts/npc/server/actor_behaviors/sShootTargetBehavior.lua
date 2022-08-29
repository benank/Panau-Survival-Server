class "ShootTargetBehavior"
ShootTargetBehavior.name = "ShootTargetBehavior"

function ShootTargetBehavior:__init(actor_profile_instance)
    self.actor_profile_instance = actor_profile_instance
    getter_setter(self, "active")
    
    self.shooting = false
    self.min_duration = 3500
    self.duration_timer = Timer()
    self.has_los = false

    self.actor_profile_instance.actor:SubscribeToStateEvent("LineOfSightLost", self, self.LineOfSightLost)
    self.actor_profile_instance.actor:SubscribeToStateEvent("LineOfSightGained", self, self.LineOfSightGained)
end

function ShootTargetBehavior:ShootTarget(target)
    --Chat:Broadcast("Started Shooting Target", Color.Yellow)
    self.target = target
    self.min_duration = math.random(math.round(self.min_duration * 0.80), math.round(self.min_duration * 1.20))
    self.has_los = false
    self.actor_profile_instance.actor:AddStateEvent("ShootTarget", {
        target = target,
        min_duration = min_duration
    })
    self.duration_timer:Restart()
    self.shooting = true

    if self.update_interval then
        Timer.Clear(self.update_interval)
    end
    self.update_interval = Timer.SetInstanceInterval(350, self, self.Update)
end

function ShootTargetBehavior:LineOfSightLost(player, args)
    --Chat:Broadcast("Entered LineOfSightLost", Color.Blue)
    self.has_los = false
end

function ShootTargetBehavior:LineOfSightGained(player, args)
    --Chat:Broadcast("Entered LineOfSightGained", Color.Green)
    self.has_los = true
    self.actor_profile_instance.actor:FireBehaviorEvent("LineOfSightGained")
end

function ShootTargetBehavior:Update()
    if not self.has_los and self.duration_timer:GetMilliseconds() > self.min_duration then
        self:StopShootingTarget(true)
    elseif self.has_los then
        self.duration_timer:Restart()
    end
end

-- fire_behavior_event is bool whether we should fire callback function on the actor profile instance
function ShootTargetBehavior:StopShootingTarget(fire_behavior_event)
    if self.shooting then
        self.actor_profile_instance.actor:AddStateEvent("StopShootingTarget", {})
    end
    self.target = nil
    self.shooting = false
    self.has_los = false
    if self.update_interval then
        Timer.Clear(self.update_interval)
        self.update_interval = nil
    end

    if fire_behavior_event then
        self.actor_profile_instance.actor:FireBehaviorEvent("StoppedShootingTarget")
    end
end


-- need to send this in actor profile sync data
function ShootTargetBehavior:GetRemainingMinDuration()
    if self.shooting then
        return math.min(0, self.min_duration - self.duration_timer:GetMilliseconds())
    else
        return 0
    end
end

function ShootTargetBehavior:Remove()
    -- remove references to actor profile instance
end
