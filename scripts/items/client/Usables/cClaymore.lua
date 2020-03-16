class 'cClaymore'

function cClaymore:__init(args)

    self.position = args.position
    self.angle = args.angle
    self.id = args.id
    self.owner_id = args.owner_id
    self.cell_x, self.cell_y = GetCell(self.position, ItemsConfig.usables.Claymore.cell_size)

    self:CreateClaymore()

    self.subs = 
    {
        Events:Subscribe(var("ShapeTriggerEnter"):get(), self, self.ShapeTriggerEnter)
    }

end

function cClaymore:ShapeTriggerEnter(args)
    if args.trigger ~= self.shapetrigger then return end
    if args.entity.__type ~= "LocalPlayer" then return end
    if args.entity ~= LocalPlayer then return end
    if self.owner_id == tostring(LocalPlayer:GetSteamId()) then return end -- Don't explode on the owner

    Network:Send(var("items/StepOnClaymore"):get(), {id = self.id})
    cClaymores:ClaymoreExplode({position = self.position, id = self.id})
end

function cClaymore:GetCell()
    return {x = self.cell_x, y = self.cell_y}
end

function cClaymore:CreateClaymore()

    local radius = ItemsConfig.usables.Claymore.trigger_radius

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
        angle = self.angle,
        model = 'km05.blz/gp703-a.lod',
        collision = 'km05.blz/gp703_lod1-a_col.pfx'
    })

end

function cClaymore:Remove()
    self.object:Remove()
    self.shapetrigger:Remove()
    for k,v in pairs(self.subs) do
        Events:Unsubscribe(v)
        v = nil
    end
end