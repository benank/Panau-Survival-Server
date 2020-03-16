class 'cClaymores'

function cClaymores:__init(args)

    self.claymore_cells = {} -- Claymores in cells
    self.pickup_key = 'E'
    self.pickup_timer = Timer()
    self.CSO_register = {}

    self.placing_claymore = false

    self.blockedActions = {
        [Action.FireLeft] = true,
        [Action.FireRight] = true,
        [Action.McFire] = true,
        [Action.HeliTurnRight] = true,
        [Action.HeliTurnLeft] = true,
        [Action.VehicleFireLeft] = true,
        [Action.ThrowGrenade] = true,
        [Action.VehicleFireRight] = true,
        [Action.Reverse] = true,
        [Action.UseItem] = true,
        [Action.GuiPDAToggleAOI] = true,
        [Action.GrapplingAction] = true,
        [Action.PickupWithLeftHand] = true,
        [Action.PickupWithRightHand] = true,
        [Action.ActivateBlackMarketBeacon] = true,
        [Action.GuiPDAZoomOut] = true,
        [Action.GuiPDAZoomIn] = true,
        [Action.NextWeapon] = true,
        [Action.PrevWeapon] = true,
        [Action.ExitVehicle] = true
    }

    Events:Subscribe(var("Cells/LocalPlayerCellUpdate"):get() 
        .. tostring(ItemsConfig.usables.Claymore.cell_size), self, self.LocalPlayerCellUpdate)

    Events:Subscribe(var("FireWeapon"):get(), self, self.FireWeapon)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

    Events:Subscribe("KeyUp", self, self.KeyUp)
    
    Network:Subscribe(var("items/StartClaymorePlacement"):get(), self, self.StartClaymorePlacement)
    Network:Subscribe(var("items/ClaymorePlaceSound"):get(), self, self.ClaymorePlaceSound)
    Network:Subscribe(var("items/ClaymoreSyncOne"):get(), self, self.ClaymoreSyncOne)
    Network:Subscribe(var("items/ClaymoreExplode"):get(), self, self.ClaymoreExplode)
    Network:Subscribe(var("items/ClaymoresCellsSync"):get(), self, self.ClaymoresCellsSync)
    Network:Subscribe(var("items/RemoveClaymore"):get(), self, self.RemoveClaymore)

end

function cClaymores:StartClaymorePlacement()

    self.yaw = 0

    self.obj = ClientStaticObject.Create({
        position = Vector3(),
        angle = Angle(),
        model = 'km05.blz/gp703-a.lod'
    })

    self.place_subs = 
    {
        Events:Subscribe("Render", self, self.Render),
        Events:Subscribe("MouseScroll", self, self.MouseScroll),
        Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput),
        Events:Subscribe("MouseUp", self, self.MouseUp)
    }
    
    self.placing_claymore = true
end

function cClaymores:LocalPlayerInput(args)
    if self.blockedActions[args.input] then return false end
end

function cClaymores:MouseScroll(args)
    if not self.placing_claymore then return end
    if not IsValid(self.obj) then return end

    local change = math.ceil(args.delta)
    self.yaw = self.yaw + change * math.pi / 6
end

function cClaymores:MouseUp(args)
    if not self.placing_claymore then return end
    if not IsValid(self.obj) then return end

    if args.button == 1 then
        -- Left click, place claymore
        Network:Send("items/PlaceClaymore", {
            position = self.obj:GetPosition(),
            angle = self.obj:GetAngle()
        })
        self:StopPlacement()
    elseif args.button == 2 then 
        -- Right click, cancel placement
        Network:Send("items/CancelClaymorePlacement")
        self:StopPlacement()
    end
end

function cClaymores:StopPlacement()
    for k, v in pairs(self.place_subs) do
        Events:Unsubscribe(v)
    end
    self.place_subs = {}
    self.placing_claymore = false

    if IsValid(self.obj) then
        self.obj:Remove()
    end
end

function cClaymores:Render(args)

    if not self.placing_claymore then return end
    if not IsValid(self.obj) then return end

    local ray1 = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 6)

    local ray2 = Physics:Raycast(ray1.position + Vector3.Up, Vector3.Down, 0, 15)

    if ray2.position:Distance(LocalPlayer:GetPosition()) > 5 then return end
    if ray2.entity and ray2.entity.__type ~= "ClientStaticObject" then return end


    self.obj:SetPosition(ray2.position)
    local ang = Angle.FromVectors(Vector3.Up, ray2.normal) * Angle(self.yaw, 0, 0)
    self.obj:SetAngle(ang)

end

function cClaymores:StartPlacingClaymore()

    self.object = ClientStaticObject.Create({
        position = self.position,
        angle = self.angle,
        model = 'km05.blz/gp703-a.lod',
        collision = 'km05.blz/gp703_lod1-a_col.pfx'
    })

    -- TODO

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

        local cell_x, cell_y = GetCell(ray.position, ItemsConfig.usables.Claymore.cell_size)
        VerifyCellExists(self.claymore_cells, {x = cell_x, y = cell_y})

        if not ray.entity then return end
        if ray.entity.__type ~= "ClientStaticObject" then return end

        local claymore = self.CSO_register[ray.entity:GetId()]
        if not claymore then return end

        if claymore.owner_id ~= tostring(LocalPlayer:GetSteamId()) then return end

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
        type = "Claymore"
    })

end

function cClaymores:ClaymoresCellsSync(args)

    for _, claymore_data in pairs(args.claymore_data) do
        self:AddClaymore(claymore_data)
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