class 'cC4s'

function cC4s:__init(args)

    self.c4s = {} -- [wno id] = cC4() 

    self.placing_claymore = false

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    
    Network:Subscribe(var("items/StartC4Placement"):get(), self, self.StartC4Placement)
    Network:Subscribe(var("items/C4Explode"):get(), self, self.C4Explode)

end

function cC4s:StartC4Placement()

    Events:Fire("build/StartObjectPlacement", {
        model = 'f1t05bomb01.eez/key019_01-z.lod',
        display_bb = true,
        offset = Vector3(0, 0.05, 0)
    })

    self.place_subs = 
    {
        Events:Subscribe("build/PlaceObject", self, self.PlaceObject),
        Events:Subscribe("build/CancelObjectPlacement", self, self.CancelObjectPlacement)
    }
    
    self.placing_c4 = true
end

function cC4s:PlaceObject(args)
    if not self.placing_claymore then return end

    Network:Send("items/PlaceC4", {
        position = args.position,
        angle = args.angle
    })
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

    -- TODO: remove C4

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