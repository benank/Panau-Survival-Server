class 'cLandclaimManager'

function cLandclaimManager:__init()

    -- Preemptively register one resource while we wait for the total landclaim count sync
    Events:Fire("loader/RegisterResource", {count = 1, name = "Landclaim Preload"})

    self.cell_size = 2048

    self.landclaims = {}

    self.delta = 0

    Events:Fire("build/ResetLandclaimsMenu")

    Network:Subscribe("build/SyncLandclaim", self, self.SyncLandclaim)
    Network:Subscribe("build/SyncTotalLandclaims", self, self.SyncTotalLandclaims)
    Network:Subscribe("build/SyncSmallLandclaimUpdate", self, self.SyncSmallLandclaimUpdate)
    Events:Subscribe("Cells/LocalPlayerCellUpdate" .. tostring(self.cell_size), self, self.LocalPlayerCellUpdate)
    Events:Subscribe("build/ToggleLandclaimVisibility", self, self.ToggleLandclaimVisibility)
    Events:Subscribe("build/DeleteLandclaim", self, self.DeleteLandclaim)
    Events:Subscribe("build/RenameLandclaim", self, self.RenameLandclaim)
    Events:Subscribe("build/ChangeLandclaimAccessMode", self, self.ChangeLandclaimAccessMode)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("GameRender", self, self.GameRender)
    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)

    -- Wait until player position has been set to load landclaims
    if LocalPlayer:GetValue("Loading") then
        local sub
        sub = Events:Subscribe(var("loader/BaseLoadscreenDone"):get(), function()
            Thread(function()
                Network:Send("build/ReadyForInitialSync")
                Events:Unsubscribe(sub)
            end)
        end)
    else
        Network:Send("build/ReadyForInitialSync")
    end

end

function cLandclaimManager:AreAnyLandclaimsLoading()
    for steam_id, landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(landclaims) do
            if landclaim.loading then
                return true
            end
        end
    end
    
    return false
end

function cLandclaimManager:ModulesLoad()
    Events:Fire("build/ResetLandclaimsMenu")
    Events:Fire("build/UpdateLandclaims", self:GetLocalPlayerOwnedLandclaims(true))
end

function cLandclaimManager:ChangeLandclaimAccessMode(args)
    local my_claims = self:GetLocalPlayerOwnedLandclaims()
    if not my_claims[args.id] then return end
    local access_mode = LandclaimAccessModeEnum:GetEnumFromDescription(args.access_mode_string)
    if not access_mode then return end
    Network:Send("build/ChangeLandclaimAccessMode", {id = args.id, access_mode = access_mode})
end

function cLandclaimManager:RenameLandclaim(args)
    local my_claims = self:GetLocalPlayerOwnedLandclaims()
    if not my_claims[args.id] then return end
    Network:Send("build/RenameLandclaim", {id = args.id, name = args.name})
end

function cLandclaimManager:DeleteLandclaim(args)
    local my_claims = self:GetLocalPlayerOwnedLandclaims()
    if not my_claims[args.id] then return end
    Network:Send("build/DeleteLandclaim", {id = args.id})
end

function cLandclaimManager:SyncSmallLandclaimUpdate(args)
    if not self.landclaims[args.landclaim_owner_id] 
    or not self.landclaims[args.landclaim_owner_id][args.landclaim_id] then return end

    local landclaim = self.landclaims[args.landclaim_owner_id][args.landclaim_id]

    if args.type == "add_object" then
        landclaim:PlaceObject(args.object)
    elseif args.type == "state_change" then
        landclaim.state = args.state

        if not landclaim:IsActive() then
            Events:Fire("build/RemoveLandclaimFromMap", landclaim:GetSyncObject())
        end
    elseif args.type == "expiry_date_change" then
        landclaim.expiry_date = args.expiry_date
    elseif args.type == "name_change" then
        landclaim.name = args.name
        Events:Fire("build/UpdateLandclaimOnMap", landclaim:GetSyncObject())
    elseif args.type == "object_damaged" then
        landclaim:DamageObject(args, args.player)
    elseif args.type == "bed_update" then
        local object = landclaim.objects[args.id]
        if not object then return end

        object.custom_data.player_spawns = args.player_spawns
    elseif args.type == "door_access_update" then
        local object = landclaim.objects[args.id]
        if not object then return end

        object.custom_data.access_mode = args.access_mode
    elseif args.type == "object_remove" then
        landclaim:RemoveObject(args)
    elseif args.type == "light_state" then
        local object = landclaim.objects[args.id]
        if not object or not object.extension then return end

        object.custom_data.enabled = args.enabled
        object.extension:StateUpdated(args.enabled)
    elseif args.type == "door_state" then
        local object = landclaim.objects[args.id]
        if not object or not object.extension then return end

        object.custom_data.open = args.open
        object.extension:StateUpdated()
    elseif args.type == "access_mode" then
        landclaim.access_mode = args.access_mode
    elseif args.type == "sign" then
        local object = landclaim.objects[args.id]
        if not object or not object.extension then return end

        object.custom_data.color = args.color
        object.custom_data.text = args.text
        object.extension:StateUpdated()
    elseif args.type == "teleporter" then
        local object = landclaim.objects[args.id]
        if not object or not object.extension then return end

        object.custom_data.tp_link_id = args.tp_link_id
        object.extension:StateUpdated()
    end
    
    Events:Fire("build/UpdateLandclaims", self:GetLocalPlayerOwnedLandclaims(true))
