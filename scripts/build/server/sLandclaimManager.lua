class 'sLandclaimManager'

function sLandclaimManager:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS landclaims (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, position VARCHAR, name VARCHAR(20), size INTEGER, expiry_date VARCHAR, access_mode INTEGER, state INTEGER, objects BLOB)")
    
    self.landclaims = {} -- [steam_id] = {[landclaim_id] = landclaim, [landclaim_id] = landclaim}
    self.player_spawns = {} -- [steam id] = {id = id, landclaim_id = landclaim id, landclaim_owner_id = landclaim_owner_id}
    self.players = {}
    
    if SharedObject.GetByName("Landclaims") then
        SharedObject.GetByName("Landclaims"):Remove()
    end

    self.landclaims_sharedobject = SharedObject.Create("Landclaims")
    self:UpdateLandclaimsSharedObject()

    Network:Subscribe("build/DeleteLandclaim", self, self.DeleteLandclaim)
    Network:Subscribe("build/RenameLandclaim", self, self.RenameLandclaim)
    Network:Subscribe("build/ChangeLandclaimAccessMode", self, self.ChangeLandclaimAccessMode)
    Network:Subscribe("build/PressBuildObjectMenuButton", self, self.PressBuildObjectMenuButton)
    Network:Subscribe("build/ReadyForInitialSync", self, self.PlayerReadyForInitialSync)
    Network:Subscribe("build/ActivateLight", self, self.ActivateLight)
    Network:Subscribe("build/ActivateDoor", self, self.ActivateDoor)
    Network:Subscribe("build/EditSign", self, self.EditSign)

    Events:Subscribe("items/PlaceLandclaim", self, self.TryPlaceLandclaim)
    Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated)
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("items/PlaceObjectInLandclaim", self, self.PlaceObjectInLandclaim)
    Events:Subscribe("items/DetonateOnBuildObject", self, self.DetonateOnBuildObject)

    -- Check for expired landclaims every 3 hours and on load
    Timer.SetInterval(1000 * 60 * 60 * 3, function()
        self:CheckForExpiredLandclaims()
        self:TotalBuildObjectsUpdate()
    end)

    -- Update health of decaying objects in expired claims every 2 hours
    Timer.SetInterval(1000 * 60 * 60 * 2, function()
        self:DecayExpiredLandclaims()
    end)

    if IsTest then
        Events:Subscribe("PlayerChat", function(args)
            if args.text == "/objtest" and IsAdmin(args.player) then
                self:ObjectTest(args)
            end
        end)
    end

end

function sLandclaimManager:DecayExpiredLandclaims()
    Thread(function()
        for steam_id, player_landclaims in pairs(self.landclaims) do
            for id, landclaim in pairs(player_landclaims) do
                if landclaim.state == LandclaimStateEnum.Inactive then
                    landclaim:Decay()
                    Timer.Sleep(10)
                end
            end
        end
    end)
end

function sLandclaimManager:CheckForExpiredLandclaims()
    for steam_id, player_landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(player_landclaims) do
            if landclaim.state == LandclaimStateEnum.Active and GetLandclaimDaysTillExpiry(landclaim.expiry_date) <= 0 then
                landclaim:Expire()
            end
        end
    end
    self:UpdateLandclaimsSharedObject()
end

function sLandclaimManager:PlayerQuit(args)
    self.players[tostring(args.player:GetSteamId())] = nil
end

function sLandclaimManager:ActivateDoor(args, player)
    local landclaim = sLandclaimManager:GetLandclaimFromData(args.landclaim_owner_id, args.landclaim_id)
    if not landclaim then return end

    landclaim:ActivateDoor(args, player)
end

function sLandclaimManager:EditSign(args, player)
    local landclaim = sLandclaimManager:GetLandclaimFromData(args.landclaim_owner_id, args.landclaim_id)
    if not landclaim then return end

    landclaim:EditSign(args, player)
end

function sLandclaimManager:ActivateLight(args, player)
    local landclaim = sLandclaimManager:GetLandclaimFromData(args.landclaim_owner_id, args.landclaim_id)
    if not landclaim then return end

    landclaim:ActivateLight(args, player)
end

-- Called when a player presses a button from the right click object menu
function sLandclaimManager:PressBuildObjectMenuButton(args, player)
    local landclaim = sLandclaimManager:GetLandclaimFromData(args.landclaim_owner_id, args.landclaim_id)
    if not landclaim then return end
    if not landclaim:IsActive() then return end

    landclaim:PressBuildObjectMenuButton(args, player)
    self:UpdateLandclaimsSharedObject()
end

