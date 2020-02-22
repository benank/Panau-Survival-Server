class 'sItemGenerator'

function sItemGenerator:__init()

    self.computed_rarity_sums = {}

    self:ComputeRaritySums()

    -- Test command for generating loot
    Console:Subscribe("loot", function()
    
        local tier = math.random(4)

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

    -- Always have lockpicks in there
    --[[local item = CreateItem({name = "Lockpick", amount = self:GetRandomNumberOfLockpicks(tier)})
    local stack = shStack({contents = {item}})
    table.insert(contents, stack)]]

    local num_items = math.ceil(Lootbox.GeneratorConfig.box[tier].min_items + 
        math.random() * (Lootbox.GeneratorConfig.box[tier].max_items - Lootbox.GeneratorConfig.box[tier].min_items))

    for i = 1, num_items do
        table.insert(contents, self:GetStack(tier))
    end

    return contents

end

function sItemGenerator:GetRandomNumberOfLockpicks(tier)
    return math.random(Lootbox.GeneratorConfig.box[tier].min_lockpicks, Lootbox.GeneratorConfig.box[tier].max_lockpicks)
end

function sItemGenerator:GetStack(tier)

    if tier < Lootbox.Types.Level1 or tier > Lootbox.Types.Level5 then
        error("sItemGenerator:GetItem failed: invalid tier specified")
    end

    local target = self.computed_rarity_sums[tier] * math.random()
    
    local item_data = self:FindTargetItem(target, tier)
    item_data.amount = 1

    if item_data then

        local item = CreateItem(item_data)
        
        local stack = shStack({contents = {item}})
        
        local amount = self:GetItemAmount(item, item_data.max_loot)

        -- Add items to stack like this so it handles all the dirty work for us
        for i = 1, amount - 1 do

            stack:AddItem(CreateItem(item_data))

        end

        return stack

    else
        -- I don't really know why it wouldn't find an item, but hey try again if it happens
        return sItemGenerator:GetStack(tier)

    end

end

function sItemGenerator:GetItemAmount(item, max_loot)

    -- Get random amount
    local amount = math.ceil(item.stacklimit * 
        (math.random() * (Lootbox.GeneratorConfig.stack.max_percent - Lootbox.GeneratorConfig.stack.min_percent)
        + Lootbox.GeneratorConfig.stack.min_percent)
        )

    -- Clamp it
    amount = math.clamp(
        amount, 
        Lootbox.GeneratorConfig.stack.min,
        math.min(math.random(Lootbox.GeneratorConfig.stack.max), max_loot or 999))

        -- TODO: use self:GetRandomNumberOfLockpicks(tier) for lootboxes

    return amount

end

function sItemGenerator:FindTargetItem(target, tier)

    local sum = 0

    -- TODO: optimize this with weighted tables

    for _, item in pairs(Items_indexed) do

        for index, _tier in pairs(item.loot) do

            if tier == _tier then

                sum = sum + item.rarity * item.rarity_mod[index]

                if target <= sum then
                    return item
                end

            end

        end

    end

end

function sItemGenerator:ComputeRaritySums()

    for _, item in pairs(Items_indexed) do

        for index, tier in pairs(item.loot) do

            if not self.computed_rarity_sums[tier] then
                self.computed_rarity_sums[tier] = 0
            end

            -- Sum up all the rarities per tier
            self.computed_rarity_sums[tier] = self.computed_rarity_sums[tier] + 
                item.rarity * item.rarity_mod[index] 

        end

    end


end

ItemGenerator = sItemGenerator()