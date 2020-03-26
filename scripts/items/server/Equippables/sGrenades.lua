class "Grenades"

function Grenades:__init()

    for player in Server:GetPlayers() do
        player:SetNetworkValue("ThrowingGrenade", nil)
        player:SetNetworkValue("EquippedGrenade", nil)
    end

    Network:Subscribe("items/GrenadeTossed", self, self.GrenadeTossed)
    Network:Subscribe("items/StartThrowingGrenade", self, self.StartThrowingGrenade)
    Network:Subscribe("items/GrenadeExploded", self, self.GrenadeExploded)
    
    Events:Subscribe("Inventory/ToggleEquipped", self, self.ToggleEquipped)
end

function Grenades:GrenadeExploded(args, player)
    if args.position and args.radius < 100 then
        Events:Fire("items/ItemExplode", {
            position = args.position,
            radius = args.radius,
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
    args.player:SetNetworkValue("ThrowingGrenade", nil)

end

function Grenades:GrenadeTossed(args, sender)
    if sender:InVehicle() then return end
    sender:SetNetworkValue("ThrowingGrenade", nil)
    if not sender:GetValue("EquippedGrenade") then return end
	Network:SendNearby(sender, "items/GrenadeTossed", {
        position = args.position,
        velocity = args.velocity,
        type = sender:GetValue("EquippedGrenade"),
        fusetime = math.max(0, args.fusetime)
    })
end

grenades = Grenades()