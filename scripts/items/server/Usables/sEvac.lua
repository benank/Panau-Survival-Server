class 'sEvac'

function sEvac:__init()

    Network:Subscribe("items/CompleteItemUsage", self, self.UseItem)

end

function sEvac:UseItem(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "EVAC" then

        if not args.waypoint or args.waypoint:Distance(Vector3(0,0,0)) < 1 or not args.waypoint_set then
            Chat:Send(player, "You must set a waypoint first before using this item!", Color.Red)
            return
        end

        
        local num_grapples = Inventory.GetNumOfItem({player = player, item_name = "Grapplehook"}) + 
            Inventory.GetNumOfItem({player = player, item_name = "RocketGrapple"})

        if num_grapples == 0 then
            Chat:Send(player, "You must have a grapplehook to use this item!", Color.Red)
            return
        end

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        local target_pos = Vector3(
            math.clamp(args.waypoint.x, -16384, 16384),
            math.min(3000, args.waypoint.y),
            math.clamp(args.waypoint.z, -16384, 16384)
        )

        Network:Broadcast("items/ActivateEvac", {
            start_position = player:GetPosition() + Vector3(0, 7, 0),
            end_position = target_pos + Vector3(0, 12, 0)
        })

        Chat:Send(player, "EVAC called. Grapple onto the side when it arrives.", Color.Yellow)

    end
    
end

sEvac = sEvac()