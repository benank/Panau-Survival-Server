-- Serializes a table representing an inventory or stash contents into a string
function Serialize(contents_data, has_categories)

    local str = '';

    local function ProcessContents(contents)

        for i, stack in ipairs(contents) do
            for j = 1, #stack.contents do
            
                local item = stack.contents[j]
                str = str .. tostring(i) .. "=" .. item.name .. "=" .. tostring(item.amount)

                str = (item.equipped) and str .. "=E" or str
                str = (item.durability and item.durability > 0) and str .. "=D" .. tostring(item.durability) or str

                -- If this item has at least 1 custom data
                for k,v in pairs(item.custom_data) do
                
                    str = str .. "=N" .. tostring(k) .. ">" .. tostring(v)

                end

                str = str .. "~";

            end

            str = str .. "|";

        end

    end

    if has_categories then
        for cat_name, _ in pairs(contents_data) do
            ProcessContents(contents_data[cat_name])
        end
    else
        ProcessContents(contents_data)
    end

    return str;

end

-- Deserializes a string representing an inventory or stash contents
function Deserialize(data, has_categories)
    
    data = tostring(data)

    local split = splitstr2(data, "|")
    local contents = {}

    if has_categories then
        for _, cat_data in pairs(Inventory.config.categories) do
            contents[cat_data.name] = {}
        end
    end

    for i = 1, #split - 1 do -- Each stack
    
        local valid_item = true
        local split2 = splitstr2(split[i], "~")
        local stack = nil
        local index = 0

        for j = 1, #split2 - 1 do -- Each item within the stack
        
            local split3 = splitstr2(split2[j], "=")
            local item_data = {}
            item_data.custom_data = {}

            for k = 1, #split3 do -- Each property within the item

                if (k == 1) then -- Index
                
                    index = tonumber(split3[k])
                
                elseif (k == 2) then -- Name
                
                    item_data.name = split3[k]

                    if not CreateItem({name = item_data.name, amount = 1}) then -- Unable to find item, eg does not exist
                        print("Unable to find item with name " .. tostring(split3[k]) .. " in sInventory:Deserialize")
                        valid_item = false
                    end
                
                elseif (k == 3) then -- Amount
                
                    item_data.amount = tonumber(split3[k])
                
                elseif (split3[k]:sub(1, 1) == "E" and k > 3) then -- Equipped
                
                    item_data.equipped = true
                
                elseif (split3[k]:sub(1, 1) == "D" and k > 3) then -- Durability
                
                    item_data.durability = tonumber(splitstr(split3[k], "D")[1])
                
                elseif (split3[k]:sub(1, 1) == "N" and k > 3) then -- Custom property/data
                
                    local replaced = split3[k]:sub(2, split3[k]:len())
                    local replaced_split = splitstr(replaced, ">")
                    if replaced_split[1] and replaced_split[2] then
                        item_data.custom_data[replaced_split[1]] = replaced_split[2]
                    end
                end
                
            end

            if valid_item then
                local item = CreateItem(item_data) -- Create item

                if (not stack) then -- If this is the first item, create the stack
                
                    stack = shStack({contents = {item}});
                
                else -- Otherwise, add it to the front of the stack
                
                    stack:AddItem(item);

                end
            end

            
        end

        if valid_item then
            if index > 0 and has_categories then
                contents[stack:GetProperty("category")][index] = stack
            elseif index > 0 and not has_categories then
                contents[index] = stack
            end
        end


    end

    return contents

end

function splitstr2(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end