function sLandclaimManager:DetonateOnBuildObject(args)
    if not IsValid(args.player) then return end

    local landclaim = sLandclaimManager:GetLandclaimFromData(args.landclaim_data.landclaim_owner_id, args.landclaim_data.landclaim_id)
    if not landclaim then return end
    
    if landclaim.owner_id == "SERVER" then return end

    local target_object_id = tonumber(args.landclaim_data.id)
    landclaim:DamageObject(args, args.player)
    Thread(function()
        -- Loop through all objects in landclaim and see if they are close enough to get hit
        local splash_radius = ExplosiveRadius[args.type]
        if not splash_radius then return end
        
        for id, landclaim_object in pairs(landclaim.objects) do
            if target_object_id ~= id then
                local dist = landclaim_object.position:Distance(args.c4_position)
                if dist < splash_radius then
                    local percent_damage = 1 - (dist / splash_radius)
                    args.percent_damage = percent_damage
                    args.landclaim_data.id = id
                    landclaim:DamageObject(args, args.player)
                    -- print(string.format("Damage object %d with mod %.2f", id, percent_damage))
                end
            end
            
            Timer.Sleep(1)
        end
        
    end)
    
    self:UpdateLandclaimsSharedObject()
end

function sLandclaimManager:GetLandclaimFromData(landclaim_owner_id, landclaim_id)
    local landclaims = self.landclaims[landclaim_owner_id]
    if not landclaims then return end

    return landclaims[landclaim_id]
end

function sLandclaimManager:ObjectTest(args)
    _debug("SPAWNING...")
    local object_amount = 10000
    local object_range = 300

    local target_landclaim = self:FindFirstActiveLandclaimContainingPosition(args.player:GetPosition())

    -- No valid landclaim found; can't place here
    if not target_landclaim then return end

    Thread(function()
        for i = 1, object_amount do
            target_landclaim:PlaceObject({
                player_iu = {
                    item = {
                        name = "Wall",
                        durability = 500
                    }
                },
                position = target_landclaim.position + 
                    Vector3(
                        math.random() * target_landclaim.size - target_landclaim.size / 2, 
                        math.random() * object_range, 
                        math.random() * target_landclaim.size - target_landclaim.size / 2),
                angle = Angle(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2),
                --player = args.player
            })
            Timer.Sleep(1)
            _debug(string.format("%d/%d", i, object_amount))
        end
        _debug("FINISHED")
    end)
end

function sLandclaimManager:ChangeLandclaimAccessMode(args, player)
    if not args.id or not args.access_mode then return end

    local player_landclaims = self:GetPlayerActiveLandclaims(player)

    local landclaim = player_landclaims[args.id]
    if not landclaim then return end

    if not LandclaimAccessModeEnum:IsValidAccessMode(args.access_mode) then return end

    landclaim:ChangeAccessMode(args.access_mode, player)
    self:UpdateLandclaimsSharedObject()
end

function sLandclaimManager:RenameLandclaim(args, player)
    if not args.id or not args.name then return end
    args.name = tostring(args.name)
    args.name = args.name:sub(1, Config.landclaim_name_max_length)

    local player_landclaims = self:GetPlayerActiveLandclaims(player)

    local landclaim = player_landclaims[args.id]
    if not landclaim then return end

    landclaim:Rename(args.name, player)
    self:UpdateLandclaimsSharedObject()
end

function sLandclaimManager:DeleteLandclaim(args, player)
    if not args.id then return end

    local player_landclaims = self:GetPlayerActiveLandclaims(player)

    local landclaim = player_landclaims[args.id]
    if not landclaim then return end

    landclaim:Delete(player)
    Chat:Send(player, "Landclaim successfully deleted. Any objects that you didn't pick up will slowly decay over time unless claimed again.", Color.Yellow)
    self:UpdateLandclaimsSharedObject()
end

function sLandclaimManager:PlaceObjectInLandclaim(args)

    if not IsValid(args.player) then return end

    -- Find the first (and should be only) landclaim that contains this position
    local target_landclaim = self:FindFirstActiveLandclaimContainingPosition(args.position)

    -- No valid landclaim found; can't place here
    if not target_landclaim then return end

    target_landclaim:PlaceObject(args)
    self:UpdateLandclaimsSharedObject()

end

function sLandclaimManager:FindFirstActiveLandclaimContainingPosition(pos)
    for steam_id, landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(landclaims) do
            if landclaim:IsActive() and IsInSquare(landclaim.position, landclaim.size, pos) then
                return landclaim
            end
        end
    end
end

function sLandclaimManager:LoadAllLandclaims()

    print("Loading all landclaims...")

    local result = SQL:Query("SELECT * FROM landclaims")
    result = result:Execute()

    if result and count_table(result) > 0 then
        for _, data in ipairs(result) do
            self:ParseLandclaimDataFromDB(data)
        end
    end
    print(string.format("Loaded %d landclaims!", count_table(result)))

    self:CheckForExpiredLandclaims()
    self:TotalBuildObjectsUpdate()

