class "ChasePlayerBehavior"
ChasePlayerBehavior.name = "ChasePlayerBehavior"

function ChasePlayerBehavior:__init(actor_profile_instance)
    getter_setter(self, "active")
    self.actor_profile_instance = actor_profile_instance
    self.chasing = false
    self.has_los = false
    self.los_timer = Timer()
    self.los_delay = 250 -- how often to check for LoS & loss of LoS

    self:DeclareNetworkSubscriptions()
end

function ChasePlayerBehavior:DeclareNetworkSubscriptions()
    self.actor_profile_instance.actor:SubscribeToStateEvent("StartChasing", self, self.StartChasing)
    self.actor_profile_instance.actor:SubscribeToStateEvent("StopChasing", self, self.StopChasing)
end

function ChasePlayerBehavior:StartChasing(args)
    --Chat:Print("Started Chasing in cChasePlayerBehavior", Color.LawnGreen)
    self.target = args.target
    self.chasing = true
    self.has_los = false

    if self.los_interval then
        Timer.Clear(self.los_interval)
        self.los_interval = nil
    end
    self.los_interval = Timer.SetInstanceInterval(400, self, self.LineOfSightInterval)

    --Chat:Print("Entered client-side StartChasing in behavior", Color.LawnGreen)
end

function ChasePlayerBehavior:StopChasing()
    self.target = nil
    self.chasing = false
    if self.los_interval then
        Timer.Clear(self.los_interval)
        self.los_interval = nil
    end
end

function ChasePlayerBehavior:LineOfSightInterval()
    local client_actor = self.actor_profile_instance.client_actor
    local client_has_authority = tostring(self.target:GetSteamId()) == tostring(LocalPlayer:GetSteamId())
    if client_has_authority and self.chasing and client_actor and IsValid(client_actor) and IsValid(self.target) then
        if not self.has_los then
            self:AttemptEstablishLineOfSight()
        end
    end

    self.actor_profile_instance.actor:SyncStateEventsIfNecessary()
end

-- defer to the actor profile instance for testing line-of-sight
function ChasePlayerBehavior:AttemptEstablishLineOfSight()
    self.has_los = self.actor_profile_instance.actor:IsEntityInLineOfSight(self.target)
    if self.has_los then
        --Chat:Print("Gained LoS when Chasing", Color.Tomato)
        self.actor_profile_instance.actor:AddStateEvent("LineOfSightGainedWhenChasing")
    end
end

function ChasePlayerBehavior:Remove()
    if self.los_interval then
        Timer.Clear(self.los_interval)
    end
    self.actor_profile_instance = nil
    self.target = nil
end
