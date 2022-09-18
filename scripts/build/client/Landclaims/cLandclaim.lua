class 'cLandclaim'

function cLandclaim:__init(args, callback)

    self.size = args.size -- Length of one side
    self.position = args.position
    self.owner_id = args.owner_id
    self.name = args.name
    self.expiry_date = args.expiry_date
    self.access_mode = args.access_mode
    self.objects_data = args.objects -- If you loop through this, please use count_table_async to avoid lag
    self.id = args.id
    self.state = args.state
    self.object_count = 0
    self.visible = false -- If this landclaim's border is visible to the owner or not, toggle-able by the menu
    -- Setting it to visible also allows you to see the health of objects on the landclaim
    
    self.cell = GetCell(self.position, LandclaimManager.cell_size)
    self.adjacent_cells = GetAdjacentCells(self.cell)

    self.ready = false -- Check upon creation that is set to true when the landclaim is loaded, aka objects are spawned if needed

    count_table_async(self.objects_data, function(count)
        self.object_count = count
        self:OnInit()
        callback(self)
    end)

end

-- Individual distance checks for each object to determine whether it should have collision
function cLandclaim:StartObjectStreamingThread()
    Thread(function()
        while self.loaded do
                
            local player_pos = Camera:GetPosition()
            local sleep_count = 0
            local collision_sleep_count = 0

            for id, object in pairs(self.objects) do
                local is_in_collision_range = object:IsInCollisionRange(player_pos)
                local has_collision = object.has_collision

                if is_in_collision_range and not has_collision then
                    object:ToggleCollision(true)
                    collision_sleep_count = collision_sleep_count + 1
                    if collision_sleep_count % 100 == 0 then
                        Timer.Sleep(1)
                    end
                elseif not is_in_collision_range and has_collision then
                    object:ToggleCollision(false)
                end

                sleep_count = sleep_count + 1
                -- Adjust this number to speed up checks at the cost of performance
                if sleep_count % 300 == 0 then
                    Timer.Sleep(1)
                end
            end

            if not self.one_stream_iteration_done then
                Thread(function()
                    Timer.Sleep(3000)
                    self.one_stream_iteration_done = true
                end)
            end
            Timer.Sleep(50)
        end
    end)
end

function cLandclaim:IsActive()
    return self.state == LandclaimStateEnum.Active and GetLandclaimDaysTillExpiry(self.expiry_date) > 0
end

function cLandclaim:LocalPlayerCellUpdate(args)

    -- Retry cell update if it's loading, aka loading or unloading objects
    if self.loading then
        Thread(function()
            Timer.Sleep(500)
            self:LocalPlayerCellUpdate(args)
        end)
        return
    end

    -- Check if we should unload this landclaim
    if self:IsInCellList(args.old_adjacent) then
        Thread(function()
            self:Unload()
        end)
        return
    end

    -- Check if we should load this landclaim
    if self:IsInCellList(args.adjacent) then
        Thread(function()
            self:Load()
        end)
        return
    end

end

function cLandclaim:Unload()

    if self.loading then return end

    self.loaded = false
    self.loading = true

    local sleep_count = 0
    for id, object in pairs(self.objects) do
        object:Remove()

        sleep_count = sleep_count + 1
        if sleep_count % 500 == 0 then
            Timer.Sleep(1)
        end
    end
    
    collectgarbage("collect")
    
    self.loading = false

end

function cLandclaim:ModuleUnload()
    self:Remove()
end

function cLandclaim:Remove()
    self.loaded = false
    self.loading = false
    for id, object in pairs(self.objects) do
        object:Remove()
    end
    self.objects = {}
end

-- Loads in the objects in the landclaim. Assumes player is close enough.
function cLandclaim:Load()

    if self.loaded or self.loading then return end

    self.loading = true

    local sleep_count = 0
    for id, object in pairs(self.objects) do
        object:Create(true)

        sleep_count = sleep_count + 1
        if sleep_count % 200 == 0 then
            Timer.Sleep(1)
        end
    end

    self.loaded = true

    self.one_stream_iteration_done = false
    self:StartObjectStreamingThread()

    while not self.one_stream_iteration_done do
        Timer.Sleep(100)
    end

    self.loading = false

    -- Finished loading objects
    if not self.ready then
        self:OnReady()
    end
    
