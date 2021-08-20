class 'sBurstPing'

function sBurstPing:__init()
    
    self.cooldown = 0
    
    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
end

function sBurstPing:ClientModuleLoad(args)
    args.player:SetValue("LastPingTime", Server:GetElapsedSeconds()) 
end

function sBurstPing:UseItem(args)
    
    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= 'Burst Ping' then return end
    
    local last_ping_time = args.player:GetValue("LastPingTime")
    
    if Server:GetElapsedSeconds() - last_ping_time < self.cooldown then
        Chat:Send(args.player, 
            string.format("You must wait %.0f seconds before using this!", self.cooldown - (Server:GetElapsedSeconds() - last_ping_time) + 1), Color.Red)
        return
    end
    
    args.player:SetValue("LastPingTime", Server:GetElapsedSeconds())
    
    local bp_x = args.item.custom_data.bp_x == 1
    
    local attacker_pos = args.player:GetPosition()
    Network:Send(args.player, "items/BurstPingFX", {
        position = attacker_pos,
        effect_id = not bp_x and 342 or 365
    })
    
    Network:SendNearby(args.player, "items/BurstPingFX", {
        position = attacker_pos,
        effect_id = not bp_x and 342 or 365
    })
    
    local item_data = ItemsConfig.usables['Burst Ping']
    for player in Server:GetPlayers() do
        if not player:GetValue("InSafezone") and player ~= args.player and not player:GetValue("Loading") then
            local distance = player:GetPosition():Distance(attacker_pos)
            
            if distance < item_data.range then
                Network:Send(player, "items/BurstPingHit", {
                    position = attacker_pos - Vector3.Up,
                    amount = (1 - distance / item_data.range) * item_data.knockback * (bp_x and 5 or 1)
                })
                
                -- Slight bit of damage to ensure kill attribution
                Events:Fire("HitDetection/BurstPingHit", {
                    player = player,
                    attacker = args.player
                })
            end
        end
    end
    
    Inventory.RemoveItem({
        item = args.item,
        index = args.index,
        player = args.player
    })
 
end

sBurstPing = sBurstPing()