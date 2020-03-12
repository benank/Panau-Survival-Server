class 'cMine'

function cMine:__init(args)

    self.position = args.position
    self.id = args.id
    self.owner_id = args.owner_id
    self.cell_x, self.cell_y = GetCell(self.position, ItemsConfig.usables.Mine.cell_size)

    self:CreateMine()

    self.subs = 
    {
        Events:Subscribe(var("ShapeTriggerEnter"):get(), self, self.ShapeTriggerEnter)
    }

end

function cMine:ShapeTriggerEnter(args)
    if args.trigger ~= self.shapetrigger then return end
    if args.entity.__type ~= "LocalPlayer" then return end
    if args.entity ~= LocalPlayer then return end
    if self.owner_id == tostring(LocalPlayer:GetSteamId()) then return end -- Don't explode on the owner

    Network:Send(var("items/StepOnMine"):get(), {id = self.id})
end

function cMine:GetCell()
    return {x = self.cell_x, y = self.cell_y}
end

function cMine:CreateMine()

    local radius = ItemsConfig.usables.Mine.explode_radius

    self.shapetrigger = ShapeTrigger.Create({
        position = self.position,
        angle = Angle(),
        components = {
            {
                type = TriggerType.Sphere,
                size = Vector3(radius,radius,radius),
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
    self.object:Remove()
    self.shapetrigger:Remove()
    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
        v = nil
    end
end