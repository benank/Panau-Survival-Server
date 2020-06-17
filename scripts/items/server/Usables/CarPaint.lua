-- Color rarity table
local cLookup = {
    ["Red"] = Color(255,0,0),
    ["Green"] = Color(0,255,0),
    ["Blue"] = Color(0,0,255),
    ["Purple"] = Color(128,0,255),
    ["Pink"] = Color(255,0,255),
    ["Nyan"] = Color(0,191,255),
    ["Lime"] = Color(128,255,0),
    ["Orange"] = Color(255,64,0),
    ["Yellow"] = Color(255,255,0),
    ["White"] = Color(255,255,255),
    ["Black"] = Color(0,0,0),
    ["Brown"] = Color(94,66,27),
    ["DarkGreen"] = Color(38,71,14),
}

Network:Subscribe("items/CompleteItemUsage", function(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed and 
    player_iu.item.name == "Car Paint" then

        local entity = args.forward_ray.entity

        if not IsValid(entity) or entity.__type ~= "Vehicle" then
            Chat:Send(player, "You must aim at a vehicle to use this item!", Color.Red)
            return
        end

        if player:GetPosition():Distance(args.forward_ray.position) > ItemsConfig.usables[player_iu.item.name].range then
            Chat:Send(player, "You must move closer to the vehicle to use this item!", Color.Red)
            return
        end

        if not cLookup[player_iu.item.custom_data.color] then
            print("**Custom color for car paint not found!** " .. player_iu.item.custom_data.color)
            return
        end

		entity:SetColors(cLookup[player_iu.item.custom_data.color], cLookup[player_iu.item.custom_data.color])

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

    end

end)