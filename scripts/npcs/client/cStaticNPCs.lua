class 'cStaticNPCs'

function cStaticNPCs:__init()
    
    self.static_npcs = {}
    self.static_npcs_shared_object = SharedObject.Create("StaticNPCs")
    
    Network:Subscribe("NPC/static/sync", self, self.SyncStaticNPCs)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function cStaticNPCs:SyncStaticNPCs(data)
    self:RemoveAllActors()
    self.static_npcs = data
    
    for _, npc_data in pairs(self.static_npcs) do
        local actor = self:CreateClientActor(npc_data)
        npc_data.client_actor_id = actor:GetId()
    end
    
    self:UpdateSharedNPCs()
end

function cStaticNPCs:UpdateSharedNPCs()
    self.static_npcs_shared_object:SetValue("StaticNPCs", self.static_npcs)
end

function cStaticNPCs:RemoveAllActors()
    for _, npc_data in pairs(self.static_npcs) do
        local actor = ClientActor.GetById(npc_data.client_actor_id)
        if IsValid(actor) then
            actor:Remove()
        end
    end
end

function cStaticNPCs:ModuleUnload()
    self:RemoveAllActors()
end

function cStaticNPCs:CreateClientActor(npc_data)
    return ClientActor.Create(AssetLocation.Game, {
        model_id = tonumber(npc_data.model_id),
        position = npc_data.position,
        angle = Angle(math.random() * math.pi * 2, 0, 0)
    })
end

cStaticNPCs = cStaticNPCs()