local lootbag_config = 
{
    ["Halloween Lootbag"] = 
    {
        ["Stick Disguise"] =     {amount = 1, chance = 0.001},
        ["Palm Costume"] =     {amount = 1, chance = 0.01},
        ["Umbrella Costume"] =     {amount = 1, chance = 0.01},
        ["Plant Costume"] =    {amount = 1, chance = 0.01},
        ["Heli Costume"] =     {amount = 1, chance = 0.01},
        ["Car Costume"] =      {amount = 1, chance = 0.01},
        ["Boat Costume"] =     {amount = 1, chance = 0.02},
        ["Wall Costume"] =     {amount = 1, chance = 0.02},
        ["Stash Costume"] =    {amount = 1, chance = 0.02},
        ["Halo Hat"] =     {amount = 1, chance = 0.05},
        ["Meathead Hat"] = {amount = 1, chance = 0.05},
        ["Sun Costume"] =      {amount = 1, chance = 0.04},
        ["Cone Hat"] =     {amount = 1, chance = 0.05},
        ["Candy Corn"] =       {amount = 6, chance = 0.199},
        ["Marshmallow"] =      {amount = 3, chance = 0.1},
        ["Kit Kat"] =          {amount = 2, chance = 0.1},
        ["Starburst"] =        {amount = 4, chance = 0.1},
        ["Skittles"] =         {amount = 8, chance = 0.2}
    },
    ["Holiday Lootbag"] = 
    {
        ["Snowman Outfit"] =     {amount = 1, chance = 0.05},
        ["Snowball"] =          {amount = 10, chance = 0.4},
        ["Sugarcookie"] =    {amount = 5, chance = 0.1},
        ["Milk"] =              {amount = 3, chance = 0.1},
        ["Candy Cane"] =      {amount = 12, chance = 0.2},
        ["Hot Chocolate"] =     {amount = 1, chance = 0.1},
        ["Christmas Tree"] =     {amount = 1, chance = 0.05}
    },
    ["Two Year Lootbag"] = 
    {
        ["Two Year Party Hat"] =     {amount = 1, chance = 1},
    },
    ["Three Year Lootbag"] = 
    {
        ["Three Year Party Hat"] =     {amount = 1, chance = 1},
    }
}

Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and ItemsConfig.usables[player_iu.item.name] then
            
        if not lootbag_config[player_iu.item.name] then return end

        local item_name = GetRandomItem(player_iu.item.name)
        local item_amount = lootbag_config[player_iu.item.name][item_name].amount

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        for i = 1, item_amount do
            local item = CreateItem({
                name = item_name,
                amount = 1
            })

            Inventory.AddItem({
                item = item:GetSyncObject(),
                player = player
            })
        end

        Chat:Send(player, string.format("Opened %s and got: %s!", player_iu.item.name, item_name), Color.Orange)

    end

end)

function GetRandomItem(lootbag_type)

    local chance = math.random()
    local total = 0

    for item_name, data in pairs(lootbag_config[lootbag_type]) do
        total = total + data.chance
        if chance <= total then return item_name end
    end

end