end

function sLandclaimManager:LoadAllUnclaimedObjects()
    -- Load all unclaimed objects from DB and send to client
end

function sLandclaimManager:ParseLandclaimDataFromDB(data)
    local owner_id = tostring(data.steamID)
    local landclaim_id = tonumber(data.id)

    self:AddClaim({
        size = tonumber(data.size),
        position = DeserializePosition(tostring(data.position)),
        owner_id = tostring(owner_id),
        name = tostring(data.name),
        expiry_date = tostring(data.expiry_date),
        access_mode = tonumber(data.access_mode),
        objects = data.objects,
        id = landclaim_id,
        state = tonumber(data.state)
    })

end

function sLandclaimManager:ModuleLoad()
    self:LoadAllUnclaimedObjects()
    self:LoadAllLandclaims()
end

function sLandclaimManager:GetPlayerMaxClaims(player)

    local perks = player:GetValue("Perks")

    if not perks then return 0 end

    local max_landclaims = Config.player_base_landclaims

    for perk_id, bonus in pairs(Config.player_max_landclaims) do
        if perks.unlocked_perks[perk_id] then
            max_landclaims = max_landclaims + bonus
        end
    end

    return max_landclaims

end

function sLandclaimManager:PlayerPerksUpdated(args)
    args.player:SetNetworkValue("MaxLandclaims", self:GetPlayerMaxClaims(args.player))
end

function sLandclaimManager:PlayerReadyForInitialSync(args, player)
    -- Send player data of all landclaims. They will manage streaming on the clientside.
    self.players[tostring(player:GetSteamId())] = player
    Thread(function()
        
        local total_landclaims = 0
        for steam_id, landclaims in pairs(self.landclaims) do
            total_landclaims = total_landclaims + count_table(landclaims)
        end

        -- Sync total number of landclaims so they can load the landclaims before loadscreen finishes
        Network:Send(player, "build/SyncTotalLandclaims", {total = total_landclaims})

        for steam_id, landclaims in pairs(self.landclaims) do
            for id, landclaim in pairs(landclaims) do
                -- Use separate network sends to prevent sending too much data at once and on a single frame
                Timer.Sleep(1)
                landclaim:Sync(player)
            end
        end
    end)
end

function sLandclaimManager:AddClaim(claim_data)

    if not self.landclaims[claim_data.owner_id] then
        self.landclaims[claim_data.owner_id] = {}
    end

    local landclaim = sLandclaim(claim_data)
    self.landclaims[claim_data.owner_id][claim_data.id] = landclaim
    self:UpdateLandclaimsSharedObject()
    return landclaim

end

function sLandclaimManager:TotalBuildObjectsUpdate()
    local total_build_objects = 0
    for steam_id, player_landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(player_landclaims) do
            total_build_objects = total_build_objects + count_table(landclaim.objects)
        end
    end
    Events:Fire("build/TotalBuildObjectsUpdate", {total = total_build_objects})
end

function sLandclaimManager:UpdateLandclaimsSharedObject()
    Thread(function()
        local landclaims = {}
        for steam_id, player_landclaims in pairs(self.landclaims) do
            landclaims[steam_id] = {}
            for id, landclaim in pairs(player_landclaims) do
                local sync_object = landclaim:GetSyncObject()
                landclaims[steam_id][id] = landclaim:GetSyncObject()
                Timer.Sleep(1) -- Sleep every time because the speed doesn't matter here
            end
        end
        self.landclaims_sharedobject:SetValue("Landclaims", landclaims)
    end)
end

function sLandclaimManager:UpdateLandclaimExpiry(size, landclaim, player)
    -- A couple sanity checks in case something went terribly wrong
    if landclaim.owner_id ~= tostring(player:GetSteamId()) then return end
    if not IsInSquare(landclaim.position, landclaim.size, player:GetPosition()) then return end

    local old_expiry_date = landclaim.expiry_date
    local new_expiry_date, days_to_add = GetLandclaimExpireDate({
        size = landclaim.size,
        new_size = size,
        expiry_date = landclaim.expiry_date
    })
    
    landclaim:UpdateExpiryDate(new_expiry_date)
    Chat:Send(player, string.format("Extended %s duration to %d days.", landclaim.name, days_to_add), Color.Green)
    
    Events:Fire("Discord", {
        channel = "Build",
        content = string.format("%s [%s] added %d days to landclaim expiry. Old: %s New: %s (%s)", 
            player:GetName(), tostring(player:GetSteamId()), days_to_add, old_expiry_date, landclaim.expiry_date, landclaim:ToLogString())
    })

    self:UpdateLandclaimsSharedObject()
end

