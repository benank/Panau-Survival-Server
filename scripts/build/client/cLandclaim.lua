class 'cLandclaim'

function cLandclaim:__init(args)

    self.size = args.size -- Length of one side
    self.position = args.position
    self.owner_id = args.owner_id
    self.name = args.name
    self.expiry_date = args.expiry_date
    self.access_mode = args.access_mode
    self.objects_data = args.objects
    self.id = args.id
    self.state = args.state
    self.visible = false -- If this landclaim's border is visible to the owner or not, toggle-able by the menu
    
    self.cell = GetCell(self.position, LandclaimManager.cell_size)
    self.adjacent_cells = GetAdjacentCells(self.cell)

    self.ready = false -- Check upon creation that is set to true when the landclaim is loaded, aka objects are spawned if needed

    self:OnInit()

end

-- Individual distance checks for each object to determine whether it should have collision
function cLandclaim:StartObjectStreamingThread()
    Thread(function()
        while self.loaded do

            local player_pos = Camera:GetPosition()
            local sleep_count = 0

            for id, object in pairs(self.objects) do
                local is_in_collision_range = object:IsInCollisionRange(player_pos)
                local has_collision = object.has_collision

                if is_in_collision_range and not has_collision then
                    object:ToggleCollision(true)
                elseif not is_in_collision_range and has_collision then
                    object:ToggleCollision(false)
                end

                sleep_count = sleep_count + 1
                if sleep_count % 10 == 0 then
                    Timer.Sleep(1)
                end
            end

            Timer.Sleep(500)
        end
    end)
end

function cLandclaim:IsActive()
    return self.state == LandclaimStateEnum.Active
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

    if not self.loaded or self.loading then return end

    self.loading = true

    local sleep_count = 0
    for id, object in pairs(self.objects) do
        object:Remove()

        sleep_count = sleep_count + 1
        if sleep_count % 500 == 0 then
            Timer.Sleep(1)
        end
    end

    self.loading = false
    self.loaded = false

end

-- Loads in the objects in the landclaim. Assumes player is close enough.
function cLandclaim:Load()

    if self.loaded or self.loading then return end

    local sleep_count = 0
    for id, object in pairs(self.objects) do
        object:Create(true)

        sleep_count = sleep_count + 1
        if sleep_count % 100 == 0 then
            Timer.Sleep(1)
        end
    end

    self.loaded = true
    self.loading = false
    self:StartObjectStreamingThread()

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
        Events:Fire("loader/CompleteResource", {count = 1})
    end
end

-- Called when a new object was placed in the landclaim
function cLandclaim:PlaceObject(args)
    if self.objects_data[args.id] then return end

    self.objects_data[args.id] = args
    self.objects[args.id] = cLandclaimObject(args)

    if self.loaded then
        self.objects[args.id]:Create()
    end
end

-- Called when an object was removed from the landclaim (or destroyed)
function cLandclaim:RemoveObject(args)

end

-- Called when an object on the landclaim is damaged
function cLandclaim:DamageObject(args, player)

end

-- Called when we try to rename the landclaim
function cLandclaim:Rename(name, player)

end

-- TODO: update with object counts and stuff for menu
function cLandclaim:GetSyncObject()

    return {
        size = self.size,
        position = self.position,
        owner_id = self.owner_id,
        name = self.name,
        expiry_date = self.expiry_date,
        access_mode = self.access_mode,
        objects = self.objects_data,
        id = self.id,
        days_till_expiry = GetLandclaimDaysTillExpiry(self.expiry_date),
        access_mode_string = LandclaimAccessModeEnum:GetDescription(self.access_mode),
        state = self.state
    }

end