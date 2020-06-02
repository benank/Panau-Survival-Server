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

    local item_name = self:FindTargetItem(target, tier, group)

    if item_name then

        local item_data = Items_indexed[item_name]
        item_data.amount = 1

        local item = CreateItem(item_data)
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

function sItemGenerator:GetItemAmount(item, tier)

    return math.random(item.min, item.max)

end

function sItemGenerator:FindTargetItem(target, tier, group)

    local sum = 0

    for item_name, item_data in pairs(LootItems[tier][group].items) do

        sum = sum + item_data.rarity

        if target <= sum then
            return item_name
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

    error(debug.traceback("No group name found in sItemGenerator:FindGroupName! Did you make the rarities absolute?"))

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