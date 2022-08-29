class "ChasePlayerBehavior"
ChasePlayerBehavior.name = "ChasePlayerBehavior"

function ChasePlayerBehavior:__init(actor_profile_instance)
    self.actor_profile_instance = actor_profile_instance
    getter_setter(self, "active")
    getter_setter(self, "max_chase_time") -- max time spent pathing towards the target before firing the timeout event
    self.chasing = false
    self.chase_timer = Timer()

    self.actor_profile_instance.actor:SubscribeToStateEvent("LineOfSightGainedWhenChasing", self, self.LineOfSightGainedWhenChasing)
end

function ChasePlayerBehavior:StartChasing(target)
    --Chat:Broadcast("Started Chasing Player", Color.Purple)
    self.target = target
    self.chasing = true
    self.chase_timer:Restart()
    self:FindNextPath(self.target)
    self.actor_profile_instance.actor:AddStateEvent("StartChasing", {
        target = self.target
    })

    if self.chase_interval then
        Timer.Clear(self.chase_interval)
        self.chase_interval = nil
    end
    self.chase_interval = Timer.SetInstanceInterval(1500, self, self.ChaseInterval)
end

function ChasePlayerBehavior:ChaseInterval() -- every 1500 ms
    if self.chasing then
        self:CheckForTimeout()
    end
end

function ChasePlayerBehavior:CheckForTimeout()
    if self.max_chase_time then
        if self.chase_timer:GetMilliseconds() > self.max_chase_time then
            self.actor_profile_instance.actor:FireBehaviorEvent("ChasingTimedOut")
        end
    end
end

function ChasePlayerBehavior:StopChasing()
    self.chasing = false
    self.actor_profile_instance.actor:AddStateEvent("StopChasing", {}) -- let actor profile do the state sync
end

function ChasePlayerBehavior:FindNextPath(target) -- requires GetPosition on the actor profile to be accurate at this point in time
    local current_position = self.actor_profile_instance.actor:GetPosition()
    local target_position = target:GetPosition()

    if self.actor_profile_instance.actor.behaviors.NavigatePathBehavior then
        local current_path = self.actor_profile_instance.actor.behaviors.NavigatePathBehavior:GetPath()
        if current_path then
            local last_node_position = current_path:GetLastNodePosition()
            if Vector3.Distance(target_position, last_node_position) < 10 then
                --Chat:Broadcast("Re-using old path", Color.Red)
                -- dont try to find new path if current path last node is close to target position
                if self.actor_profile_instance.actor.behaviors.NavigatePathBehavior:GetProgress() < 1.0 then
                    self.actor_profile_instance.actor.behaviors.NavigatePathBehavior:Resume()
                    return
                end
            end
        end
    end

    PathEngineManager:GetFootPath(target:GetPosition(), current_position, self.PathRequestCallback, self)
end

function ChasePlayerBehavior:PathRequestCallback(data)
    if not data or data.error then
        print("could not find path! trying again")
        print(data.error)
        self:FindNextPath(self.actor_profile_instance.target)
    else
        self.actor_profile_instance.actor:FireBehaviorEvent("PathAcquired", data.path)
    end
end

function ChasePlayerBehavior:LineOfSightGainedWhenChasing(args, player)
    self.actor_profile_instance.actor:FireBehaviorEvent("LineOfSightGainedWhenChasing")
end

function ChasePlayerBehavior:Remove()
    if self.chase_interval then
        Timer.Clear(self.chase_interval)
        self.chase_interval = nil
    end
    self.actor_profile_instance = nil
    self.chase_timer = nil
end