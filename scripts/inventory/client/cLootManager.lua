class 'cLootManager'

function cLootManager:__init()

    self.loot = {} -- Create 2D array to store loot in cells
    self.objects = {}
    self.current_box = nil -- Current opened box
    self.close_to_box = false -- If they are close enough to a box that we should raycast

    self.SO_id_to_uid = {} -- Static object ids to lootbox unique ids

    self.look_at_circle_size = Render.Size.x * 0.0075
    self.look_at_circle_size_inner = self.look_at_circle_size * 0.85
    self.up = Vector3(0, 0.1, 0)

    self:CheckIfCloseToBox()

    Network:Subscribe(var("Inventory/LootboxCellsSync"):get(), self, self.LootboxCellsSync)
    Network:Subscribe(var("Inventory/OneLootboxCellSync"):get(), self, self.OneLootboxCellSync)
    Network:Subscribe(var("Inventory/RemoveLootbox"):get(), self, self.RemoveLootbox)
    Network:Subscribe(var("Inventory/ForceCloseLootbox"):get(), self, self.ForceCloseLootbox)
    
    Events:Subscribe("ModuleUnload", self, self.Unload)
    Events:Subscribe(var("LocalPlayerChat"):get(), self, self.LocalPlayerChat)

    Events:Subscribe("Cells/LocalPlayerCellUpdate" .. tostring(Lootbox.Cell_Size), self, self.LocalPlayerCellUpdate)

    if IsAdmin(LocalPlayer) then
        self.stash_render = Events:Subscribe("Render", self, self.StashRender)
    end

end

function cLootManager:LocalPlayerChat(args)

    if not IsAdmin(LocalPlayer) then return end

    if args.text == "/showstashes" then
        if not self.stash_render then
            self.stash_render = Events:Subscribe("Render", self, self.StashRender)
        else
            self.stash_render = Events:Unsubscribe(self.stash_render)
        end
    end

end

function cLootManager:StashRender(args)

    if not IsAdmin(LocalPlayer) then return end

    for x, data in pairs(self.loot) do
        for y, data in pairs(self.loot[x]) do
            for id, box in pairs(self.loot[x][y]) do
                if Lootbox.Stashes[box.tier] then
                    local pos, on_screen = Render:WorldToScreen(box.position)
                    if on_screen then
                        Render:FillCircle(pos, 12, Color.Black)
                        Render:FillCircle(pos, 10, Color.Red)
                        Render:DrawText(pos + Vector2(22, 2), box.stash.owner_id, Color.Black, 24)
                        Render:DrawText(pos + Vector2(20, 0), box.stash.owner_id, Color.Red, 24)
                    end
                end
            end
        end
    end

end

function cLootManager:LocalPlayerCellUpdate(args)

    -- Remove loot from old cells
    for _, cell in pairs(args.old_adjacent) do
        self:ClearCell(cell)
    end

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

    VerifyCellExists(self.loot, args.cell)
    if self.loot[args.cell.x][args.cell.y][args.uid] then
        self.loot[args.cell.x][args.cell.y][args.uid]:Remove()
        self.loot[args.cell.x][args.cell.y][args.uid] = nil
    end

end


