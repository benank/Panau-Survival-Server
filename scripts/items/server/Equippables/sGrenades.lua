class "Grenades"

function Grenades:__init()

    for player in Server:GetPlayers() do
        player:SetNetworkValue("ThrowingGrenade", nil)
        player:SetNetworkValue("EquippedGrenade", nil)
    end

    Network:Subscribe("items/GrenadeTossed", self, self.GrenadeTossed)
    Network:Subscribe("items/StartThrowingGrenade", self, self.StartThrowingGrenade)
    Network:Subscribe("items/GrenadeExploded", self, self.GrenadeExploded)
    Network:Subscribe("items/PlayerInsideToxicGrenadeArea", self, self.PlayerInsideToxicGrenadeArea)
    Network:Subscribe("items/PlayerInsideFireGrenadeArea", self, self.PlayerInsideFireGrenadeArea)
    Network:Subscribe("items/SnowballHit", self, self.SnowballHit)
    
    Events:Subscribe("items/CreateGrenade", self, self.CreateGrenadeExternal)
    Events:Subscribe("drones/CreateGrenade", self, self.CreateGrenadeDrone)
    
    Events:Subscribe("Inventory/ToggleEquipped", self, self.ToggleEquipped)
end

function Grenades:CreateGrenadeExternal(args)
	Network:Broadcast("items/GrenadeTossed", {
        position = args.position,
        velocity = args.velocity,
        type = args.grenade_type,
        fusetime = args.fusetime,
        owner_id = args.owner_id or "???"
    })
end

function Grenades:CreateGrenadeDrone(args)
    
    local grenade_types = {"HE Grenade", "Flashbang", "Toxic Grenade"}
    local grenade_type = grenade_types[math.floor(math.random(#grenade_types))]

	Network:Broadcast("items/GrenadeTossed", {
        position = args.drone_position,
        velocity = (args.position - args.drone_position):Normalized() * args.distance,
        type = grenade_type,
        fusetime = math.random() * 3 + 2,
        owner_id = "Drone"
    })
end

function Grenades:PlayerInsideFireGrenadeArea(args, player)
    if player:GetValue("InSafezone") then return end
    player:SetNetworkValue("OnFire", true)
    player:SetNetworkValue("OnFireTime", Server:GetElapsedSeconds())

    player:SetNetworkValue("FireAttackerId", args.attacker_id)
end

function Grenades:PlayerInsideToxicGrenadeArea(args, player)
    if player:GetValue("InSafezone") then return end
    
    Events:Fire("HitDetection/PlayerInToxicArea", {
        player = player,
        attacker_id = args.attacker_id,
        type = "Toxic Grenade"
    })
end

function Grenades:SnowballHit(args, player)
    if not IsValid(args.player) then return end
    Events:Fire("HitDetection/SnowballHit", 
    {
        attacker = player,
        player = args.player
    })
end

function Grenades:GrenadeExploded(args, player)
    if args.position and args.radius < 100 and args.type ~= "Molotov" then
        Events:Fire("items/ItemExplode", {
            position = args.position,
            radius = args.radius,
            type = args.type,
            player = player
        })
    end

    if args.type == "Warp Grenade" then
        Network:Send(player, "items/WarpEffect", {position = player:GetPosition()})
        Network:SendNearby(player, "items/WarpEffect", {position = player:GetPosition()})
        player:SetPosition(args.position)
        Events:Fire("HitDetection/WarpGrenade", {
            player = player
        })
    end
end

function Grenades:StartThrowingGrenade(args, player)
    player:SetNetworkValue("ThrowingGrenade", true)
end

function Grenades:ToggleEquipped(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.grenades[args.item.name] then return end

    Network:Send(args.player, "items/ToggleEquippedGrenade", {
        name = args.item.name,
        equipped = args.item.equipped == true
    })

    args.player:SetNetworkValue("EquippedGrenade", args.item.name)
    args.player:SetValue("EquippedGrenadeData", args)
    args.player:SetNetworkValue("ThrowingGrenade", nil)

end

function Grenades:GrenadeTossed(args, sender)
    if sender:InVehicle() then return end
    sender:SetNetworkValue("ThrowingGrenade", nil)
    if not sender:GetValue("EquippedGrenade") then return end
    if sender:GetHealth() <= 0 then return end

    local item_data = sender:GetValue("EquippedGrenadeData")
    if not item_data then return end

    local inv = Inventory.Get({player = sender})
    if not inv then return end

    local stack = inv[item_data.item.category][item_data.index]

    local stack_index = -1

    for index, stack in pairs(inv[item_data.item.category]) do
        for _, item in pairs(stack.contents) do
            if item.uid == item_data.item.uid then
                stack_index = index
                break
            end
        end
    end

    Inventory.RemoveItem({
        item = item_data.item,
        index = stack_index,
        player = sender
    })

    inv = Inventory.Get({player = sender}) -- Refresh inventory

    -- If there is another grenade in the stack, equip it
    local stack = inv[item_data.item.category][stack_index]
    if stack and stack:GetProperty("name") == item_data.item.name then
        Inventory.SetItemEquipped({
            player = sender,
            item = stack.contents[1]:GetSyncObject(),
            index = stack_index,
            equipped = true
        })
    end

	Network:SendNearby(sender, "items/GrenadeTossed", {
        position = args.position,
        velocity = args.velocity,
        type = sender:GetValue("EquippedGrenade"),
        fusetime = math.max(0, args.fusetime),
        owner_id = tostring(sender:GetSteamId())
    })
end

grenades = Grenades()