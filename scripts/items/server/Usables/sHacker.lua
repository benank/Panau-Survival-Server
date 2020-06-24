class 'sHacker'

function sHacker:__init()

    self.difficulties = 
    {
        [13] = 3, -- Locked stash
        [14] = 2 -- Prox alarm
    }

    self.perks = 
    {
        [102] = {[1] = 1, [2] = 0.1},
        [169] = {[1] = 1, [2] = 0.1},
        [205] = {[1] = 1, [2] = 0.1},
    }

    Network:Subscribe("items/CompleteItemUsage", self, self.UseItem)

    Network:Subscribe("items/HackComplete", self, self.HackComplete)
    Network:Subscribe("items/FailHack", self, self.FailHack)

end

function sHacker:GetPerkMods(player)

    local perks = player:GetValue("Perks")

    if not perks then return end

    local perk_mods = {[1] = 0, [2] = 0}

    for perk_id, perk_mod_data in pairs(self.perks) do
        local choice = perks.unlocked_perks[perk_id]
        if choice and perk_mod_data[choice] then
            perk_mods[choice] = perk_mods[choice] + perk_mod_data[choice]
        end
    end

    return perk_mods

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

    player:SetValue("CurrentlyHacking", false)

    Chat:Send(player, "Hack successful!", Color.Yellow)

    Inventory.OperationBlock({player = player, change = -1})
end

local hackable_tiers = 
{
    [13] = true, -- Locked stash
    [14] = true -- Prox alarm
}

function sHacker:UseItem(args, player)

    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed
        and (player_iu.item.name == "Hacker" or player_iu.item.name == "Master Hacker") and not player:GetValue("CurrentlyHacking") then

        local current_box = player:GetValue("CurrentLootbox")
        if not current_box or (not current_box.locked and not hackable_tiers[current_box.tier])
        or current_box.stash.access_mode == 1
        or current_box.stash.owner_id == tostring(player:GetSteamId())
        or AreFriends(player, current_box.stash.owner_id) then
            Chat:Send(player, "You must open a hackable object first!", Color.Red)
            return
        end

        if not current_box.tier or not self.difficulties[current_box.tier] then
            Chat:Send(player, "This object cannot be hacked.", Color.Red)
            return
        end

        local perk_mods = self:GetPerkMods(player)

        local chance_to_keep = math.random()

        if chance_to_keep <= perk_mods[2] then
            Chat:Send(player, "Your Hacker was kept after using it, thanks to your perks!", Color(0, 220, 0))
        else

            Inventory.RemoveItem({
                item = player_iu.item,
                index = player_iu.index,
                player = player
            })

        end

        Inventory.OperationBlock({player = player, change = 1})
        player:SetValue("CurrentlyHacking", true)

        local send_data = {difficulty = self.difficulties[current_box.tier]}

        if player_iu.item.name == "Master Hacker" then
            send_data.time = 20 -- Double time for Master Hacker
        else
            send_data.time = 10
        end

        send_data.time = send_data.time + perk_mods[1]

        Network:Send(player, "items/StartHack", send_data)

    end
    
end

sHacker = sHacker()