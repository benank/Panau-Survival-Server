local NetName = var("items/StepOnMine")
local STE = var("ShapeTriggerEnter")

class 'cMine'

function cMine:__init(args)

    self.position = args.position
    self.id = args.id
    self.owner_id = args.owner_id

    self:CreateMine()

    self.subs = 
    {
        Events:Subscribe(STE:get(), self, self.ShapeTriggerEnter)
    }
end

function cMine:ShapeTriggerEnter()
    if args.trigger ~= self.shapetrigger or args.entity ~= LocalPlayer then return end
    if self.owner_id == tostring(LocalPlayer:GetSteamId()) then return end -- Don't explode on the owner

    Network:Send(NetName:get(), {id = self.id})
end

function cMine:CreateMine()

    self.shapetrigger = ShapeTrigger.Create({
        position = self.position,
        angle = Angle(),
        components = {
            {
                type = TriggerType.Sphere,
                size = Vector3(1,1,1),
                position = Vector3(0,0,0)
            }
        },
        trigger_player = true,
        trigger_player_in_vehicle = true,
        trigger_vehicle = true,
        trigger_npc = false,
        vehicle_type = VehicleTriggerType.All
    })

    self.object = ClientStaticObject.Create({
        position = self.position,
        angle = Angle(),
        model = "general.blz/go063-b2.lod"
    })

end

function cMine:Remove()
    self.shapetrigger:Remove()
    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
        v = nil
    end
    self.object:Remove()
end