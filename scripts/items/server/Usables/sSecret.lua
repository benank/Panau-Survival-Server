class 'sSecret'

function sSecret:__init()
    self.active_secrets = {}
    
    self.tier_radius = 
    {
        [21] = 2000,
        [22] = 2500
    }
    
    Network:Subscribe("items/CompleteItemUsage", self, self.UseItem)
    Events:Subscribe("Inventory/LockboxSpawned", self, self.LockboxSpawned)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerOpenLootbox", self, self.PlayerOpenLootbox)

end

function sSecret:PlayerOpenLootbox(args)
    if args.tier ~= 21 and args.tier ~= 22 then return end
    
    self.active_secrets[args.uid] = nil
    
    Network:Broadcast("items/RemoveSecret", {uid = args.uid})
end

function sSecret:ClientModuleLoad(args)
    Network:Send(args.player, "items/SyncSecrets", self.active_secrets) 
end

function sSecret:GetApproximatePosition(position, tier)
    local dir = Vector3(math.random() - 0.5, 0, math.random() - 0.5):Normalized()
    local distance = self.tier_radius[tier] * math.random()
    return position + dir * distance
end

function sSecret:LockboxSpawned(args)
    local approx_position = self:GetApproximatePosition(args.position, args.tier)
    
    self.active_secrets[args.uid] = 
    {
        uid = args.uid,
        tier = args.tier,
        position = approx_position,
        radius = self.tier_radius[args.tier],
        -- exact_position = args.position
    }
    
    Network:Broadcast("items/NewSecret", self.active_secrets[args.uid])
end

function sSecret:UseItem(args, player)
    
    local player_iu = player:GetValue("ItemUse")
    if player_iu.item and ItemsConfig.usables[player_iu.item.name] and player_iu.using and player_iu.completed and
       player_iu.item.name == "Secret" then
        self:ActivateSecret(player_iu, player)
        
        Inventory.RemoveItem({
            item = player_iu.item,
            index = player_iu.index,
            player = player
        })
    end 
end

function sSecret:ActivateSecret(player_iu, player)
    Events:Fire("items/CreateSecretLockbox", {
        player = player,
        x = tonumber(player_iu.item.custom_data.secret_x) == 1
    })
    Chat:Send(player, "Secret uploaded to map. This area is visible to all players.", Color.Yellow)
end

sSecret = sSecret()