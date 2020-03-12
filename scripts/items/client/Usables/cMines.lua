class 'cMines'

function cMines:__init(args)

    self.mine_cells = {} -- Mines in cells

    Network:Subscribe(var("items/MineSyncOne"):get(), self, self.MineSyncOne)
    Network:Subscribe(var("items/MineExplode"):get(), self, self.MineExplode)
    Network:Subscribe(var("items/MinesCellsSync"):get(), self, self.MinesCellsSync)

    Events:Subscribe(var("Cells/LocalPlayerCellUpdate"):get() 
        .. tostring(ItemsConfig.usables.Mine.cell_size), self, self.LocalPlayerCellUpdate)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cMines:AddMine(args)

    local mine = cMine({
        position = args.position,
        id = args.id,
        owner_id = args.owner_id
    })

    local cell = mine:GetCell()
    VerifyCellExists(self.mine_cells, cell)

    if self.mine_cells[cell.x][cell.y][mine.id] then
        self.mine_cells[cell.x][cell.y][mine.id]:Remove()
    end

    self.mine_cells[cell.x][cell.y][mine.id] = mine

end

function cMines:MineSyncOne(args)
    self:AddMine(args)
end

function cMines:MineExplode(args)

    for x, _ in pairs(self.mine_cells) do
        for y, _ in pairs(self.mine_cells[x]) do
            for id, mine in pairs(self.mine_cells[x][y]) do
                if id == args.id then
                    self.mine_cells[x][y][id]:Remove()
                    self.mine_cells[x][y][id] = nil
                end
            end
        end
    end

    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        effect_id = 20,
        angle = Angle()
    })

end

function cMines:MinesCellsSync(args)

    for _, mine_data in pairs(args.mine_data) do
        self:AddMine(mine_data)
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