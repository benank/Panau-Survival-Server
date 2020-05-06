class 'sEvac'

function sEvac:__init()

    Network:Subscribe("items/CompleteItemUsage", self, self.UseItem)

end

function sEvac:UseItem(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "EVAC" then

        if not args.waypoint or args.waypoint:Distance(Vector3(0,0,0)) < 1 then
            Chat:Send(player, "You must set a waypoint first before using this item!", Color.Red)
            return
        end

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        Network:Broadcast("items/ActivateEvac", {
            start_position = player:GetPosition() + Vector3(0, 7, 0),
            end_position = args.waypoint + Vector3(0, 12, 0)
        })

    end
    
end

sEvac = sEvac()