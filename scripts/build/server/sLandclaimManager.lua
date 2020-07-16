class 'sLandclaimManager'

function sLandclaimManager:__init()

    self.landclaims = {} -- [steam_id] = {[landclaim_id] = landclaim, [landclaim_id] = landclaim}

    Network:Subscribe("build/PlaceLandclaim", self, self.TryPlaceLandclaim)

end

function sLandclaimManager:PlaceLandclaim(radius, player)



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