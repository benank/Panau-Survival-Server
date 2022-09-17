class 'sLootHotspots'

function sLootHotspots:__init()
    self.cell_size = 128
    self.hotspot_cells = {} -- Table of [hotspot_name] = {min_cell = cell, max_cell = cell}
    
    -- Enable to print current hotspot
    -- Timer.SetInterval(1000 * 5, function()
    --     for p in Server:GetPlayers() do
    --         print(self:GetHotspotForPosition(p:GetPosition())) 
    --     end
    -- end)

end

function sLootHotspots:ModuleLoad()
    for hotspot_name, data in pairs(LootHotspots) do
        local cell_mod = Vector3(data.radius, 0, data.radius)
        self.hotspot_cells[hotspot_name] = {
            min_cell = GetCell(data.position - cell_mod, self.cell_size),
            max_cell = GetCell(data.position + cell_mod, self.cell_size)
        }
    end
end

function sLootHotspots:GetHotspotForPosition(pos)
    if not pos then return end
    
    local cell = GetCell(pos, self.cell_size)
    
    for hotspot_name, data in pairs(self.hotspot_cells) do
        if cell.x >= data.min_cell.x
        and cell.x <= data.max_cell.x 
        and cell.y >= data.min_cell.y
        and cell.y <= data.max_cell.y then
            return hotspot_name
        end
    end
end

sLootHotspots = sLootHotspots()