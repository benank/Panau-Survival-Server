class 'sHacker'

function sHacker:__init()

    self.difficulties = 
    {
        [13] = 3, -- Locked stash
        [14] = 2 -- Prox alarm
    }

    Network:Subscribe("items/CompleteItemUsage", self, self.UseItem)

    Network:Subscribe("items/HackComplete", self, self.HackComplete)
    Network:Subscribe("items/FailHack", self, self.FailHack)

end

function sHacker:FailHack(args, player)

    if not player:GetValue("CurrentlyHacking") then return end
    if not player:GetValue("CurrentLootbox") then return end

    player:SetValue("CurrentlyHacking", false)

    Inventory.OperationBlock({player = player, change = -1})
end

function sHacker:HackComplete(args, player)

    if not player:GetValue("CurrentlyHacking") then return end
    if not player:GetValue("CurrentLootbox") then return end

    Events:Fire("items/HackComplete", {
        player = player,
        stash_id = player:GetValue("CurrentLootbox").stash.id,
        tier = player:GetValue("CurrentLootbox").tier
    })

    player:SetValue("CurrentlyHacking", true)

    Chat:Send(player, "Hack successful!", Color.Yellow)

    Inventory.OperationBlock({player = player, change = -1})
end

function sHacker:UseItem(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and (player_iu.item.name == "Hacker" or player_iu.item.name == "Master Hacker") and not player:GetValue("CurrentlyHacking") then

        local current_box = player:GetValue("CurrentLootbox")
        if not current_box or not current_box.locked then
            Chat:Send(player, "You must open a hackable object first!", Color.Red)
            return
        end

        if not current_box.tier or not self.difficulties[current_box.tier] then
            Chat:Send(player, "This object cannot be hacked.", Color.Red)
            return
        end

        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })

        Inventory.OperationBlock({player = player, change = 1})
        player:SetValue("CurrentlyHacking", true)

        local send_data = {difficulty = self.difficulties[current_box.tier]}

        if player_iu.item.name == "Master Hacker" then
            send_data.time = 20 -- Double time for Master Hacker
        end

        Network:Send(player, "items/StartHack", send_data)

    end
    
end

sHacker = sHacker()