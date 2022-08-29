class "Actor"

function Actor:__init()
    getter_setter(self, "active")
    getter_setter(self, "actor_id")
    getter_setter(self, "actor_profile_enum")
    getter_setter(self, "position")
    getter_setter(self, "cell")
    getter_setter(self, "host")
    getter_setter(self, "model_id")
    getter_setter(self, "behaviors")
    getter_setter(self, "actor_profile_instance")
    getter_setter(self, "weapon_enum")

    self.client_actor_spawned_timer = Timer()
    self.behaviors = {}
    self.state_event_callbacks = {}
    self.queued_state_events = {}
end

function Actor:DeclareNetworkSubscriptions()
    self.state_events_sub = Network:Subscribe("npc/SyncStateEvents" .. tostring(self.actor_id), self, self.SyncStateEvents)
end

function Actor:GetSyncData()
    local sync_data = {}
    
    sync_data.actor_id = self.actor_id
    sync_data.actor_profile_enum = self.actor_profile_enum
    sync_data.position = self.position
    sync_data.cell = self.cell

    return sync_data
end

function Actor:InitializeFromSyncData(sync_data)
    if sync_data.active ~= nil then
        self.active = sync_data.active
    end
    if sync_data.actor_id then
        self.actor_id = sync_data.actor_id
    end
    if sync_data.position then
        self.position = sync_data.position
    end
    if sync_data.actor_profile_enum then
        self.actor_profile_enum = sync_data.actor_profile_enum
    end
    if sync_data.cell then
        self.cell = sync_data.cell
    end
    self.weapon_enum = sync_data.weapon_enum
    self.model_id = sync_data.model_id
    
    self:DeclareNetworkSubscriptions()
end

function Actor:SubscribeToStateEvent(state_event_name, callback_instance, callback)
    if not self.state_event_callbacks[state_event_name] then
        self.state_event_callbacks[state_event_name] = {}
    end
    table.insert(self.state_event_callbacks[state_event_name], {
        callback_instance = callback_instance,
        callback = callback
    })
end

function Actor:SyncStateEvents(args)
    for _, state_event_data in ipairs(args.state_events) do
        local callbacks = self.state_event_callbacks[state_event_data.event_name]
        if callbacks then
            for _, callback_data in ipairs(callbacks) do
                local callback_instance, callback = callback_data.callback_instance, callback_data.callback
                if callback_instance then
                    callback(callback_instance, state_event_data.data)
                else
                    callback(state_event_data.data)
                end
            end
        end
    end
end

function Actor:UseBehavior(actor_profile_instance, behavior_class)
    local behavior_instance = behavior_class(actor_profile_instance)
    self.behaviors[behavior_class.name] = behavior_instance
    behavior_instance:SetActive(true)
end

function Actor:Respawned()
    self.client_actor_spawned_timer:Restart()
end

function Actor:GetClientActorSpawnedTime()
    return self.client_actor_spawned_timer:GetSeconds()
end

-- shoot ray from actor -> entity
function Actor:IsEntityInLineOfSight(entity)
    local target_entity_type = entity.__type
	local client_actor = self.actor_profile_instance.client_actor
	local target_position = entity:GetBonePosition("ragdoll_Head")
	if IsNaN( target_position ) then return end
	local actor_position = client_actor:GetBonePosition("ragdoll_Head") + Vector3(0, 0.35, 0)

	local ray_angle = target_position - actor_position
	ray_angle:Normalize()

	local raycast = Physics:Raycast(actor_position, ray_angle, 0, 1000, false)

	if raycast.entity == nil then return false end -- no LoS

	if raycast.entity and IsValid(raycast.entity) then
		local entity_type = raycast.entity.__type
		if entity_type == target_entity_type then
            if entity == raycast.entity then
				return true
			end
		end
	end

	return false
end

-- map the behavior event to a function of the same name on the Agent
function Actor:FireBehaviorEvent(event_name, args)
    if self.actor_profile_instance[event_name] then
        self.actor_profile_instance[event_name](self.actor_profile_instance, args)
    end
end

function Actor:AddStateEvent(state_event_name, data)
    table.insert(self.queued_state_events, {
        event_name = state_event_name,
        data = data
    })
end

function Actor:SyncStateEventsIfNecessary()
    if count_table(self.queued_state_events) > 0 then
        Network:Send("npc/StateEventsFromClient" .. tostring(self.actor_id), {
            state_events = Copy(self.queued_state_events)
        })
        self.queued_state_events = {}
    end
end

function Actor:RemoveAllBehaviors()
    for behavior_name, behavior_instance in pairs(self.behaviors) do
        behavior_instance:SetActive(false)
        if behavior_instance.Remove then
            behavior_instance:Remove()
        end
    end
end

function Actor:Remove()
    Network:Unsubscribe(self.state_events_sub)
    self.state_event_callbacks = nil
    self.actor_profile_instance = nil
end

