class 'sMine'

function sMine:__init(args)

    self.id = args.id
    self.position = args.position
    self.owner_id = args.owner_id
    self.exploded = false
    self.cell_x, self.cell_y = GetCell(self.position, ItemsConfig.usables.Mine.cell_size)

end

function sMine:Explode(player)

    if self.exploded then return false end -- Already exploded
    if tostring(player:GetSteamId()) == self.owner_id then return false end -- This is the owner, don't explode

    -- No need to sort players by cells for this, so just send nearby to remove
    Network:Send(player, "items/MineExplode", {position = self.position, id = self.id})
    Network:SendNearby(player, "items/MineExplode", {position = self.position, id = self.id})

    self.exploded = true

    return true

end

-- Syncs a newly placed mine to the player and nearby players
function sMine:SyncNearby(player)
    Network:Send(player, "items/MineSyncOne", self:GetSyncObject())
    Network:SendNearby(player, "items/MineSyncOne", self:GetSyncObject())
end

function sMine:GetCell()
    return {x = self.cell_x, y = self.cell_y}
end

function sMine:Remove(player)
    Network:Send(player, "items/RemoveMine", {id = self.id, cell = {x = self.cell_x, y = self.cell_y}})
    Network:SendNearby(player, "items/RemoveMine", {id = self.id, cell = {x = self.cell_x, y = self.cell_y}})
end


function sMine:GetSyncObject()
    return {
        id = self.id,
        position = self.position,
        owner_id = self.owner_id
    }
end