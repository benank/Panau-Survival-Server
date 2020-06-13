class 'sWorkBench'

function sWorkBench:__init(args)

    self.state = WorkBenchState.Idle
    self.name = args.name

    self.lootbox = args.lootbox
    self.stash = args.stash

end

function sWorkBench:SyncStatus(player, finished)

    local data = 
    {
        state = self.state,
        finished = finished,
        name = self.name,
        position = self.lootbox.position
    }

    if not IsValid(player) then
        Network:Broadcast("Workbenches/SyncStatus", data)
    else
        Network:Send(player, "Workbenches/SyncStatus", data)
    end
end

function sWorkBench:BeginCombining(player)

    if self.state ~= WorkBenchState.Idle then return end

    if not self:CanConbineItems() then
        Chat:Send(player, "These items cannot be combined.", Color.Red)
        return
    end

    self.state = WorkBenchState.Combining
    self.stash.access_mode = StashAccessMode.OnlyMe
    self.lootbox:ForceClose()
    self.lootbox:Sync()
    self.stash:Sync()
    
    self:SyncStatus()

    local combined_dura = self:GetCombinedDurability()
    local max_dura = self.lootbox.contents[1].contents[1].max_durability
    local name = self.lootbox.contents[1]:GetProperty("name")
    local combine_time = combined_dura / max_dura * WorkBenchConfig.time_to_combine

    Timer.SetTimeout(1000 * combine_time, function()
    
        local new_item = CreateItem({
            name = name,
            amount = 1,
            durability = combined_dura
        })

        self.lootbox.contents = {[1] = shStack({contents = {new_item}})}
    
        self.state = WorkBenchState.Idle
        self.stash.access_mode = StashAccessMode.Everyone

        self.stash:Sync()
        self.lootbox:Sync()

        self:SyncStatus()

    end)

end

function sWorkBench:GetCombinedDurability()

    local max_dura = self.lootbox.contents[1].contents[1].max_durability

    local combined_dura = max_dura * WorkBenchConfig.durability_bonus

    for _, stack in pairs(self.lootbox.contents) do
        for _, item in pairs(stack.contents) do
            combined_dura = combined_dura + item.durability
        end
    end

    combined_dura = math.min(max_dura * WorkBenchConfig.maximum_durability, combined_dura)

    return combined_dura

end

-- Returns whether or not the items in the workbench can be combined
function sWorkBench:CanConbineItems()

    if count_table(self.lootbox.contents) < 1 then return false end

    local target_stack = self.lootbox.contents[1]

    if count_table(self.lootbox.contents) == 1 and target_stack:GetAmount() == 1 then return false end

    if WorkBenchConfig.blacklisted_items[target_stack:GetProperty("name")] then return false end
    if not target_stack:GetProperty("durability") then return end

    for _, stack in pairs(self.lootbox.contents) do
        if stack:GetProperty("name") ~= target_stack:GetProperty("name") then return false end
    end

    return true

end