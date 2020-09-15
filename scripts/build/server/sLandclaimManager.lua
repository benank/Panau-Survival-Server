class 'sLandclaimManager'

function sLandclaimManager:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS landclaims (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, position VARCHAR, name VARCHAR(20), size INTEGER, expire_date VARCHAR, build_access_mode INTEGER, objects BLOB)")

    self.landclaims = {} -- [steam_id] = {[landclaim_id] = landclaim, [landclaim_id] = landclaim}

    Network:Subscribe("build/PlaceLandclaim", self, self.TryPlaceLandclaim)
    Network:Subscribe("build/ReadyForInitialSync", self, self.PlayerReadyForInitialSync)
    Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated)
    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    Events:Subscribe("items/PlaceObjectInLandclaim", self, self.PlaceObjectInLandclaim)

end

function sLandclaimManager:PlaceObjectInLandclaim(args)

    if not IsValid(args.player) then return end

    -- Find the first (and should be only) landclaim that contains this position
    local target_landclaim = self:FindFirstLandclaimContainingPosition(args.position)

    -- No valid landclaim found; can't place here
    if not target_landclaim then return end

    target_landclaim:PlaceObject(args)

end

function sLandclaimManager:FindFirstLandclaimContainingPosition(pos)
    for steam_id, landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(landclaims) do
            if IsInSquare(landclaim.position, landclaim.size, pos) then
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
        print(string.format("Loaded %d landclaims!", count_table(result)))
    end

end

function sLandclaimManager:ParseLandclaimDataFromDB(data)
    output_table(data)
    local owner_id = tostring(data.steamID)
    local landclaim_id = tonumber(data.id)

    self:AddClaim({
        size = tonumber(data.size),
        position = DeserializePosition(tostring(data.position)),
        owner_id = tostring(owner_id),
        name = tostring(data.name),
        expiry_date = tostring(data.expire_date),
        access_mode = tonumber(data.build_access_mode),
        objects = data.objects,
        id = landclaim_id
    })

end

function sLandclaimManager:ModuleLoad()
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
    return landclaim

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
        objects = {}
    }
    
    local cmd = SQL:Command("INSERT INTO landclaims (steamID, position, name, size, expire_date, build_access_mode, objects) VALUES (?, ?, ?, ?, ?, ?, ?)")
    cmd:Bind(1, landclaim_data.owner_id)
    cmd:Bind(2, SerializePosition(landclaim_data.position))
    cmd:Bind(3, landclaim_data.name)
    cmd:Bind(4, landclaim_data.size)
    cmd:Bind(5, landclaim_data.expiry_date)
    cmd:Bind(6, landclaim_data.access_mode)
    cmd:Bind(7, "")
    cmd:Execute()

    
    cmd = SQL:Query("SELECT last_insert_rowid() as insert_id FROM landclaims")
    local result = cmd:Execute()
    landclaim_data.id = tonumber(result[1].insert_id)

    local landclaim = self:AddClaim(landclaim_data)
    landclaim:Sync()
    Chat:Send(player, "LandClaim placed successfully!", Color.Green)

end

function sLandclaimManager:SendPlayerErrorMessage(player)
    Chat:Send(player, "Placing landclaim failed!", Color.Red)
end

function sLandclaimManager:TryPlaceLandclaim(args, player)

    local player_iu = player:GetValue("LandclaimUsingItem")

    player:SetValue("LandclaimUsingItem", nil)
    Inventory.OperationBlock({player = player, change = -1})

    if not player_iu then return end
    if not player_iu.item then return end

    local item = player_iu.item

    if item.name ~= "LandClaim" then return end

    local size = tonumber(item.custom_data.size)

    if not size then
        self:SendPlayerErrorMessage(player)
        return
    end


    local position = player:GetPosition()
    
    if player:InVehicle() then
        Chat:Send(player, "Cannot place landclaims while in a vehicle!", Color.Red)
        return
    end

    local steam_id = tostring(player:GetSteamId())
    local num_player_landclaims = self.landclaims[steam_id] and count_table(self.landclaims[steam_id]) or 0
    if num_player_landclaims >= player:GetValue("MaxLandclaims") then
        Chat:Send(player, "You already have the maximum amount of landclaims placed!", Color.Red)
        return
    end

    if not self.sz_config then
        self.sz_config = SharedObject.GetByName("SafezoneConfig"):GetValues()
    end

    local BlacklistedAreas = SharedObject.GetByName("BlacklistedAreas"):GetValues().blacklist

    for _, area in pairs(BlacklistedAreas) do
        if position:Distance(area.pos) < size + 50 then
            self:SendPlayerErrorMessage(player)
            return
        end
    end

    -- If they are within nz radius * 3, we don't let them place that close
    if position:Distance(self.sz_config.neutralzone.position) < self.sz_config.neutralzone.radius * 3 + size then
        self:SendPlayerErrorMessage(player)
        return
    end

    local ModelChangeAreas = SharedObject.GetByName("ModelLocations"):GetValues()

    for _, area in pairs(ModelChangeAreas) do
        if position:Distance(area.pos) < 200 + size then
            self:SendPlayerErrorMessage(player)
            return
        end
    end

    -- Check for proximity to existing landclaims
    for steamid, landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(landclaims) do
            if steamid ~= steam_id and Distance2D(position, landclaim.position) < size / 2 + landclaim.size / 2 + 100 then
                self:SendPlayerErrorMessage(player)
                return
            end
        end
    end

    Inventory.RemoveItem({
        item = player_iu.item,
        index = player_iu.index,
        player = player
    })

    self:PlaceLandclaim(size, player)

end

sLandclaimManager = sLandclaimManager()