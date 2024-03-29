class 'cLootManager'

function cLootManager:__init()

    self.loot = {} -- Create 2D array to store loot in cells
    self.objects = {}
    self.current_box = nil -- Current opened box
    self.current_vehicle_storage_box = nil -- Current vehicle storage lootbox
    self.close_to_box = false -- If they are close enough to a box that we should raycast

    self.look_at_circle_size = Render.Size.x * 0.0075
    self.look_at_circle_size_inner = self.look_at_circle_size * 0.85
    self.up = Vector3(0, 0.1, 0)

    self:CheckIfCloseToBox()

    Network:Subscribe(var("Inventory/LootboxCellsSync"):get(), self, self.LootboxCellsSync)
    Network:Subscribe(var("Inventory/OneLootboxCellSync"):get(), self, self.OneLootboxCellSync)
    Network:Subscribe(var("Inventory/RemoveLootbox"):get(), self, self.RemoveLootbox)
    Network:Subscribe(var("Inventory/ForceCloseLootbox"):get(), self, self.ForceCloseLootbox)
    Network:Subscribe(var("Inventory/GetGroundDataAtPos"):get(), self, self.GetGroundDataAtPos)
    
    Events:Subscribe("ModuleUnload", self, self.Unload)
    Events:Subscribe(var("LocalPlayerChat"):get(), self, self.LocalPlayerChat)

    Events:Subscribe("Cells/LocalPlayerCellUpdate" .. tostring(Lootbox.Cell_Size), self, self.LocalPlayerCellUpdate)
    
    Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)

    -- if IsAdmin(LocalPlayer) then
    --     self.stash_render = Events:Subscribe("Render", self, self.StashRender)
    -- end
    
    self.loot_radar_tiers = {
        [Lootbox.Types.Level1] = true, 
        [Lootbox.Types.Level2] = true, 
        [Lootbox.Types.Level3] = true, 
        [Lootbox.Types.DroneUnder30] = true
    }
    self.max_loot_radar_level = var(5)
    Events:Subscribe("PlayerExpUpdated", self, self.PlayerExpUpdated)
    self:PlayerExpUpdated()

end

function cLootManager:PlayerExpUpdated(_exp)
    local exp = _exp or LocalPlayer:GetValue("Exp")
    if not exp then return end
    
    if exp.level >= tonumber(self.max_loot_radar_level:get()) then
        if self.loot_radar_render then
            self.loot_radar_render = Events:Unsubscribe(self.loot_radar_render)
        end
        return
    end
    
    -- Player is low enough level to get loot radar
    if not self.loot_radar_render then
        self.loot_radar_render = Events:Subscribe("Render", self, self.RenderLootRadar)
    end
end

function cLootManager:GetGroundDataAtPos(args)
    local ray = Physics:Raycast(args.position, Vector3.Down, 0, 500)
    
    Network:Send("Inventory/GetGroundDataAtPos" .. tostring(args.ground_id), {
        position = ray.position,
        angle = Angle.FromVectors(Vector3.Up, ray.normal) * Angle(math.random() * math.pi * 2, 0, 0)
    })
end

function cLootManager:LocalPlayerExitVehicle(args)
    self.current_vehicle_storage_box = nil
    self.current_box = nil
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

function cLootManager:RenderLootRadar(args)
    local local_pos = LocalPlayer:GetPosition()
    for x, data in pairs(self.loot) do
        for y, data in pairs(self.loot[x]) do
            for id, box in pairs(self.loot[x][y]) do
                if self.loot_radar_tiers[box.tier] then
                    local pos, on_screen = Render:WorldToScreen(box.position)
                    if on_screen then
                        local distance = math.abs(local_pos:Distance(box.position))
                        local alpha = math.max(0, 1 - distance / 50) * 255
                        if distance < 5 then alpha = 0 end
                        local lootbox_color = Color(Lootbox.LootRadarColor.r, Lootbox.LootRadarColor.g, Lootbox.LootRadarColor.b, alpha)
                        Render:FillCircle(pos, self.look_at_circle_size, Color(0, 0, 0, alpha))
                        Render:FillCircle(pos, self.look_at_circle_size_inner, lootbox_color)
                    end
                end
            end
        end
    end
    
    self:RenderNearbyUnownedVehicles()
