-- Returns a table with start_index and end_index so you can loop through lol
function GetCategoryInfo(cat, player)

    if not cat or not IsValid(player) then return end

    local data = {start_index = 1, end_index = 0}

    local slots = 0

    local inventory = Inventory.Get({player = player})

    for k,v in pairs(Inventory.config.categories) do

        data.end_index = data.end_index + v.slots

        if v.name == cat then return data end

        data.start_index = data.start_index + v.slots

    end

end
