class 'sItemGenerator'

function sItemGenerator:__init()

    self.computed_rarity_sums = {}

    self:ComputeRaritySums()

    -- Test command for generating loot
    Console:Subscribe("loot", function()
    
        local tier = 1

        local loot = ItemGenerator:GetLoot(tier)
        print("Level " .. tostring(tier) .. " Loot")
    

        for k,v in pairs(loot) do
            print(v:GetProperty("name") .. " [x" .. tostring(v:GetAmount()) .. "]")
        end
    
    end)

end

-- Returns a table of contents yummy
function sItemGenerator:GetLoot(tier)

    local contents = {}

    local num_items = math.random(Lootbox.GeneratorConfig.box[tier].min_items, Lootbox.GeneratorConfig.box[tier].max_items)
    local groups = {}

    for i = 1, num_items do
        table.insert(contents, self:GetStack(tier, groups))
    end

    return contents

end

function sItemGenerator:GetStack(tier, groups)

    if not Lootbox.GeneratorConfig.spawnable[tier] then
        error(debug.traceback("sItemGenerator:GetItem failed: invalid tier specified"))
    end

    local group = self:FindGroupName(tier)

    while groups[group] and count_table(LootItems[tier]) > 1 do
        group = self:FindGroupName(tier)
    end

    groups[group] = true

    local target = self.computed_rarity_sums[tier][group] * math.random()

    local item_name, item_data_loot = self:FindTargetItem(target, tier, group)

    if item_name then

        local item_data = Items_indexed[item_name]
        item_data.amount = 1
        item_data.min_dura_amt = item_data_loot.min_dura
        item_data.max_dura_amt = item_data_loot.max_dura


        local item = CreateItem(item_data)
        local extra_custom_data = self:GetTierSpecificCustomData(tier, item)

        for key, value in pairs(extra_custom_data) do
            item.custom_data[key] = value
        end

        local stack = shStack({contents = {item}})
        local amount = self:GetItemAmount(LootItems[tier][group].items[item_name], tier)

        -- Add items to stack like this so it handles all the dirty work for us
        for i = 1, amount - 1 do -- Amount - 1 because there is already one item in there
            stack:AddItem(CreateItem(item_data))
        end

        return stack

    else
        -- I don't really know why it wouldn't find an item, but hey try again if it happens
        return self:GetStack(tier)

    end

end

function sItemGenerator:GetTierSpecificCustomData(tier, item)

    local custom_data = {}

    if item.name == "LandClaim" then
        
        -- Landclaim size chances based on loot tier
        local sizes = 
        {
            {chance = 0.8, min = 20, max = 50},
            {chance = 0.95, min = 50, max = 100},
            {chance = 1.0, min = 100, max = 200}
        }

        if tier == Lootbox.Types.Level3 then
            sizes = 
            {
                {chance = 0.95, min = 20, max = 50},
                {chance = 0.05, min = 50, max = 100}
            }
        elseif tier == Lootbox.Types.AirdropLevel1 then
            sizes = 
            {
                {chance = 0.4, min = 30, max = 60},
                {chance = 0.9, min = 60, max = 100},
                {chance = 1.0, min = 100, max = 200}
            }
        elseif tier == Lootbox.Types.AirdropLevel2 then
            sizes = 
            {
                {chance = 0.7, min = 50, max = 100},
                {chance = 1.0, min = 100, max = 200}
            }
        elseif tier == Lootbox.Types.AirdropLevel3 then
            sizes = 
            {
                {chance = 1.0, min = 150, max = 250}
            }
        elseif tier == Lootbox.Types.Lockbox then
            sizes = 
            {
                {chance = 1.0, min = 100, max = 200}
            }
        elseif tier == Lootbox.Types.LockboxX then
            sizes = 
            {
                {chance = 1.0, min = 100, max = 300}
            }
        end

        local random = math.random()

        for _, size_data in ipairs(sizes) do
            if random <= size_data.chance then
                custom_data.size = size_data.min + math.random(size_data.max - size_data.min)
                break
            end
        end

    elseif item.name == "Airdrop" then
        
        -- Landclaim size chances based on loot tier
        local sizes = 
        {
            {chance = 0.5, min = 1, max = 1},
            {chance = 1.0, min = 2, max = 2},
        }

        if tier == Lootbox.Types.Lockbox then
            sizes = 
            {
                {chance = 0.5, min = 1, max = 1},
                {chance = 1.0, min = 2, max = 2},
            }
        elseif tier == Lootbox.Types.LockboxX then
            sizes = 
            {
                {chance = 0.3, min = 2, max = 2},
                {chance = 1.0, min = 3, max = 3},
            }
        elseif tier == Lootbox.Types.Drone60to100 then
            sizes = 
            {
                {chance = 1.0, min = 1, max = 1},
            }
        elseif tier == Lootbox.Types.Drone100Plus then
            sizes = 
            {
                {chance = 0.9, min = 1, max = 2},
                {chance = 1.0, min = 1, max = 3},
            }
        end

        local random = math.random()

        for _, size_data in ipairs(sizes) do
            if random <= size_data.chance then
                local random_amount = size_data.max - size_data.min ~= 0 and math.random(size_data.max - size_data.min) or 0
                custom_data.level = size_data.min + random_amount
                break
            end
        end
        
    end

    return custom_data
end

function sItemGenerator:GetItemAmount(item, tier)
    return math.random(item.min, item.max)
end

function sItemGenerator:FindTargetItem(target, tier, group)

    local sum = 0

    for item_name, item_data in pairs(LootItems[tier][group].items) do

        sum = sum + item_data.rarity

        if target <= sum then
            return item_name, item_data
        end

    end

end

function sItemGenerator:FindGroupName(tier)
    
    local random = math.random()
    local sum = 0

    for group_name, group_data in pairs(LootItems[tier]) do

        sum = sum + group_data.rarity

        if random <= sum then
            return group_name
        end

    end

    error(debug.traceback("No group name found in sItemGenerator:FindGroupName! Did you make the rarities absolute? Tier: " .. tier))

end

function sItemGenerator:ComputeRaritySums()

    for tier, tier_data in pairs(LootItems) do

        self.computed_rarity_sums[tier] = {}

        for group_name, group_data in pairs(tier_data) do

            self.computed_rarity_sums[tier][group_name] = 0

            for _, item_data in pairs(group_data.items) do

                -- Sum up all the rarities per tier
                self.computed_rarity_sums[tier][group_name] = self.computed_rarity_sums[tier][group_name] + item_data.rarity

            end
        end

    end

end

ItemGenerator = sItemGenerator()