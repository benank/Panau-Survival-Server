class 'sWorkBenchCrafting'

function sWorkBenchCrafting:__init()
    
end

function sWorkBenchCrafting:StackMeetsRequirements(stack, req)
    
    local meets_reqs = stack:GetProperty("name") == req.name and
        stack:GetAmount() >= req.amount
    
    if req.min_durability then
        for _, item in pairs(stack.contents) do
            meets_reqs = meets_reqs and 
                item.durability / item.max_durability >= req.min_durability
        end
    end
    
    return meets_reqs
end

function sWorkBenchCrafting:GetCraftingRecipeFromContentsIfExists(contents)
   
    if count_table(contents) == 0 then return end
    
    for _, crafting_recipe in pairs(WorkbenchCraftingRecpies) do
        local contents_matched = {}
        local recipe_matched = {}
        local satisfied_reqs = 0
        local needed_reqs = 3
        
        for stack_index, stack in pairs(contents) do
            local found = false
            for req_index, item_req in pairs(crafting_recipe.recipe) do
                if not contents_matched[stack_index] 
                and not recipe_matched[req_index] 
                and self:StackMeetsRequirements(stack, item_req) then
                    satisfied_reqs = satisfied_reqs + 1
                    recipe_matched[req_index] = true
                    contents_matched[stack_index] = true
                    found = true
                    break
                end
            end
            
            if satisfied_reqs == needed_reqs then break end
            if not found then break end
        end
        
        if count_table(contents_matched) == needed_reqs and satisfied_reqs == needed_reqs then
            return crafting_recipe
        end
    end

end

sWorkBenchCrafting = sWorkBenchCrafting()