class 'sItemGenerator'

function sItemGenerator:__init()

    self.computed_rarity_sums = {}

    self:ComputeRaritySums()

    -- Test command for generating loot
    Console:Subscribe("loot", function()
    
        local tier = 4

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

    for i = 1, num_items do
        table.insert(contents, self:GetStack(tier))
    end

    return contents

end

function sItemGenerator:GetStack(tier)

    if not Lootbox.GeneratorConfig.spawnable[tier] then
        error("sItemGenerator:GetItem failed: invalid tier specified")
    end

    local target = self.computed_rarity_sums[tier] * math.random()

    local item_name = self:FindTargetItem(target, tier)

    if item_name then

        local item_data = Items_indexed[item_name]
        item_data.amount = 1

        local item = CreateItem(item_data)
        local stack = shStack({contents = {item}})
        local amount = self:GetItemAmount(item.name, tier)

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

    return math.random(LootItems[tier][item].min, LootItems[tier][item].max)

end

function sItemGenerator:FindTargetItem(target, tier)

    local sum = 0

    for item_name, item_data in pairs(LootItems[tier]) do

        sum = sum + item_data.rarity

        if target <= sum then
            return item_name
        end

    end

end

function sItemGenerator:ComputeRaritySums()

    for tier, tier_data in pairs(LootItems) do

        for _, item_data in pairs(tier_data) do

            if not self.computed_rarity_sums[tier] then
                self.computed_rarity_sums[tier] = 0
            end

            -- Sum up all the rarities per tier
            self.computed_rarity_sums[tier] = self.computed_rarity_sums[tier] + item_data.rarity

        end

    end

end

ItemGenerator = sItemGenerator()