class 'sSecret'

function sSecret:__init()
    
    self.lockboxes = {}
    self.lockbox_radius = 300
    
    
    
    Network:Subscribe("items/CompleteItemUsage", self, self.CompleteItemUsage)
end

function sSecret:CompleteItemUsage(args, player)
    
    local player_iu = player:GetValue("ItemUse")

    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed and 
    player_iu.item.name == "Secret" then
        if player_iu.item.custom_data.secret_type == "lockbox" then
            self:UseSecretLockbox(player_iu, player)
        end
    end

end

function sSecret:CreateSecretLootbox()
    
end

function sSecret:UseSecretLockbox(player_iu, player)
    
    local steam_id = tostring(player:GetSteamId())
    if not self.player_lockboxes[steam_id] then
        self.player_lockboxes[steam_id] = {}
    end
    
    -- Create a secret lockbox, then add it to the player's map
    local sub
    sub = Events:Subscribe("Inventory/SpawnSecretLockbox_" .. steam_id, function(args)
        local direction = Vector3(math.random() - 0.5, 0, math.random() - 0.5):Normalized()
        local nearby_pos = args.position + direction * self.lockbox_radius
        
        Network:Send("items/SecretLootboxSync", {
            position = nearby_pos,
            radius = 
        })
    end)
    
    Inventory.RemoveItem({
        item = player_iu.item,
        index = player_iu.index,
        player = player
    })

end

sSecret = sSecret()