end

function cLandclaimManager:ToggleLandclaimVisibility(args)
    if not args.id then return end

    local my_claims = self:GetLocalPlayerOwnedLandclaims()

    local landclaim = my_claims[args.id]
    if not landclaim then return end

    landclaim.visible = not landclaim.visible
end

function cLandclaimManager:GameRender(args)

    local my_claims = self:GetLocalPlayerOwnedLandclaims()

    self.delta = self.delta + args.delta

    local color = Color(0, 255, 255, 25)
    local color_static = Color(0, 255, 255, 100)
    -- Render landclaim borders for the owner if they are enabled
    for id, landclaim in pairs(my_claims) do
        if landclaim.visible then
            cLandclaimPlacer:RenderLandClaimBorder(landclaim.position, landclaim.size, self.delta, color)
            cLandclaimPlacer:RenderLandClaimStaticBorder(landclaim.position, landclaim.size, color_static)
        end
    end

end

-- Gets all active landclaims owned by the localplayer. Returns sync object for all if get_sync_object is true
function cLandclaimManager:GetLocalPlayerOwnedLandclaims(get_sync_object)
    local landclaims = self.landclaims[tostring(LocalPlayer:GetSteamId())] or {}

    local landclaim_data = {}
    for id, landclaim in pairs(landclaims) do
        if landclaim:IsActive() then
            landclaim_data[id] = get_sync_object and landclaim:GetSyncObject() or landclaim
        end
    end

    return landclaim_data
end

function cLandclaimManager:ModuleUnload()

    for steam_id, landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(landclaims) do
            landclaim:ModuleUnload()
        end
    end
end

-- Large scale cell updates for landclaims
function cLandclaimManager:LocalPlayerCellUpdate(args)
    for steam_id, landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(landclaims) do
            landclaim:LocalPlayerCellUpdate(args)
        end
    end
end

-- Called by server when a single landclaim syncs, either on join or when a new one is placed
function cLandclaimManager:SyncLandclaim(args)

    if not self.landclaims[args.owner_id] then
        self.landclaims[args.owner_id] = {}
    end

    -- Remove existing landclaim if there is one, but after creating the new one
    local existing_claim = self.landclaims[args.owner_id][args.id]

    cLandclaim(args, function(landclaim)
        self.landclaims[args.owner_id][args.id] = landclaim

        -- Sync owned landclaims to asset manager menu
        if args.owner_id == tostring(LocalPlayer:GetSteamId()) then
            Events:Fire("build/UpdateLandclaims", self:GetLocalPlayerOwnedLandclaims(true))
            if landclaim:IsActive() then
                Events:Fire("build/AddLandclaimToMap", landclaim:GetSyncObject())
            end
        end

        if existing_claim then
            existing_claim:Remove()
        end
    end)

end

function cLandclaimManager:SyncTotalLandclaims(args)

    -- Regsiter each landclaim as a loading resource so the load screen waits for them to fully load
    Events:Fire("loader/RegisterResource", {count = args.total, name = "Landclaims"})
    Events:Fire("loader/CompleteResource", {count = 1, name = "Landclaim Preload"})

end

LandclaimManager = nil

Events:Subscribe("LoaderReady", function()

    if not LandclaimManager then
        LandclaimManager = cLandclaimManager()
    end

end)