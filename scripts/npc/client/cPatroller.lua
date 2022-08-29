class "Patroller"

function Patroller:__init()
    getter_setter(self, "actor")
    getter_setter(self, "path")
    self.actor = Actor()
end

function Patroller:InitializeBehaviors()
    -- Configure behaviors
    self.actor:UseBehavior(self, DetectLocalPlayerHitsBehavior)
    self.actor:UseBehavior(self, FollowPathBehavior2)
    self.actor:UseBehavior(self, ShootTargetBehavior)
    self.actor:UseBehavior(self, ChasePlayerBehavior)

    -- TODO: try to move these to the behavior classes since it's not actor profile specific?
    -- unless we want the flexibility to disable these parts of behaviors? dont think so
    self.actor:SubscribeToStateEvent("ShootTarget", self.actor.behaviors.ShootTargetBehavior, self.actor.behaviors.ShootTargetBehavior.ShootTarget)
    self.actor:SubscribeToStateEvent("PausePath", self.actor.behaviors.FollowPathBehavior2, self.actor.behaviors.FollowPathBehavior2.PausePath)
    self.actor:SubscribeToStateEvent("ResumePath", self.actor.behaviors.FollowPathBehavior2, self.actor.behaviors.FollowPathBehavior2.ResumePath)
end

function Patroller:GetSyncData()
    local sync_data = {}
    return sync_data
end

function Patroller:InitializeFromSyncData(sync_data)
    self.path = Path()
    self.path:InitializeFromJsonData(sync_data.path)

    self:InitializeBehaviors()
    self.actor.behaviors.FollowPathBehavior2:FollowNewPath(self.path, sync_data.path_progress, sync_data.path_speed_multiplier)
end

function Patroller:Spawn()
    local spawn_node = self.path.positions[self.actor.behaviors.FollowPathBehavior2.current_node_index]
    local next_path_node = self.path.positions[self.actor.behaviors.FollowPathBehavior2.current_node_index + 1]
    local spawn_angle = next_path_node and Angle(Angle.FromVectors(Vector3.Forward, next_path_node - spawn_node).yaw, 0, 0) or Angle()
    local spawn_position = self.actor.behaviors.FollowPathBehavior2:GetPosition()
    self.client_actor = ClientActor.Create(self, {
        model_id = self.actor:GetModelId(),
        position = spawn_position,
        angle = spawn_angle
    })

    Timer.SetTimeout(1500, function()
        if self.actor and self.actor.active and self.client_actor and IsValid(self.client_actor) and self.actor.weapon_enum then
            self.client_actor:GiveWeapon(1, Weapon(WeaponEnum:GetWeaponId(self.actor.weapon_enum), 999999, 999999))
        end
    end)
    self.actor:Respawned()
end

-- LocalPlayer shot the actor
function Patroller:LocalPlayerHit()
    Network:Send("npc/PlayerAttackNPC" .. tostring(self.actor.actor_id), {
        line_of_sight = self:HasLineOfSightOnLocalPlayer()
    })
end

function Patroller:HasLineOfSightOnLocalPlayer()
    if not IsValid(self.client_actor) then return false end
    local client_actor_pos = self.client_actor:GetPosition() + Vector3(0, 2.3, 0)
    local localplayer_pos = LocalPlayer:GetBonePosition("ragdoll_Head")
    
	local ray = Physics:Raycast(client_actor_pos, Angle.FromVectors(Vector3.Forward, localplayer_pos - client_actor_pos) * Vector3.Forward, 0, 850, false)
	return (ray.entity and ray.entity.__type == "LocalPlayer")
end

function Patroller:Respawn(pos, ang)
    if IsValid(self.client_actor) then
        self.client_actor:Remove()
    end
    print("self:")
    print(self)
    print(self.actor)
    self.client_actor = ClientActor.Create(self, {
        model_id = self.actor:GetModelId(),
        position = pos,
        angle = ang
    })
end

function Patroller:RenderDebug()
    self.path:RenderDebug()
end

function Patroller:Remove()
    self.actor = nil
    if IsValid(self.client_actor) then -- TODO : build actor removal queue to avoid crashes
        self.client_actor:Remove()
    end
end