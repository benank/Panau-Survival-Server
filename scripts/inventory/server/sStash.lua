class 'sStash'

function sStash:__init(args)

    self.id = args.id
    self.lootbox = args.lootbox
    self.owner_id = args.owner_id
    self.access_mode = args.access_mode
    self.name = args.name
    self.health = math.min(args.health, Lootbox.Stashes[self.lootbox.tier].health)
    self.capacity = Lootbox.Stashes[self.lootbox.tier].capacity
    self.can_change_access = self.lootbox.tier == Lootbox.Types.LockedStash

    self.lootbox.stash = self

end

-- Returns whether or not a player can open a stash
function sStash:CanPlayerOpen(player)
    if self.access_mode == StashAccessMode.Everyone then
        return true
    elseif self.access_mode == StashAccessMode.Friends then
        return AreFriends(player, self.owner_id) or self:IsPlayerOwner(player)
    elseif self.access_mode == StashAccessMode.OnlyMe then
        return self:IsPlayerOwner(player)
    end
end

-- Returns whether or not a player is owner
function sStash:IsPlayerOwner(player)
    return IsValid(player) and tostring(player:GetSteamId()) == self.owner_id
end

function sStash:ChangeName(name, player)

    name = tostring(name):sub(1, 30):trim()

    if not name then return end
    if name:len() < 3 then return end
    
    if not self:IsPlayerOwner(player) then return end
    
    self.name = name
    
    self:UpdateToDB()
    self:Sync(player)

end

function sStash:ChangeAccessMode(mode, player)

    -- Invalid access mode
    if mode ~= StashAccessMode.Everyone
    and mode ~= StashAccessMode.Friends
    and mode ~= StashAccessMode.OnlyMe then return end

    -- Player is not owner of this stash
    if not self:IsPlayerOwner(player) then return end

    -- Cannot change access mode of this type of stash
    if not self.can_change_access then return end

    self.access_mode = mode
    self:UpdateToDB()

    self:Sync(player)
    self.lootbox:Sync()

    -- Force close lootbox for players who cannot open anymore
    for id, p in pairs(self.lootbox.players_opened) do
        if not self:CanPlayerOpen(p) then
            self.lootbox:ForceClose(p)
        end
    end

end

function sStash:UpdateToDB()
    -- Updates stash to DB, including contents and access type

    if self.lootbox.tier == Lootbox.Types.Workbench then return end
    
	local command = SQL:Command("UPDATE stashes SET contents = ?, name = ?, access_mode = ?, health = ?, steamID = ? WHERE id = (?)")
	command:Bind(1, Serialize(self.lootbox.contents))
	command:Bind(2, self.name)
	command:Bind(3, self.access_mode)
	command:Bind(4, self.health)
	command:Bind(5, self.owner_id)
	command:Bind(6, self.id)
	command:Execute()

end

-- Called when the contents of the stash are changed by player
function sStash:ContentsChanged(player)
    if tostring(player:GetSteamId()) == self.owner_id then
        self:Sync(player)
    else

        local owner = nil

        for p in Server:GetPlayers() do
            if tostring(p:GetSteamId()) == self.owner_id then
                owner = p
            end
        end

        if IsValid(owner) then
            self:Sync(owner)
        end

    end
end

function sStash:Sync(player)
    if not IsValid(player) then return end
    if tostring(player:GetSteamId()) ~= self.owner_id then return end
    if self.lootbox.tier == Lootbox.Types.ProximityAlarm then return end
    Network:Send(player, "Stashes/Sync", self:GetSyncData())

    local player_stashes = player:GetValue("Stashes")
    player_stashes[self.id] = self:GetSyncData()
    player:SetValue("Stashes", player_stashes)
end

-- Removes the stash from the world, DB, and owner's menu
function sStash:Remove()

    -- Create dropbox with contents
    local cmd = SQL:Command("DELETE FROM stashes where id = ?")
    cmd:Bind(1, self.id)
    cmd:Execute()
    
    self.lootbox:Remove()

end

function sStash:GetSyncData()
    return {
        id = self.id,
        access_mode = self.access_mode,
        owner_id = self.owner_id,
        name = self.name,
        capacity = self.capacity,
        position = self.lootbox.position,
        can_change_access = self.can_change_access,
        num_items = count_table(self.lootbox.contents)
    }
end