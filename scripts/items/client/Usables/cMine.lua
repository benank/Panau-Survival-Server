class 'cMine'

function cMine:__init(args)

    self.position = args.position
    self.angle = args.angle
    self.id = args.id
    self.owner_id = args.owner_id
    self.exploding = false
    self.cell = GetCell(self.position, ItemsConfig.usables.Mine.cell_size)

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
    if AreFriends(LocalPlayer, self.owner_id) then return end -- Owner is a friend
    if LocalPlayer:GetValue("Invincible") then return end

    self.exploding = true
    Network:Send(var("items/StepOnMine"):get(), {id = self.id})
    cMines:MineTrigger({position = self.position, id = self.id, owner_id = self.owner_id})
end

function cMine:GetCell()
    return self.cell
end

function cMine:CreateMine()

    local radius = ItemsConfig.usables.Mine.trigger_radius

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
        position = self.position + self.angle * Vector3(0, 0, 0.02),
        angle = self.angle,
        model = "f2m07.researchfacility.flz/key028_01-b.lod",
        collision = "f2m07.researchfacility.flz/key028_01_lod1-b_col.pfx"
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