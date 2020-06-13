class 'sWorkBench'

function sWorkBench:__init(args)

    self.state = WorkBenchState.Idle
    self.nearby_players = {}


    self.lootbox = args.lootbox
    self.stash = args.stash

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

    Timer.SetTimeout(1000 * WorkBenchConfig.time_to_combine, function()
    
        local item1 = self.lootbox.contents[1]
        local item2 = self.lootbox.contents[2]
    
        local max_dura = item1.contents[1].max_durability
        local combined_dura = item1.contents[1].durability + item2.contents[1].durability

        combined_dura = combined_dura + max_dura * WorkBenchConfig.durability_bonus
        combined_dura = math.min(max_dura * WorkBenchConfig.maximum_durability, combined_dura)

        local new_item = CreateItem({
            name = item1:GetProperty("name"),
            amount = 1,
            durability = combined_dura
        })

        self.lootbox.contents = {new_item}
    
        self.lootbox:Sync()

        self.state = WorkBenchState.Idle
        self.stash.access_mode = StashAccessMode.Everyone

    end)

end

-- Returns whether or not the items in the workbench can be combined
function sWorkBench:CanConbineItems()

    if count_table(self.lootbox.contents) < 2 then return false end

    local item1 = self.lootbox.contents[1]
    local item2 = self.lootbox.contents[2]

    if WorkBenchConfig.blacklisted_items[item1:GetProperty("name")] then return false end

    if item1:GetAmount() > 1 or item2:GetAmount() > 1 then return false end
    if item1:GetProperty("name") ~= item2:GetProperty("name") then return false end
    if not item1:GetProperty("durability") or not item2:GetProperty("durability") then return false end

    return true

end