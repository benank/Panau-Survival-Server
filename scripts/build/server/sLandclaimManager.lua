class 'sLandclaimManager'

function sLandclaimManager:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS landclaims (id INTEGER PRIMARY KEY AUTOINCREMENT, steamID VARCHAR, position VARCHAR, build_access_mode INTEGER, objects BLOB)")

    self.landclaims = {} -- [steam_id] = {[landclaim_id] = landclaim, [landclaim_id] = landclaim}

    Network:Subscribe("build/PlaceLandclaim", self, self.TryPlaceLandclaim)
    Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)

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

function sLandclaimManager:ClientModuleLoad(args)

    -- Send player landclaim data of their owned landclaims

end

function sLandclaimManager:PlaceLandclaim(radius, player)

    local position = player:GetPosition()
    
    
    local cmd = SQL:Command("INSERT INTO landclaims (steamID, position, angle) VALUES (?, ?, ?)")
    cmd:Bind(1, steamID)
    cmd:Bind(2, tostring(position))
    cmd:Bind(3, self:SerializeAngle(angle))
    cmd:Execute()

end

function sLandclaimManager:SendPlayerErrorMessage(player)
    Chat:Send(player, "Placing landclaim failed!", Color.Red)
end

function sLandclaimManager:TryPlaceLandclaim(args, player)

    local player_iu = player:GetValue("ItemUse")

    if not player_iu then return end
    if not player_iu.item then return end

    local item = player_iu.item

    if item.name ~= "LandClaim" then return end

    local radius = item.custom_data.size

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
        if position:Distance(area.pos) < radius then
            self:SendPlayerErrorMessage(player)
            return
        end
    end

    -- If they are within nz radius * 3, we don't let them place that close
    if position:Distance(self.sz_config.neutralzone.position) < self.sz_config.neutralzone.radius * 3 + radius then
        self:SendPlayerErrorMessage(player)
        return
    end

    local ModelChangeAreas = SharedObject.GetByName("ModelLocations"):GetValues()

    for _, area in pairs(ModelChangeAreas) do
        if position:Distance(area.pos) < 200 + radius then
            self:SendPlayerErrorMessage(player)
            return
        end
    end

    -- Check for proximity to existing landclaims
    -- TODO: don't check for proximity for owned landclaims
    for steamid, landclaims in pairs(self.landclaims) do
        for id, landclaim in pairs(landclaims) do
            if Distance2D(position, landclaim.position) < radius + landclaim.radius then
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

    self:PlaceLandclaim(radius, player)

end

sLandclaimManager = sLandclaimManager()