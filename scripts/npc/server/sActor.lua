class "Actor"

function Actor:__init(actor_id)
    getter_setter(self, "active")
    getter_setter(self, "actor_id")
    getter_setter(self, "actor_profile_enum")
    getter_setter(self, "cell")
    getter_setter(self, "host")
    getter_setter(self, "streamed_players")
    getter_setter(self, "behaviors")
    getter_setter(self, "actor_profile_instance")
    getter_setter(self, "removed")
    getter_setter(self, "weapon_enum")
    getter_setter(self, "model_id")

    self:SetActorId(actor_id)
    
    
    self.behaviors = {}
    self.streamed_players = {}
    self.state_event_callbacks = {}
    self.queued_state_events = {}
end

function Actor:Initialize()
    self:DeclareNetworkSubscriptions()
end

function Actor:DeclareNetworkSubscriptions()
    self.state_events_sub = Network:Subscribe("npc/StateEventsFromClient" .. tostring(self.actor_id), self, self.StateEventsFromClient)
end

function Actor:StreamInPlayer(player)
    if not IsValid(player) then return end
    
    local steam_id = tostring(player:GetSteamId())
    self.streamed_players[steam_id] = player
end

function Actor:StreamOutPlayer(player)
    if not IsValid(player) then return end

    local steam_id = tostring(player:GetSteamId())
    self.streamed_players[steam_id] = nil
end

function Actor:IsPlayerStreamedIn(player)
    if not IsValid(player) then return false end
    return self.streamed_players[tostring(player:GetSteamId())] ~= nil
end

function Actor:GetStreamedPlayersSequential()
    local sequential_streamed_players = {}
    for steam_id, player in pairs(self.streamed_players) do
        table.insert(sequential_streamed_players, player)
    end
    return sequential_streamed_players
end

function Actor:GetSyncData()
    local sync_data = {}
    
    sync_data.active = self.active
    sync_data.actor_id = self.actor_id
    sync_data.actor_profile_enum = self.actor_profile_enum
    sync_data.position = self.position
    sync_data.cell = self.cell
    sync_data.host = self.host
    sync_data.weapon_enum = self.weapon_enum
    sync_data.model_id = self.model_id

    return sync_data
end

function Actor:UseBehavior(actor_profile_instance, behavior_class)
    local behavior_instance = behavior_class(actor_profile_instance)
    self.behaviors[behavior_class.name] = behavior_instance
    behavior_instance:SetActive(true)
end

function Actor:RemoveAllBehaviors()
    for behavior_name, behavior_instance in pairs(self.behaviors) do
        if behavior_instance.Remove then
            behavior_instance:Remove()
        end
        behavior_instance:SetActive(false)
    end
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
    if count_table(self.queued_state_events) > 0 and count_table(self.streamed_players) > 0 then
        local streamed_players_seq = self:GetStreamedPlayersSequential()
        Network:SendToPlayers(streamed_players_seq, "npc/SyncStateEvents" .. tostring(self.actor_id), {
            state_events = Copy(self.queued_state_events)
        })
    end
    self.queued_state_events = {}
end

function Actor:StateEventsFromClient(args, player)
    for _, state_event_data in ipairs(args.state_events) do
        local callbacks = self.state_event_callbacks[state_event_data.event_name]
        if callbacks then
            for _, callback_data in ipairs(callbacks) do
                local callback_instance, callback = callback_data.callback_instance, callback_data.callback
                if callback_instance then
                    callback(callback_instance, player, state_event_data.data)
                else
                    callback(player, state_event_data.data)
                end
            end
        end
    end
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

function Actor:GetPosition()
    if not self.position then
        print("Called Actor:GetPosition() but not position has been set on the actor yet")
    end
    return self.position
end

function Actor:SetPosition(pos)
    self.position = pos
    -- update the cell based on the new position
    if pos then
        self:SetCell(GetCell(self.position, ActorSync.cell_size))
    end
end

-- TODO: implement server-side actor removal/cleanup
function Actor:Remove()
    Network:Unsubscribe(self.state_events_sub)
end
