class 'sMine'

function sMine:__init(args)

    self.id = args.id
    self.position = args.position
    self.angle = args.angle
    self.owner_id = args.owner_id
    self.exploded = false
    self.exploding = false
    self.cell = GetCell(self.position, ItemsConfig.usables.Mine.cell_size)

end

function sMine:Trigger(player)

    if self.exploded or self.exploding then return false end -- Already exploded
    if tostring(player:GetSteamId()) == self.owner_id then return false end -- This is the owner, don't explode
    if AreFriends(player, self.owner_id) then return end -- Owner is a friend

    -- No need to sort players by cells for this, so just send nearby to remove
    -- Don't send to player who triggered in case they are lagging so it will trigger instantly for them
    --Network:Send(player, "items/MineTrigger", {position = self.position, id = self.id})
    Network:SendNearby(player, "items/MineTrigger", {position = self.position, id = self.id})

    self.exploding = true

    return true

end

-- Syncs a newly placed mine to the player and nearby players
function sMine:SyncNearby(player)
    Network:Send(player, "items/MineSyncOne", self:GetSyncObject())
    Network:SendNearby(player, "items/MineSyncOne", self:GetSyncObject())
end

function sMine:GetCell()
    return self.cell
end

function sMine:Remove(player)
    if not IsValid(player) then return end
    Network:Send(player, "items/RemoveMine", {id = self.id, cell = self.cell})
    Network:SendNearby(player, "items/RemoveMine", {id = self.id, cell = self.cell})
end


function sMine:GetSyncObject()
    return {
        id = self.id,
        position = self.position,
        angle = self.angle,
        owner_id = self.owner_id
    }
end