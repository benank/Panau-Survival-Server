class "Grenades"

function Grenades:__init()
	Network:Subscribe("GrenadeTossed", self, self.GrenadeTossed)
    Network:Subscribe("GrenadeExplode", self, self.GrenadeExplode)
    
    Events:Subscribe("Inventory/ToggleEquipped", self, self.ToggleEquipped)
end

function Grenades:ToggleEquipped(args)

    if not args.item or not IsValid(args.player) then return end
    if not ItemsConfig.equippables.grenades[args.item.name] then return end

    Network:Send(args.player, "items/ToggleEquippedGrenade", {
        name = args.item.name,
        equipped = args.item.equipped == true
    })
    args.player:SetNetworkValue("EquippedGrenade", args.item.name)

end

function Grenades:GrenadeTossed(args, sender)
	Network:SendNearby(sender, "items/GrenadeTossed", args)
end

function Grenades:GrenadeExplode(args, sender)
	if sender:GetPosition():Distance(args.position) < args.type.radius then
		local falloff = (args.type.radius - sender:GetPosition():Distance(args.position)) / (args.type.radius * 0.6)

		sender:SetHealth(sender:GetHealth() - falloff)
		
		if sender:InVehicle() then
			sender:GetVehicle():SetHealth(sender:GetVehicle():GetHealth() - falloff)
			sender:GetVehicle():SetLinearVelocity(sender:GetVehicle():GetLinearVelocity() + ((sender:GetVehicle():GetPosition() - args.position):Normalized() * args.type.radius * 2 * falloff))
		end
	end
end

grenades = Grenades()