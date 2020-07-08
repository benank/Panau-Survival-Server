class 'cC4s'

function cC4s:__init(args)

    self.near_stashes = {} -- [cso id] = lootbox uid
    self.c4s = {} -- [wno id] = cC4() 

    self.placing_c4 = false

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    
    Network:Subscribe(var("items/StartC4Placement"):get(), self, self.StartC4Placement)
    Network:Subscribe(var("items/C4Explode"):get(), self, self.C4Explode)

    Network:Subscribe("items/PlayC4TriggerAnimation", self, self.PlayC4TriggerAnimation)

    Events:Subscribe("WorldNetworkObjectCreate", self, self.WorldNetworkObjectCreate)
    Events:Subscribe("WorldNetworkObjectDestroy", self, self.WorldNetworkObjectDestroy)

    Events:Subscribe(var("Inventory/LootboxCreate"):get(), self, self.LootboxCreate)
    Events:Subscribe(var("Inventory/LootboxRemove"):get(), self, self.LootboxRemove)
end

function cC4s:PlayC4TriggerAnimation()
    LocalPlayer:SetLeftArmState(AnimationState.LaSTriggerBoom)
end

function cC4s:LootboxCreate(args)

    if args.tier ~= 11 and args.tier ~= 12 and args.tier ~= 13 then return end

    self.near_stashes[args.cso_id] = args.id

end

function cC4s:LootboxRemove(args)

    if args.tier ~= 11 and args.tier ~= 12 and args.tier ~= 13 then return end

    self.near_stashes[args.cso_id] = nil

end

function cC4s:WorldNetworkObjectCreate(args)
    if self.c4s[args.object:GetId()] then return end

    self.c4s[args.object:GetId()] = cC4({
        position = args.object:GetPosition(),
        angle = args.object:GetAngle(),
        attach_entity = args.object:GetValue("AttachEntity"),
        values = args.object:GetValue("Values")
    })

end

function cC4s:WorldNetworkObjectDestroy(args)
    if not self.c4s[args.object:GetId()] then return end

    self.c4s[args.object:GetId()]:Remove()
    self.c4s[args.object:GetId()] = nil

end

function cC4s:StartC4Placement()

    Events:Fire("build/StartObjectPlacement", {
        model = 'f1t05bomb01.eez/key019_01-z.lod',
        display_bb = true,
        offset = Vector3(0, 0.05, 0),
        place_entity = true,
        range = 6
    })

    self.place_subs = 
    {
        Events:Subscribe("build/PlaceObject", self, self.PlaceObject),
        Events:Subscribe("build/CancelObjectPlacement", self, self.CancelObjectPlacement)
    }
    
    self.placing_c4 = true
end

function cC4s:PlaceObject(args)
    if not self.placing_c4 then return end

    args.values = {}
    local entity = args.forward_ray.entity
    
    if entity and table.find({"LocalPlayer", "Player", "Vehicle"}, entity.__type) then

        if entity.__type == "LocalPlayer" or entity.__type == "Player" then
            local closestBone = nil

            for k, bone in pairs(entity:GetBones()) do
                if not closestBone 
                or bone.position:Distance(args.forward_ray.position) < closestBone.position:Distance(args.forward_ray.position) then
                    args.values.parent_bone = k
                    args.values.position_offset = -bone.angle * (args.forward_ray.position - bone.position)
                    args.values.angle_offset = -bone.angle * args.angle

                    closestBone = bone
                end
            end

        else
            args.values.position_offset = -entity:GetAngle() * (args.forward_ray.position - entity:GetPosition())
            args.values.angle_offset = -entity:GetAngle() * args.angle
        end
    end

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 7)

    local send_data = {
        position = args.position,
        angle = args.angle,
        values = args.values,
        forward_ray = args.forward_ray
    }

    -- If they are placing the explosive on a stash/lootbox
    if ray.entity and ray.entity.__type == "ClientStaticObject" then

        if self.near_stashes[ray.entity:GetId()] then
            send_data.lootbox_uid = self.near_stashes[ray.entity:GetId()]
        end

    end

    Network:Send("items/PlaceC4", send_data)

    self:StopPlacement()
end

function cC4s:CancelObjectPlacement()
    Network:Send("items/CancelC4Placement")
    self:StopPlacement()
end

function cC4s:StopPlacement()
    for k, v in pairs(self.place_subs) do
        Events:Unsubscribe(v)
    end

    self.place_subs = {}
    self.placing_c4 = false
end

function cC4s:C4Explode(args)

    if self.c4s[args.id] then
        args.position = self.c4s[args.id].object:GetPosition()
    end

    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        effect_id = 82,
        angle = Angle()
    })

    -- Let HitDetection do the rest
    Events:Fire(var("HitDetection/Explosion"):get(), {
        position = args.position,
        local_position = LocalPlayer:GetPosition(),
        type = DamageEntity.C4,
        attacker_id = args.owner_id
    })

end

function cC4s:ModuleUnload()

    for id, c4 in pairs(self.c4s) do
        c4:Remove()
    end

end

cC4s = cC4s()