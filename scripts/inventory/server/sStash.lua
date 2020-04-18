class 'sStash'

function sStash:__init(args)

    self.lootbox = args.lootbox
    self.owner_id = args.owner_id
    self.access_mode = args.access_mode
    self.capacity = Lootbox.Stashes[self.lootbox.tier].capacity

    self.lootbox.stash = self

end

-- Returns whether or not a player can open a stash
function sStash:CanPlayerOpen(player)
    if self.access_mode == StashAccessMode.Everyone then
        return true
    elseif self.access_mode == StashAccessMode.Friends then
        return IsAFriend(player, self.owner_id) or self:IsPlayerOwner(player)
    elseif self.access_mode == StashAccessMode.OnlyMe then
        return self:IsPlayerOwner(player)
    end
end

-- Returns whether or not a player is owner
function sStash:IsPlayerOwner(player)
    return tostring(player:GetSteamId()) == self.owner_id
end

function sStash:ChangeAccessMode(mode, player)

    -- Invalid access mode
    if mode ~= StashAccessMode.Everyone
    and mode ~= StashAccessMode.Friends
    and mode ~= StashAccessMode.OnlyMe then return end

    -- Player is not owner of this stash
    if not self:IsPlayerOwner(player) then return end

    self.access_mode = mode
    self:UpdateToDB()

    -- Also sync new access mode to owner

end

function sStash:UpdateToDB()
    -- Update stash to DB, including contents and access type
end