end

-- Parses objects into wrapper classes to handle streaming and custom attributes
function cLandclaim:ParseObjects()
    self.objects = {}
    local sleep_count = 0
    for id, object_data in pairs(self.objects_data) do
        object_data.landclaim = self
        self.objects[id] = cLandclaimObject(object_data)

        sleep_count = sleep_count + 1
        if sleep_count % 500 == 0 then
            Timer.Sleep(1)
        end
    end
end

function cLandclaim:OnInit()

    Thread(function()
        self:ParseObjects()

        local player_cell = GetCell(Camera:GetPosition(), LandclaimManager.cell_size)
        local adj_cells = GetAdjacentCells(player_cell)

        if self:IsInCellList(adj_cells) then
            self:Load()
        else
            self:OnReady()
        end
    end)
end

-- Returns whether or not this landclaim is in streaming range
function cLandclaim:IsInCellList(adj_cells)
    for _, cell in pairs(adj_cells) do
        if cell.x == self.cell.x and cell.y == self.cell.y then
            return true
        end
    end
end

-- Called when the landclaim is ready - this should update loading screen if they are in it
function cLandclaim:OnReady()
    self.ready = true

    if LocalPlayer:GetValue("Loading") then
        Events:Fire("loader/CompleteResource", {count = 1, name = "Landclaims"})
    end
end

-- Called when a new object was placed in the landclaim
function cLandclaim:PlaceObject(args)
    if self.objects_data[args.id] then return end

    self.objects_data[args.id] = args
    args.landclaim = self
    self.objects[args.id] = cLandclaimObject(args)

    if self.loaded then
        self.objects[args.id]:Create()
    end

    self.object_count = self.object_count + 1
end

-- Called when an object was removed from the landclaim (or destroyed)
function cLandclaim:RemoveObject(args)
    if not self.objects[args.id] then return end
    self.objects[args.id]:Remove()
    self.objects[args.id] = nil
    self.objects_data[args.id] = nil

    self.object_count = self.object_count - 1
end

-- Called when an object on the landclaim is damaged
function cLandclaim:DamageObject(args, player)

    local object = self.objects[args.id]
    if not object then return end
    
    object.health = args.health

    if IsValid(player) and player == LocalPlayer and args.primary then
        -- Display HP
        cLandclaimObjectHealthDisplay:Display(object)
    end

    if args.health <= 0 then
        -- TODO: add destruction effect
        self:RemoveObject(args)
    end
end

function cLandclaim:IsPlayerOwner(player)
    return self.owner_id == tostring(player:GetSteamId())
end

function cLandclaim:CanPlayerPlaceObject(player)

    if not self:IsActive() then return end

    local is_owner = self:IsPlayerOwner(player)

    if self.access_mode == LandclaimAccessModeEnum.OnlyMe then
        return is_owner
    elseif self.access_mode == LandclaimAccessModeEnum.Friends then
        return AreFriends(player, self.owner_id) or is_owner
    elseif self.access_mode == LandclaimAccessModeEnum.Clan then
        -- TODO: add clan check logic here
        return is_owner
    elseif self.access_mode == LandclaimAccessModeEnum.Everyone then
        return true
    end
end

function cLandclaim:GetSyncObject()

    return {
        size = self.size,
        position = self.position,
        owner_id = self.owner_id,
        name = self.name,
        expiry_date = self.expiry_date,
        access_mode = self.access_mode,
        object_count = self.object_count,
        id = self.id,
        days_till_expiry = GetLandclaimDaysTillExpiry(self.expiry_date),
        access_mode_string = LandclaimAccessModeEnum:GetDescription(self.access_mode),
        state = self.state
    }

end