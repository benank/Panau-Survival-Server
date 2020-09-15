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
    self.visible = false -- If this landclaim's border is visible to the owner or not, toggle-able by the menu
    
    self.cell = GetCell(self.position, LandclaimManager.cell_size)

    self.ready = false -- Check upon creation that is set to true when the landclaim is loaded, aka objects are spawned if needed

    self:OnInit()

end

function cLandclaim:Unload()

    if not self.loaded or self.loading then return end

    self.loading = true

    -- TODO: delete all objects
    for id, object in pairs(self.objects) do
        object:Remove()
    end

    self.loading = false
    self.loaded = false

end

-- Loads in the objects in the landclaim. Assumes player is close enough.
function cLandclaim:Load()

    if self.loaded or self.loading then return end

    self.loading = true

    local sleep_count = 0
    for id, object in pairs(self.objects) do
        object:Create()

        sleep_count = sleep_count + 1
        if sleep_count % 100 == 0 then
            Timer.Sleep(1)
        end
    end

    self.loaded = true
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

        --if self:IsInStreamingRange(adj_cells) then
            self:Load()
        --else
        --    self:OnReady()
        --end
    end)
end

-- Returns whether or not this landclaim is in streaming range
function cLandclaim:IsInStreamingRange(player_adj_cells)
    for _, cell in pairs(player_adj_cells) do
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
        access_mode_string = LandclaimAccessModeEnum:GetDescription(self.access_mode)
    }

end