class 'cClaymores'

function cClaymores:__init(args)

    self.claymore_cells = {} -- Claymores in cells
    self.pickup_key = 'E'
    self.pickup_timer = Timer()
    self.CSO_register = {}

    self.placing_claymore = false

    Events:Subscribe(var("Cells/LocalPlayerCellUpdate"):get() 
        .. tostring(ItemsConfig.usables.Claymore.cell_size), self, self.LocalPlayerCellUpdate)

    Events:Subscribe(var("FireWeapon"):get(), self, self.FireWeapon)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("KeyUp", self, self.KeyUp)
    Events:Subscribe("GameRender", self, self.GameRender)
    
    Network:Subscribe(var("items/StartClaymorePlacement"):get(), self, self.StartClaymorePlacement)
    Network:Subscribe(var("items/ClaymorePlaceSound"):get(), self, self.ClaymorePlaceSound)
    Network:Subscribe(var("items/ClaymoreSyncOne"):get(), self, self.ClaymoreSyncOne)
    Network:Subscribe(var("items/ClaymoreExplode"):get(), self, self.ClaymoreExplode)
    Network:Subscribe(var("items/ClaymoresCellsSync"):get(), self, self.ClaymoresCellsSync)
    Network:Subscribe(var("items/RemoveClaymore"):get(), self, self.RemoveClaymore)

end

function cClaymores:GameRender(args)
    for x, _ in pairs(self.claymore_cells) do
        for y, _ in pairs(self.claymore_cells[x]) do
            for _, claymore in pairs(self.claymore_cells[x][y]) do
                claymore:Render()
            end
        end
    end
end

function cClaymores:StartClaymorePlacement()

    Events:Fire("build/StartObjectPlacement", {
        model = 'km05.blz/gp703-a.lod',
        disable_ceil = true
    })

    self.place_subs = 
    {
        Events:Subscribe("ObjectPlacerGameRender", self, self.Render),
        Events:Subscribe("build/PlaceObject", self, self.PlaceObject),
        Events:Subscribe("build/CancelObjectPlacement", self, self.CancelObjectPlacement)
    }
    
    self.placing_claymore = true
end

function cClaymores:PlaceObject(args)
    if not self.placing_claymore then return end

    if args.entity and args.entity.__type == "ClientStaticObject" then
        args.model = args.entity:GetModel()
    end

    Network:Send("items/PlaceClaymore", {
        position = args.position,
        angle = args.angle,
        model = args.model
    })
    self:StopPlacement()
end

function cClaymores:CancelObjectPlacement()
    Network:Send("items/CancelClaymorePlacement")
    self:StopPlacement()
end

function cClaymores:StopPlacement()
    for k, v in pairs(self.place_subs) do
        Events:Unsubscribe(v)
    end

    self.place_subs = {}
    self.placing_claymore = false
end

function cClaymores:Render(args)

    if not self.placing_claymore then return end

    local angle = args.object:GetAngle() * Angle(math.pi / 2, 0, 0)
    local start_ray_pos = args.object:GetPosition() + angle * Vector3(0, 0.25, 0)

    local ray = Physics:Raycast(start_ray_pos, angle * Vector3.Forward, 0, ItemsConfig.usables.Claymore.trigger_range, false)

    local end_ray_pos = ray.position

    Render:DrawLine(
        start_ray_pos,
        end_ray_pos,
        Color(255, 0, 0, 255)
    )

end

function cClaymores:ClaymorePlaceSound(args)
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 11,
        sound_id = 2,
        position = args.position,
        angle = Angle()
    })

    sound:SetParameter(0,1)
end

function cClaymores:FireWeapon(args)
    local target = LocalPlayer:GetAimTarget()

    if not target.entity then return end
    if target.entity.__type ~= "ClientStaticObject" then return end

    local claymore = self.CSO_register[target.entity:GetId()]
    if not claymore then return end

    Network:Send(var("items/DestroyClaymore"):get(), {id = claymore.id})

end

