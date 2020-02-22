class 'cLootManager'

function cLootManager:__init()

    self.loot = GenerateCellArray() -- Create 2D array to store loot in cells
    self.current_box = nil -- Current opened box
    self.close_to_box = false -- If they are close enough to a box that we should raycast

    self.SO_id_to_uid = {} -- Static object ids to lootbox unique ids

    self.look_at_circle_size = Render.Size.x * 0.0075
    self.look_at_circle_size_inner = self.look_at_circle_size * 0.85
    self.up = Vector3(0, 0.3, 0)

    self:CheckIfCloseToBox()

    Network:Subscribe("Inventory/LootboxCellsSync", self, self.LootboxCellsSync)
    Network:Subscribe("Inventory/OneLootboxCellSync", self, self.OneLootboxCellSync)
    Network:Subscribe("Inventory/RemoveLootbox", self, self.RemoveLootbox)
    Network:Subscribe("Inventory/ForceCloseLootbox", self, self.ForceCloseLootbox)
    
    Events:Subscribe("ModuleUnload", self, self.Unload)

end

-- Forces the lootbox ui to close
function cLootManager:ForceCloseLootbox()

    self.current_looking_box = nil
    self.current_box = nil

    if ClientInventory.lootbox_ui.window:GetVisible() then
        ClientInventory.lootbox_ui:ToggleVisible()
    end

end

function cLootManager:RemoveLootbox(args)

    if self.loot[args.cell.x][args.cell.y][args.uid] then
        self.loot[args.cell.x][args.cell.y][args.uid]:Remove()
        self.loot[args.cell.x][args.cell.y][args.uid] = nil
    end

end


function cLootManager:Render(args)

    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 4.2)
    local found_box = false

    if ray.entity and ray.entity.__type == "ClientStaticObject" then

        local uid = self:StaticObjectIdToUID(ray.entity:GetId())
        local entity_pos = ray.entity:GetPosition()
        local cell_x, cell_y = GetCell(entity_pos)

        if not uid or not self.loot[cell_x][cell_y][uid] then return end
        if Vector3.Distance(entity_pos, LocalPlayer:GetPosition()) > Lootbox.Distances.Can_Open then return end

        local box = self.loot[cell_x][cell_y][uid]

        self.current_looking_box = box
        found_box = true

        if not ClientInventory.lootbox_ui.window:GetVisible() then
            -- Draw circle to indicate that it can be opened
            local pos = Render:WorldToScreen(box.position + self.up)
            Render:FillCircle(pos, self.look_at_circle_size, Color.White)
            Render:FillCircle(pos, self.look_at_circle_size_inner, Lootbox.LookAtColor)
        end

    end

    if not found_box then 
        self.current_looking_box = nil
        self.current_box = nil

        if ClientInventory.lootbox_ui.window:GetVisible() then
            ClientInventory.lootbox_ui:ToggleVisible()
        end


    end

end

function cLootManager:RecreateContents(_contents)

    local contents = {}

    -- Create new shItem and shStack instances for the client
    for k,v in pairs(_contents) do

        local items = {}

        for i, j in ipairs(v.contents) do
            items[i] = shItem(j)
        end

        contents[k] = shStack({contents = items, uid = v.uid})

    end

    self.current_box.contents = contents


end

function cLootManager:StaticObjectIdToUID(id)
    return self.SO_id_to_uid[id]
end

function cLootManager:CheckIfCloseToBox()

    if self:IsOneBoxCloseEnough() then

        if not self.render_event then
            self.render_event = Events:Subscribe("Render", self, self.Render)
        end

        self.close_to_box = true

    else

        if self.render_event then
            Events:Unsubscribe(self.render_event)
            self.render_event = nil
        end

        self.close_to_box = false

    end

    Timer.SetTimeout(2500, function()
        self:CheckIfCloseToBox()
    end)

end

-- Returns true if one box is within the start_raycast distance
function cLootManager:IsOneBoxCloseEnough()

    local player_pos = LocalPlayer:GetPosition()
    local player_cell_x, player_cell_y = GetCell(player_pos)

    -- TODO optimize this (but still needs to check for boxes in adjacent cells)

    for x = player_cell_x - 1, player_cell_x + 1 do

        for y = player_cell_y - 1, player_cell_y + 1 do

            for _, box in pairs(self.loot[x][y]) do

                if Vector3.Distance(box.position, player_pos) < Lootbox.Distances.Start_Raycast then

                    return true

                end

            end

        end

    end

    return false

end

function cLootManager:OneLootboxCellSync(data)

    if self.loot[data.cell.x][data.cell.y][data.uid] then
        self.loot[data.cell.x][data.cell.y][data.uid]:Remove()
        --debug("WARN: OneLootboxCellSync box already existed! Removing and replacing with new box")
        -- TODO: fix resync of lootboxes
    end

    self.loot[data.cell.x][data.cell.y][data.uid] = cLootbox(data)

end

function cLootManager:LootboxCellsSync(data)
	--debug("entered lootboxcellssync on client")
	
	-- spawn the boxes that the server has already for newly streamed cells
    for _, box_data in pairs(data.lootbox_data) do
		
		-- TODO: fix it respawning every box when the cell's loot is updated
        if self.loot[box_data.cell.x][box_data.cell.y][box_data.uid] then
            self.loot[box_data.cell.x][box_data.cell.y][box_data.uid]:Remove()
            --debug("WARN: OneLootboxCellSync box already existed! Removing and replacing with new box")
            -- TODO: fix resync of lootboxes
        end

        self.loot[box_data.cell.x][box_data.cell.y][box_data.uid] = cLootbox(box_data)
    end

end

function cLootManager:ClearCell(cell)

    if not self.loot[cell.x] or not self.loot[cell.x][cell.y] then return end

    for uid, lootbox in pairs(self.loot[cell.x][cell.y]) do

        lootbox:Remove()
        self.loot[cell.x][cell.y][uid] = nil

    end

    self.loot[cell.x][cell.y] = {}

end

function cLootManager:Unload()

    for x = 1, #self.loot do
        for y = 1, #self.loot[x] do
            self:ClearCell({x = x, y = y})
        end
    end

end

LootManager = cLootManager()