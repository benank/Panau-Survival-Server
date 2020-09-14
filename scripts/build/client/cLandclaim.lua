class 'cLandclaim'

function cLandclaim:__init(args)

    self.radius = args.radius
    self.position = args.position
    self.owner_id = args.owner_id
    self.name = args.name
    self.expiry_date = args.expiry_date
    self.access_mode = args.access_mode
    self.objects = args.objects
    self.id = args.id
    
    self.cell = GetCell(self.position, LandclaimManager.cell_size)

    self.ready = false -- Check upon creation that is set to true when the landclaim is loaded, aka objects are spawned if needed

    self:OnInit()

end

function cLandclaim:Unload()

    if not self.loaded or self.loading then return end

    self.loading = true

    -- TODO: delete all objects

    self.loading = false
    self.loaded = false

end

-- Loads in the objects in the landclaim. Assumes player is close enough.
function cLandclaim:Load()

    if self.loaded or self.loading then return end

    self.loading = true

    -- TODO: load objects


    self.loaded = true
    self.loading = false
    
    -- Finished loading objects
    if not self.ready then
        self:OnReady()
    end
end

function cLandclaim:OnInit()
    local player_cell = GetCell(Camera:GetPosition(), LandclaimManager.cell_size)
    local adj_cells = GetAdjacentCells(player_cell)

    if self:IsInStreamingRange(adj_cells) then
        self:Load()
    else
        self:OnReady()
    end
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
        radius = self.radius,
        position = self.position,
        owner_id = self.owner_id,
        name = self.name,
        expiry_date = self.expiry_date,
        access_mode = self.access_mode,
        objects = self.objects,
        id = self.id,
        days_till_expiry = GetLandclaimDaysTillExpiry(self.expiry_date),
        access_mode_string = LandclaimAccessModeEnum:GetDescription(self.access_mode)
    }

end