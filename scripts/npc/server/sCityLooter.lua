class "CityLooter"

function CityLooter:__init(actor_id)
    getter_setter(self, "actor")
    getter_setter(self, "path")
    getter_setter(self, "announced")
    getter_setter(self, "target")
    self.actor = Actor(actor_id)
    self.actor:SetActorProfileEnum(ActorProfileEnum.CityLooter)
    self.path_speed_multiplier = 1.03
    self.actor:SetWeaponEnum(random_weighted_table_value({
        [WeaponEnum.Handgun] = 120,
        [WeaponEnum.Revolver] = 120,
        [WeaponEnum.SawnOffShotgun] = 30,
        [WeaponEnum.SMG] = 30,
        [WeaponEnum.Assault] = 25,
        [WeaponEnum.MachineGun] = 25,
        [WeaponEnum.Sniper] = 15
    }))
    self.actor:SetModelId(random_weighted_table_value({
        [94] = 10,
        [92] = 10,
        [76] = 10,
        [72] = 10,
        [69] = 10,
        [68] = 10,
        [56] = 10,
        [50] = 10
    }))

    -- Configure behaviors
    self.actor:UseBehavior(self, NavigatePathBehavior)
    self.actor:UseBehavior(self, RoamBehavior)
    self.actor:UseBehavior(self, ShootTargetBehavior)
    self.actor:UseBehavior(self, ChasePlayerBehavior)
    self.actor.behaviors.NavigatePathBehavior:SetSpeedMultiplier(self.path_speed_multiplier)
    self.actor.behaviors.ChasePlayerBehavior:SetMaxChaseTime(45000) -- max time spent pathing towards the target before we get the timeout event (in milliseconds)

    self:DeclareNetworkSubscriptions()
end

function CityLooter:DeclareNetworkSubscriptions()
    Network:Subscribe("npc/PlayerAttackNPC" .. tostring(self.actor.actor_id), self, self.PlayerAttacked)
end

function CityLooter:GetSyncData()
    local sync_data = {}

    if self.path then
        sync_data.path = self.path:GetJsonCompatibleData()
        sync_data.path_progress = self.actor.behaviors.NavigatePathBehavior:GetProgress() or 0.00001
        sync_data.path_speed_multiplier = self.path_speed_multiplier
    end
    sync_data.position = self.actor:GetPosition()
    --sync_data.shooting = 
    
    return sync_data
end

function CityLooter:Initialize(data)
    self.actor:SetPosition(Copy(data.position))
    
    self.actor.behaviors.RoamBehavior:FindNextPath() -- self.actor.position should be up-to-date before calling FindNextPath

    self:DeclareNetworkSubscriptions()
end

function CityLooter:GetLineOfSightOffset()
    return Vector3()
end

-- "PathAcquired" behavior event handler from ChasePlayerBehavior
function CityLooter:PathAcquired(path)
    if self.removed then return end
    if not self.announced then
        self.announced = true
        ActorSync:AnnounceActor(self)
    end

    self.path = Path()
    self.path:SetPositions(path)
    self.actor:SetPosition(Copy(path[1]))
    self.actor.behaviors.NavigatePathBehavior:SetPath(self.path)
    self.actor.behaviors.NavigatePathBehavior:StartPath()

    if count_table(self.actor.streamed_players) > 0 then
        Network:SendToPlayers(self.actor:GetStreamedPlayersSequential(), "npc/NextPath" .. tostring(self.actor:GetActorId()), {
            path = self.path:GetJsonCompatibleData(),
            path_speed_multiplier = self.path_speed_multiplier
        })
    end
end

-- "PathFinished" behavior event handler
-- could be moved to a separate behavior, but it's not much code
function CityLooter:PathFinished()
    self.actor:SetPosition(Copy(self.path.positions[#self.path.positions]))

    if self:IsChasing() then
        self.actor.behaviors.ShootTargetBehavior:StopShootingTarget(false)
        self.actor.behaviors.ChasePlayerBehavior:StartChasing(self.target) -- self.actor.position should be up-to-date before calling StartChasing
    else
        self.actor.behaviors.RoamBehavior:FindNextPath() -- self.actor.position should be up-to-date before calling FindNextPath
    end
end

function CityLooter:PlayerAttacked(args, player)
    local should_acquire_target = false
    if self.target ~= player then
        should_acquire_target = true
    elseif not self.target or not IsValid(self.target) then
        should_acquire_target = true
    end
    if not self.actor:IsPlayerStreamedIn(player) then
        print("tried to set NewTarget but new target is not streamed in")
        should_acquire_target = false
    end

    --print("should_acquire_target: ", should_acquire_target)
    
    if should_acquire_target then
        self:NewTarget(player)
        self.actor.behaviors.NavigatePathBehavior:Pause()
        if args.line_of_sight then
            self.actor.behaviors.ChasePlayerBehavior:StopChasing()
            self.actor.behaviors.ShootTargetBehavior:ShootTarget(self.target)
        else
            self:UpdateStoredPosition()
            self.actor.behaviors.ChasePlayerBehavior:StartChasing(player)
        end
    end

    self.actor:SyncStateEventsIfNecessary()
end

function CityLooter:NewTarget(new_target)
    self.target = new_target
end

function CityLooter:StoppedShootingTarget() -- happens when LoS is lost after min duration of shooting
    self:UpdateStoredPosition()
    if self.target and IsValid(self.target) then
        self.actor.behaviors.ShootTargetBehavior:StopShootingTarget(false)
        self.actor.behaviors.ChasePlayerBehavior:StartChasing(self.target)
    else
        self.target = nil
        self.actor.behaviors.RoamBehavior:FindNextPath()
    end
    --Chat:Broadcast("Entered StoppedShootingTarget", Color.Red)
    self.actor:SyncStateEventsIfNecessary()
end

function CityLooter:LineOfSightGainedWhenChasing()
    self.actor.behaviors.NavigatePathBehavior:Pause()
    self.actor.behaviors.ChasePlayerBehavior:StopChasing()
    self.actor.behaviors.ShootTargetBehavior:ShootTarget(self.target)
    self.actor:SyncStateEventsIfNecessary()
end

-- from ChasePlayerBehavior
function CityLooter:ChasingTimedOut()
    self.target = nil
    self:UpdateStoredPosition()
    self.actor.behaviors.RoamBehavior:FindNextPath() -- self.actor.position should be up-to-date before calling FindNextPath
    self.actor.behaviors.NavigatePathBehavior:Pause()
    self.actor.behaviors.ChasePlayerBehavior:StopChasing()

    self.actor:SyncStateEventsIfNecessary()
end

function CityLooter:IsChasing()
    return self.actor.behaviors.ChasePlayerBehavior.chasing
end

function CityLooter:UpdateStoredPosition()
    self.actor:SetPosition(self.actor.behaviors.NavigatePathBehavior:GetPosition())
end

function CityLooter:Remove()
    
end