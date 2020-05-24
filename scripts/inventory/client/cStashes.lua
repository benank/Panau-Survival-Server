class 'cStashes'

function cStashes:__init()

    self.stashes = {}

    Events:Fire("Stashes/ResetStashesMenu")
    Events:Subscribe("Stashes/RenameStash", self, self.RenameStash)
    Network:Subscribe("Stashes/SyncMyStashes", self, self.SyncMyStashes)
    Network:Subscribe("Stashes/Sync", self, self.SyncStash)
    Events:Subscribe("Stashes/DeleteStash", self, self.DeleteStash)

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