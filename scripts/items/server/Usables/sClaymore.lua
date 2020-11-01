class 'sClaymore'

function sClaymore:__init(args)

    self.id = args.id
    self.position = args.position
    self.angle = args.angle
    self.owner_id = args.owner_id
    self.exploded = false
    self.cell = GetCell(self.position, ItemsConfig.usables.Claymore.cell_size)
    self.landclaim_data = args.landclaim_data
    self.lootbox_uid = args.lootbox_uid

end

function sClaymore:OnExplode()
    if self.landclaim_data then
        Events:Fire("items/DetonateOnBuildObject", {
            landclaim_data = self.landclaim_data,
            owner_id = self.owner_id,
            player = sProxAlarms.players[self.owner_id],
            type = "Claymore"
        })
    elseif self.lootbox_uid then
        Events:Fire("items/DetonateOnStash", {
            lootbox_uid = self.lootbox_uid,
            owner_id = self.owner_id,
            player = sProxAlarms.players[self.owner_id],
            type = "Claymore"
        })
    end
end

function sClaymore:Trigger(player)

    if self.exploded then return false end -- Already exploded
    if tostring(player:GetSteamId()) == self.owner_id then return false end -- This is the owner, don't explode
    if AreFriends(player, self.owner_id) then return end -- Owner is a friend

    -- No need to sort players by cells for this, so just send nearby to remove
    -- Don't send to player who triggered in case they are lagging so it will trigger instantly for them
    Network:SendNearby(player, "items/ClaymoreExplode", {position = self.position, id = self.id})

    self.exploded = true

    self:OnExplode()

    return true

end

function sClaymore:Sync()
    Network:Broadcast("items/ClaymoreSyncOne", self:GetSyncObject())
end

-- Syncs a newly placed claymore to the player and nearby players
function sClaymore:SyncNearby(player)
    Network:Send(player, "items/ClaymoreSyncOne", self:GetSyncObject())
    Network:SendNearby(player, "items/ClaymoreSyncOne", self:GetSyncObject())
end

function sClaymore:GetCell()
    return self.cell
end

function sClaymore:Remove(player)
    if not IsValid(player) then return end
    Network:Send(player, "items/RemoveClaymore", {id = self.id, cell = self.cell})
    Network:SendNearby(player, "items/RemoveClaymore", {id = self.id, cell = self.cell})
end


function sClaymore:GetSyncObject()
    return {
        id = self.id,
        position = self.position,
        angle = self.angle,
        owner_id = self.owner_id
    }
end