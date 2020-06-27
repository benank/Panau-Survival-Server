class 'cStashes'

function cStashes:__init()

    self.stashes = {}

    Events:Fire("Stashes/ResetStashesMenu")
    Events:Subscribe("Stashes/RenameStash", self, self.RenameStash)
    Network:Subscribe("Stashes/SyncMyStashes", self, self.SyncMyStashes)
    Network:Subscribe("Stashes/Sync", self, self.SyncStash)
    Events:Subscribe("Stashes/DeleteStash", self, self.DeleteStash)

    Thread(function()
        while true do
            Timer.Sleep(1000)
            self:CheckStashModels()
        end
    end)

end

function cStashes:CheckStashModels()

    local cam_pos = Camera:GetPosition()

    -- Hide locked stashes until you get close
    for x, _ in pairs(LootManager.loot) do
        for y, _ in pairs(LootManager.loot[x]) do
            for uid, lootbox in pairs(LootManager.loot[x][y]) do

                if lootbox.tier == Lootbox.Types.LockedStash then

                    local dist = cam_pos:Distance(lootbox.position)

                    if dist > 30 and not lootbox.hidden then
                        lootbox:Remove(true)
                    elseif dist < 30 and lootbox.hidden then
                        lootbox:CreateModel(true)
                    end

                end

                Timer.Sleep(1)
            end
        end
    end

end

function cStashes:DeleteStash(args)
    Network:Send("Stashes/DeleteStash", {
        id = args.id
    })
end

-- Called when one stash is synced
function cStashes:SyncStash(data)

    if LootManager.current_box and LootManager.current_box.stash and LootManager.current_box.stash.id == data.id then
        LootManager.current_box.stash = deepcopy(data)
    end
    
    data.access_mode = StashAccessModeStrings[data.access_mode]
    self.stashes[data.id] = data

    Events:Fire("Stashes/UpdateStashes", self.stashes)
end

function cStashes:RenameStash(args)
    Network:Send("Stashes/RenameStash", {
        name = args.name,
        id = args.id
    })
end

function cStashes:SyncMyStashes(my_stashes)

    -- Convert all numbered access modes to strings
    for id, stash_data in pairs(my_stashes) do
        my_stashes[id].access_mode = StashAccessModeStrings[stash_data.access_mode]
    end

    self.stashes = my_stashes

    Events:Fire("Stashes/UpdateStashes", self.stashes)
end

cStashes = cStashes()