function sLandclaimManager:PlaceLandclaim(size, player)

    local position = player:GetPosition()

    local landclaim_data = 
    {
        size = size,
        position = position,
        owner_id = tostring(player:GetSteamId()),
        name = "LandClaim",
        expiry_date = GetLandclaimExpireDate({is_new_landclaim = true}),
        access_mode = LandclaimAccessModeEnum.OnlyMe,
        state = LandclaimStateEnum.Active,
        objects = ""
    }
    
    local cmd = SQL:Command("INSERT INTO landclaims (steamID, position, name, size, expiry_date, access_mode, state, objects) VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
    cmd:Bind(1, landclaim_data.owner_id)
    cmd:Bind(2, SerializePosition(landclaim_data.position))
    cmd:Bind(3, landclaim_data.name)
    cmd:Bind(4, landclaim_data.size)
    cmd:Bind(5, landclaim_data.expiry_date)
    cmd:Bind(6, landclaim_data.access_mode)
    cmd:Bind(7, landclaim_data.state)
    cmd:Bind(8, "")
    cmd:Execute()

    
    cmd = SQL:Query("SELECT last_insert_rowid() as insert_id FROM landclaims")
    local result = cmd:Execute()
    landclaim_data.id = tonumber(result[1].insert_id)

    local landclaim = self:AddClaim(landclaim_data)
    landclaim:ClaimNearbyUnclaimedObjects(player, function()
        landclaim:Sync()
        Chat:Send(player, "LandClaim placed successfully!", Color.Green)

        Events:Fire("Discord", {
            channel = "Build",
            content = string.format("%s [%s] placed a landclaim of size %d at pos %s (%s)", 
                player:GetName(), tostring(player:GetSteamId()), landclaim_data.size, landclaim_data.position, landclaim:ToLogString())
        })
    end)
end

function sLandclaimManager:SendPlayerErrorMessage(player, reason)
    Chat:Send(player, "Placing LandClaim failed! Reason: " .. tostring(reason), Color.Red)
end

function sLandclaimManager:GetPlayerActiveLandclaims(player)

    local player_landclaims = self.landclaims[tostring(player:GetSteamId())] or {}

    local active_landclaims = {}
    for id, landclaim in pairs(player_landclaims) do
        if landclaim:IsActive() then
            active_landclaims[id] = landclaim
        end
    end

    return active_landclaims
end

function sLandclaimManager:TryPlaceLandclaim(args)

    Chat:Send(args.player, "Placing landclaim...", Color.Yellow)
    
    local player = args.player
    local player_iu = args.player_iu
    local steam_id = tostring(player:GetSteamId())

    if not player_iu then return end
    if not player_iu.item then return end

    local item = player_iu.item

    if item.name ~= "LandClaim" then return end

    local size = tonumber(item.custom_data.size)

    if not size then
        self:SendPlayerErrorMessage(player, "Generic Error")
        return
    end

    local position = player:GetPosition()
    
    if player:InVehicle() then
        Chat:Send(player, "Cannot place landclaims while in a vehicle!", Color.Red)
        return
    end

    -- Not within map bounds
    if not IsInSquare(Vector3(), 32768, position) then
        self:SendPlayerErrorMessage(player, "Out of Map")
        return
    end

    local ModelChangeAreas = SharedObject.GetByName("ModelLocations"):GetValues()

    for _, area in pairs(ModelChangeAreas) do
        if Distance2D(position, area.pos) < 25 + size then
            self:SendPlayerErrorMessage(player, "Restricted Area")
            return
        end
    end

    if IsInLocation(position, size, BlacklistedLandclaimAreas) then
        self:SendPlayerErrorMessage(player, "Restricted Area")
        return
    end

    -- Check for proximity to existing landclaims
    for steamid, landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(landclaims) do
            if landclaim:IsActive()
            and steamid ~= steam_id and Distance2D(position, landclaim.position) < size / 2 + landclaim.size / 2 + 100 then
                self:SendPlayerErrorMessage(player, "Too close to another LandClaim")
                return
            end
        end
    end
    
    Inventory.RemoveItem({
        item = player_iu.item,
        index = player_iu.index,
        player = player
    })

    -- Check for proximity to existing owned landclaims
    local player_landclaims = self:GetPlayerActiveLandclaims(player)
    for id, landclaim in pairs(player_landclaims) do
        if IsInSquare(landclaim.position, landclaim.size, position) then
            self:UpdateLandclaimExpiry(size, landclaim, player)
            return
        end
    end

    if count_table(player_landclaims) >= player:GetValue("MaxLandclaims") then
        Chat:Send(player, "You already have the maximum amount of landclaims placed!", Color.Red)
        return
    end

    self:PlaceLandclaim(size, player)
    
end

sLandclaimManager = sLandclaimManager()