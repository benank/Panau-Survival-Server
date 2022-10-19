class 'sWorkBench'

function sWorkBench:__init(args)

    self.state = WorkBenchState.Idle
    self.name = args.name

    self.lootbox = args.lootbox
    self.stash = args.stash

    self.timer = Timer()
    self.combine_time = 0

end

function sWorkBench:SyncStatus(player, finished)

    local data = 
    {
        state = self.state,
        finished = finished,
        name = self.name,
        position = self.lootbox.position,
        time_left = self.combine_time - self.timer:GetSeconds()
    }

    if not IsValid(player) then
        Network:Broadcast("Workbenches/SyncStatus", data)
    else
        Network:Send(player, "Workbenches/SyncStatus", data)
    end
end

function sWorkBench:BeginCombining(player)

    if self.state ~= WorkBenchState.Idle then return end

    local perks = player:GetValue("Perks")

    if not perks.unlocked_perks[WorkBenchConfig.use_perk_req] then
        local perks_by_id = SharedObject.GetByName("ExpPerksById"):GetValue("Perks")
        Chat:Send(player, 
            string.format("You must unlock the Workbench perk (#%d) in order to use this. Hit F2 to open the perks menu. (Free perk)", 
            perks_by_id[WorkBenchConfig.use_perk_req].position), Color.Red)
        return
    end

    local can_combine = self:CanCombineItems()
    local recipe = sWorkBenchCrafting:GetCraftingRecipeFromContentsIfExists(self.lootbox.contents)
    if not can_combine and recipe == nil then
        Chat:Send(player, "These items cannot be combined.", Color.Red)
        return
    end
    
    self.state = WorkBenchState.Combining
    self.stash.access_mode = StashAccessMode.OnlyMe
    self.lootbox:ForceClose()
    self.lootbox:Sync()
    self.stash:Sync()

    self.timer = Timer()
    
    if can_combine then
        self:CombineItems(player)
    elseif recipe ~= nil then
        self:CraftItems(player, recipe)
    end
    
end

function sWorkBench:CraftItems(player, recipe)

    self.combine_time = recipe.craft_time
    
    local recipe_items = ""
    for _, item_req in pairs(recipe.recipe) do
        recipe_items = item_req.name .. ", " .. recipe_items
    end

    self:SyncStatus()

    if recipe.announce ~= nil then
        Chat:Broadcast("[BROADCAST] ", Color.Red, 
            string.format("%s started crafting a %s at the %s! Crafting will complete in %s minutes.",
            player:GetName(), recipe.result_item.name, self.name, tostring(recipe.craft_time / 60)), Color.Yellow)
        Events:Fire("Discord", {
            channel = "Airdrops",
            content = string.format(recipe.announce, 
                player:GetName(), recipe.result_item.name, self.name, tostring(recipe.craft_time / 60))
        })
    end
    
    Events:Fire("Discord", {
        channel = "Inventory",
        content = string.format("%s [%s] started a craft of %s using %s at the %s", 
            player:GetName(), tostring(player:GetSteamId()), recipe.result_item.name, recipe_items, self.name)
    })

    Timer.SetTimeout(1000 * self.combine_time, function()
    
        local durability = recipe.result_item.durability
        
        if recipe.result_item.add_dura then
            local current_dura = 0
            
            for _, stack in pairs(self.lootbox.contents) do
                if stack:GetProperty("name") ==  recipe.result_item.add_dura.from then
                    current_dura = stack.contents[1].durability
                    break
                end
            end
            
            durability = current_dura + recipe.result_item.add_dura.amount
        end
        
        local new_item = CreateItem({
            name = recipe.result_item.name,
            amount = 1,
            durability = durability
        })
        
        if recipe.result_item.custom_data then
            new_item.custom_data = recipe.result_item.custom_data(new_item.custom_data, self.lootbox.contents)
        end
            
        -- Durability over 500%
        if new_item.durability and new_item.durability < durability then
             new_item.durability = new_item.max_durability * WorkBenchConfig.maximum_durability
        end
        
        self.lootbox.contents = {[1] = shStack({contents = {new_item}})}
    
        self.state = WorkBenchState.Idle
        self.stash.access_mode = StashAccessMode.Everyone

        self.stash:Sync()
        self.lootbox:Sync()

        self:SyncStatus()

        Events:Fire("Discord", {
            channel = "Inventory",
            content = string.format("Finished a craft of %s at the %s", 
                self.lootbox.contents[1]:GetProperty("name"), self.name)
        })
    
    end)
 
end

function sWorkBench:CombineItems(player)
   
    local combined_dura = self:GetCombinedDurability()
    local max_dura = self.lootbox.contents[1].contents[1].max_durability
    local name = self.lootbox.contents[1]:GetProperty("name")
    local durability_percent = combined_dura / max_dura

    combine_time = self:GetCombineTime(durability_percent, player)

    self.combine_time = combine_time

    self:SyncStatus()

    Events:Fire("Discord", {
        channel = "Inventory",
        content = string.format("%s [%s] started a combine of %s at the %s", 
            player:GetName(), tostring(player:GetSteamId()), self.lootbox.contents[1]:GetProperty("name"), self.name)
    })

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

        Events:Fire("Discord", {
            channel = "Inventory",
            content = string.format("Finished a combine of %s [New dura: %.0f] at the %s", 
                self.lootbox.contents[1]:GetProperty("name"), combined_dura, self.name)
        })
    
    end)
 
end

function sWorkBench:GetCombineTime(total_durability_percent, player)

    local num_items = 0
    local max_dura_percent = math.min(total_durability_percent, WorkBenchConfig.maximum_durability)

    for _, stack in pairs(self.lootbox.contents) do
        num_items = num_items + stack:GetAmount()
    end

    local perks = player:GetValue("Perks")
    local perk_mod = 1

    for perk_id, _ in pairs(perks.unlocked_perks) do
        if WorkBenchConfig.perks[perk_id] then
            perk_mod = math.min(perk_mod, WorkBenchConfig.perks[perk_id])
        end
    end

    local combine_time = math.min(240 * perk_mod, math.ceil(max_dura_percent * max_dura_percent * 4.8 / total_durability_percent * num_items * perk_mod))
    return math.ceil(combine_time / 2)

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
function sWorkBench:CanCombineItems()

    if count_table(self.lootbox.contents) < 1 then return false end

    local target_stack = self.lootbox.contents[1]

    if count_table(self.lootbox.contents) == 1 and target_stack:GetAmount() == 1 then return false end

    if WorkBenchConfig.blacklisted_items[target_stack:GetProperty("name")] then return false end
    if not target_stack:GetProperty("durability") then return end

    for _, stack in pairs(self.lootbox.contents) do
        if stack:GetProperty("name") ~= target_stack:GetProperty("name") then return false end
        for _, item in pairs(stack.contents) do
            -- If there is a max item in there, don't combine
            if item.durability == item.max_durability * WorkBenchConfig.maximum_durability then return false end
        end
    end

    return true

end