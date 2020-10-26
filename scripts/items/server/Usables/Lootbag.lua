local lootbag_config = 
{
    ["Halloween Lootbag"] = 
    {
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
        ["Candy Corn"] =       {amount = 6, chance = 0.2},
        ["Marshmallow"] =      {amount = 3, chance = 0.1},
        ["Kit Kat"] =          {amount = 2, chance = 0.1},
        ["Starburst"] =        {amount = 4, chance = 0.1},
        ["Skittles"] =         {amount = 8, chance = 0.2}
    }
}

Events:Subscribe("PlayerJoin", function(args)
    Chat:Send(args.player, "The Halloween Event is live! Find exclusive ", Color.Orange, "Halloween Lootbags", Color.Red, " in loot from now until Nov 2. Open lootbags to find candy and costumes!", Color.Orange)
end)

Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and ItemsConfig.usables[player_iu.item.name] then
            
        if not lootbag_config[player_iu.item.name] then return end

        local item_name = GetRandomItem(player_iu.item.name)
        local item_amount = lootbag_config[player_iu.item.name][item_name].amount

        local item = CreateItem({
            name = item_name,
            amount = item_amount
        })

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        Inventory.AddItem({
            item = item:GetSyncObject(),
            player = player
        })

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