function cLootManager:Render(args)

    if not ClientInventory or not ClientInventory.lootbox_ui then return end

    local cam_pos = Camera:GetPosition()
    local cam_ang = Camera:GetAngle()

    if IsNaN(cam_pos.x) or IsNaN(cam_pos.y) or IsNaN(cam_pos.z) then return end
    if IsNaN(cam_ang.pitch) or IsNaN(cam_ang.yaw) or IsNaN(cam_ang.roll) then return end

    local ray = Physics:Raycast(cam_pos, cam_ang * Vector3.Forward, 0, 6.5)
    local found_box = false

    if ray.entity and ray.entity.__type == "ClientStaticObject" then

        local uid = self:StaticObjectIdToUID(ray.entity:GetId())
        local entity_pos = ray.entity:GetPosition()
        local cell = GetCell(entity_pos, Lootbox.Cell_Size)

        VerifyCellExists(self.loot, cell)
        if not uid or not self.loot[cell.x][cell.y][uid] then return end
        if Vector3.Distance(entity_pos, LocalPlayer:GetPosition()) > Lootbox.Distances.Can_Open then return end

        local box = self.loot[cell.x][cell.y][uid]

        self.current_looking_box = box
        found_box = true

        if not ClientInventory.lootbox_ui.window:GetVisible() then
            -- Draw circle to indicate that it can be opened
            if box.look_position and self.up then
                local pos = Render:WorldToScreen(box.look_position + self.up)
                Render:FillCircle(pos, self.look_at_circle_size, Color.White)
                Render:FillCircle(pos, self.look_at_circle_size_inner, Lootbox.LookAtColor)
                LocalPlayer:SetValue("LookingAtLootbox", true)
            end
        end

    end

    local dist = IsValid(self.current_looking_box)
        and LocalPlayer:GetPosition():Distance(self.current_looking_box.position)
        or 99

    if not found_box and (not ClientInventory.lootbox_ui.window:GetVisible() or dist > Lootbox.Distances.Can_Open) then 

        if ClientInventory.lootbox_ui.window:GetVisible() then
            ClientInventory.lootbox_ui:ToggleVisible()
        end

        self.current_looking_box = nil
        self.current_box = nil

        LocalPlayer:SetValue("LookingAtLootbox", false)

    end

end

function cLootManager:RecreateContents(_contents)

    local contents = {}

    local index = 1

    -- Create new shItem and shStack instances for the client
    for k,v in pairs(_contents) do

        local items = {}

        for i, j in ipairs(v.contents) do
            if (type(j) == "userdata" or count_table(j) > 0) 
            and j.name and j.amount and j.amount >= 1 and j.category and j.stacklimit then
                items[i] = shItem(j)
            end
        end

        if count_table(items) > 0 then
            contents[index] = shStack({contents = items, uid = v.uid})
            index = index + 1
        end

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
    local player_cell = GetCell(player_pos, Lootbox.Cell_Size)

    -- TODO optimize this (but still needs to check for boxes in adjacent cells)

    local adjacent_cells = GetAdjacentCells(player_cell)

    for _, cell in pairs(adjacent_cells) do

        VerifyCellExists(self.loot, cell)
        for _, box in pairs(self.loot[cell.x][cell.y]) do

            if Vector3.Distance(box.position, player_pos) < Lootbox.Distances.Start_Raycast then

                return true

            end

        end

    end

    return false

end

function cLootManager:OneLootboxCellSync(data)

    VerifyCellExists(self.loot, data.cell)
    if self.loot[data.cell.x][data.cell.y][data.uid] then
        self.loot[data.cell.x][data.cell.y][data.uid]:Remove()
    end

    if data.active then
        self.loot[data.cell.x][data.cell.y][data.uid] = cLootbox(data)
    end

end

function cLootManager:LootboxCellsSync(data)
    
    -- spawn the boxes that the server has already for newly streamed cells
    Thread(function()
    for _, box_data in pairs(data.lootbox_data) do
        
        VerifyCellExists(self.loot, box_data.cell)
        
        if self.loot[box_data.cell.x][box_data.cell.y][box_data.uid] then
            self.loot[box_data.cell.x][box_data.cell.y][box_data.uid]:Remove()
        end

        if box_data.active then
            self.loot[box_data.cell.x][box_data.cell.y][box_data.uid] = cLootbox(box_data)
            Timer.Sleep(2)
        end
    end
    end)

end

function cLootManager:ClearCell(cell)

    VerifyCellExists(self.loot, cell)

    for uid, lootbox in pairs(self.loot[cell.x][cell.y]) do

        lootbox:Remove()
        self.loot[cell.x][cell.y][uid] = nil

    end

    self.loot[cell.x][cell.y] = {}

end

function cLootManager:Unload()

    for x, _ in pairs(self.loot) do
        for y, _ in pairs(self.loot[x]) do
            self:ClearCell({x = x, y = y})
        end
    end

end

LootManager = cLootManager()