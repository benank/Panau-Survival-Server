class 'cMines'

function cMines:__init(args)

    self.mine_cells = {} -- Mines in cells
    self.pickup_key = 'E'
    self.pickup_timer = Timer()
    self.CSO_register = {}

    Events:Subscribe(var("Cells/LocalPlayerCellUpdate"):get() 
        .. tostring(ItemsConfig.usables.Mine.cell_size), self, self.LocalPlayerCellUpdate)

    Events:Subscribe(var("FireWeapon"):get(), self, self.FireWeapon)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

    Events:Subscribe("KeyUp", self, self.KeyUp)
    
    Network:Subscribe(var("items/MinePlaceSound"):get(), self, self.MinePlaceSound)
    Network:Subscribe(var("items/MineSyncOne"):get(), self, self.MineSyncOne)
    Network:Subscribe(var("items/MineTrigger"):get(), self, self.MineTrigger)
    Network:Subscribe(var("items/MinesCellsSync"):get(), self, self.MinesCellsSync)
    Network:Subscribe(var("items/RemoveMine"):get(), self, self.RemoveMine)
    Network:Subscribe(var("items/MineDestroy"):get(), self, self.MineDestroy)

end

function cMines:MinePlaceSound(args)
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 11,
        sound_id = 2,
        position = args.position,
        angle = Angle()
    })

    sound:SetParameter(0,1)
end

function cMines:MineDestroy(args)
    --[[ClientEffect.Play(AssetLocation.Game, {
        position = args.pos,
        angle = Angle(),
        effect_id = 28
    })]]
    self:MineExplode(args)
end

function cMines:FireWeapon(args)
    local target = LocalPlayer:GetAimTarget()

    if not target.entity then return end
    if target.entity.__type ~= "ClientStaticObject" then return end

    local mine = self.CSO_register[target.entity:GetId()]
    if not mine then return end

    Network:Send(var("items/DestroyMine"):get(), {id = mine.id})

end

function cMines:RemoveMine(args)
    VerifyCellExists(self.mine_cells, args.cell)
    if self.mine_cells[args.cell.x][args.cell.y][args.id] then
        local mine = self.mine_cells[args.cell.x][args.cell.y][args.id]
        self.CSO_register[mine.object:GetId()] = nil
        self.mine_cells[args.cell.x][args.cell.y][args.id]:Remove()
        self.mine_cells[args.cell.x][args.cell.y][args.id] = nil
    end
end

function cMines:KeyUp(args)

    if args.key == string.byte(self.pickup_key) and self.pickup_timer:GetSeconds() > 1 then

        self.pickup_timer:Restart()

        local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 4.5)

        local cell = GetCell(ray.position, ItemsConfig.usables.Mine.cell_size)
        VerifyCellExists(self.mine_cells, cell)

        if not ray.entity then return end
        if ray.entity.__type ~= "ClientStaticObject" then return end

        local mine = self.CSO_register[ray.entity:GetId()]
        if not mine then return end

        Network:Send(var("items/PickupMine"):get(), {id = mine.id})

    end

end

function cMines:AddMine(args)

    local mine = cMine({
        position = args.position,
        angle = args.angle,
        id = args.id,
        owner_id = args.owner_id
    })

    local cell = mine:GetCell()
    VerifyCellExists(self.mine_cells, cell)

    if self.mine_cells[cell.x][cell.y][mine.id] then
        self.mine_cells[cell.x][cell.y][mine.id]:Remove()
    end

    self.CSO_register[mine.object:GetId()] = mine
    self.mine_cells[cell.x][cell.y][mine.id] = mine

end

function cMines:MineSyncOne(args)
    self:AddMine(args)
end

function cMines:MineTrigger(args)

    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 11,
        sound_id = 1,
        position = args.position,
        angle = Angle()
    })

    local trigger_time = ItemsConfig.usables.Mine.trigger_time

    sound:SetParameter(0,3 - trigger_time) -- Start time, 0-3
    sound:SetParameter(1,0.75)
    sound:SetParameter(2,0)


    Timer.SetTimeout(trigger_time * 1000, function()
        self:MineExplode(args)
        sound:Remove()
    end)

end

function cMines:MineExplode(args)

    local found_mine = false

    for x, _ in pairs(self.mine_cells) do
        for y, _ in pairs(self.mine_cells[x]) do
            for id, mine in pairs(self.mine_cells[x][y]) do
                if id == args.id then
                    if not args.position then
                        args.position = self.mine_cells[x][y][id].position
                    end

                    self.mine_cells[x][y][id]:Remove()
                    self.mine_cells[x][y][id] = nil
                    self.CSO_register[mine.object:GetId()] = nil

                    found_mine = true

                    break
                end
            end
        end
    end

    if not found_mine then return end -- Someone picked up the mine before it explodedF

    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        effect_id = 20,
        angle = Angle()
    })

    -- Let HitDetection do the rest
    Events:Fire(var("HitDetection/Explosion"):get(), {
        position = args.position,
        local_position = LocalPlayer:GetPosition(),
        type = DamageEntity.Mine,
        attacker_id = args.owner_id
    })

end

function cMines:MinesCellsSync(args)

    if LocalPlayer:GetValue("Loading") then
        Timer.SetTimeout(250, function()
            self:MinesCellsSync(args)
        end)
    else
        
        for _, mine_data in pairs(args.mine_data) do
            self:AddMine(mine_data)
        end

    end


end

function cMines:LocalPlayerCellUpdate(args)

    -- Remove old mines from old cells
    if count_table(args.old_adjacent) > 0 then

        for _, cell in pairs(args.old_adjacent) do
            self:ClearCell(cell)
        end

    end
end

function cMines:ClearCell(cell)

    VerifyCellExists(self.mine_cells, cell)

    for id, mine in pairs(self.mine_cells[cell.x][cell.y]) do
        mine:Remove()
    end

    self.mine_cells[cell.x][cell.y] = {}
end

function cMines:ModuleUnload()
    for x, _ in pairs(self.mine_cells) do
        for y, _ in pairs(self.mine_cells[x]) do
            self:ClearCell({x = x, y = y})
        end
    end

end

cMines = cMines()