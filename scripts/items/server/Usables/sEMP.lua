class 'sEMP'

function sEMP:__init()

    self.helis = 
    {
        [3] = true,
        [14] = true,
        [37] = true,
        [57] = true,
        [62] = true,
        [64] = true,
        [65] = true,
        [67] = true
    }

    for v in Server:GetVehicles() do
        v:SetNetworkValue("DisabledByEMP", false)
    end
    
    Network:Subscribe("items/CompleteItemUsage", self, self.UseItem)

end

function sEMP:Activate(position, range, disable_time)

    local affected_vehicles = {}

    for v in Server:GetVehicles() do

        if v:GetPosition():Distance(position) < range then
            v:SetNetworkValue("DisabledByEMP", true)
            v:SetValue("EMPDisableTime", Server:GetElapsedSeconds())
            v:SetHealth(v:GetHealth() - 0.1)
            table.insert(affected_vehicles, v)

            if self.helis[v:GetModelId()] then
                v:SetLinearVelocity(v:GetLinearVelocity() + Vector3(0, -40, 0))
                v:SetAngularVelocity(Vector3(15, 15, 15))
            end
        end

    end

    Timer.SetTimeout(disable_time * 1000 + 500, function()
        local seconds = Server:GetElapsedSeconds()

        for _, v in pairs(affected_vehicles) do
            if IsValid(v) and seconds - v:GetValue("EMPDisableTime") >= disable_time then
                v:SetNetworkValue("DisabledByEMP", false)
                v:SetValue("EMPDisableTime", nil)
            end
        end
    end)

end

function sEMP:UseItem(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and player_iu.item.name == "EMP" then

        Network:Broadcast("items/ActivateEMP", {
            position = player:GetPosition()
        })

        local range = ItemsConfig.usables[player_iu.item.name].range
        local disable_time = ItemsConfig.usables[player_iu.item.name].disable_time

        -- TODO: add perk bonuses

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        self:Activate(player:GetPosition(), range, disable_time)

    end
    
end

sEMP = sEMP()