function cClaymores:RemoveClaymore(args)
    VerifyCellExists(self.claymore_cells, args.cell)
    if self.claymore_cells[args.cell.x][args.cell.y][args.id] then
        local claymore = self.claymore_cells[args.cell.x][args.cell.y][args.id]
        self.CSO_register[claymore.object:GetId()] = nil
        self.claymore_cells[args.cell.x][args.cell.y][args.id]:Remove()
        self.claymore_cells[args.cell.x][args.cell.y][args.id] = nil
    end
end

function cClaymores:KeyUp(args)

    if args.key == string.byte(self.pickup_key) and self.pickup_timer:GetSeconds() > 1 then

        self.pickup_timer:Restart()

        local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 4.5)

        local cell = GetCell(ray.position, ItemsConfig.usables.Claymore.cell_size)
        VerifyCellExists(self.claymore_cells, cell)

        if not ray.entity then return end
        if ray.entity.__type ~= "ClientStaticObject" then return end

        local claymore = self.CSO_register[ray.entity:GetId()]
        if not claymore then return end

        --if claymore.owner_id ~= tostring(LocalPlayer:GetSteamId()) then return end

        Network:Send(var("items/PickupClaymore"):get(), {id = claymore.id})

    end

end

function cClaymores:AddClaymore(args)

    local claymore = cClaymore({
        position = args.position,
        angle = args.angle,
        id = args.id,
        owner_id = args.owner_id
    })

    local cell = claymore:GetCell()
    VerifyCellExists(self.claymore_cells, cell)

    if self.claymore_cells[cell.x][cell.y][claymore.id] then
        self.claymore_cells[cell.x][cell.y][claymore.id]:Remove()
    end

    self.CSO_register[claymore.object:GetId()] = claymore
    self.claymore_cells[cell.x][cell.y][claymore.id] = claymore

end

function cClaymores:ClaymoreSyncOne(args)
    self:AddClaymore(args)
end

function cClaymores:ClaymoreExplode(args)

    for x, _ in pairs(self.claymore_cells) do
        for y, _ in pairs(self.claymore_cells[x]) do
            for id, claymore in pairs(self.claymore_cells[x][y]) do
                if id == args.id then
                    if not args.position then
                        args.position = self.claymore_cells[x][y][id].position
                    end

                    self.claymore_cells[x][y][id]:Remove()
                    self.claymore_cells[x][y][id] = nil
                    self.CSO_register[claymore.object:GetId()] = nil

                    break
                end
            end
        end
    end

    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        effect_id = 20,
        angle = Angle()
    })

    -- Let HitDetection do the rest
    Events:Fire(var("HitDetection/Explosion"):get(), {
        position = args.position,
        local_position = LocalPlayer:GetPosition(),
        type = DamageEntity.Claymore,
        attacker_id = args.owner_id
    })

end

function cClaymores:ClaymoresCellsSync(args)

    if LocalPlayer:GetValue("Loading") then
        Timer.SetTimeout(250, function()
            self:ClaymoresCellsSync(args)
        end)
    elseif args.claymore_data then
        for _, claymore_data in pairs(args.claymore_data) do
            self:AddClaymore(claymore_data)
        end
    end

end

function cClaymores:LocalPlayerCellUpdate(args)

    -- Remove old claymores from old cells
    if count_table(args.old_adjacent) > 0 then

        for _, cell in pairs(args.old_adjacent) do
            self:ClearCell(cell)
        end

    end
end

function cClaymores:ClearCell(cell)

    VerifyCellExists(self.claymore_cells, cell)

    for id, claymore in pairs(self.claymore_cells[cell.x][cell.y]) do
        claymore:Remove()
    end

    self.claymore_cells[cell.x][cell.y] = {}
end

function cClaymores:ModuleUnload()
    for x, _ in pairs(self.claymore_cells) do
        for y, _ in pairs(self.claymore_cells[x]) do
            self:ClearCell({x = x, y = y})
        end
    end

    if IsValid(self.obj) then
        self.obj:Remove()
    end

end

cClaymores = cClaymores()