end

function cLootManager:RenderNearbyUnownedVehicles()
    local local_pos = LocalPlayer:GetPosition()
    for vehicle in Client:GetVehicles() do
        local vehicle_pos = vehicle:GetPosition()
        local vehicle_data = vehicle:GetValue("VehicleData")
        if not vehicle_data or not vehicle_data.owner_steamid then
            local pos, on_screen = Render:WorldToScreen(vehicle_pos)
            if on_screen then
                local distance = math.abs(local_pos:Distance(vehicle_pos))
                local alpha = math.max(0, 1 - distance / 150) * 255
                if distance < 5 then alpha = 0 end
                local lootbox_color = Color(219, 32, 135, alpha)
                Render:FillCircle(pos, self.look_at_circle_size, Color(0, 0, 0, alpha))
                Render:FillCircle(pos, self.look_at_circle_size_inner, lootbox_color)
            end
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

    if ClientInventory.lootbox_ui and ClientInventory.lootbox_ui.window:GetVisible() then
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

function cLootManager:IsObjectALootbox(ray)
    
    local uid = ray.entity:GetValue("LootboxId")
    local entity_pos = ray.entity:GetPosition()
    local cell = GetCell(entity_pos, Lootbox.Cell_Size)

    VerifyCellExists(self.loot, cell)
    if not LootManager.objects[ray.entity:GetId()] then return end
    if not uid or not self.loot[cell.x][cell.y][uid] then return end
    if Vector3.Distance(entity_pos, LocalPlayer:GetPosition()) > Lootbox.Distances.Can_Open then return end

    return self.loot[cell.x][cell.y][uid]

end

function cLootManager:Render(args)

    if not ClientInventory or not ClientInventory.lootbox_ui then return end
    if LocalPlayer:InVehicle() then return end

    local cam_pos = Camera:GetPosition()
    local cam_ang = Camera:GetAngle()

    if IsNaN(cam_pos.x) or IsNaN(cam_pos.y) or IsNaN(cam_pos.z) then return end
    if IsNaN(cam_ang.pitch) or IsNaN(cam_ang.yaw) or IsNaN(cam_ang.roll) then return end

    local ray = Physics:Raycast(cam_pos, cam_ang * Vector3.Forward, 0, 6.5)
    local found_box = false

    if ray.entity and ray.entity.__type == "ClientStaticObject" then

        local box = self:IsObjectALootbox(ray)

        if box then

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

function cLootManager:CheckIfCloseToBox()
    
    Thread(function()
        while true do 
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
            Timer.Sleep(1500)
        end
    end)

end

-- Returns true if one box is within the start_raycast distance
function cLootManager:IsOneBoxCloseEnough()

    local player_pos = LocalPlayer:GetPosition()
    local player_cell = GetCell(player_pos, Lootbox.Cell_Size)

    local adjacent_cells = GetAdjacentCells(player_cell)
    local distance_calls = 0

    for _, cell in pairs(adjacent_cells) do

        VerifyCellExists(self.loot, cell)
        for _, box in pairs(self.loot[cell.x][cell.y]) do

            if Vector3.Distance(box.position, player_pos) < Lootbox.Distances.Start_Raycast then

                return true

            end
            distance_calls = distance_calls + 1
            
            if distance_calls % 30 == 0 then
                Timer.Sleep(1)
            end

        end

    end

    return false

end

function cLootManager:OneLootboxCellSync(data)
    
    -- Lootbox is specifically a vehicle storage box
    if data.vehicle_storage then
        self.current_vehicle_storage_box = cLootbox(data)
        return
    end

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