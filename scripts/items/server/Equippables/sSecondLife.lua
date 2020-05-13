Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "Second Life" then return end

    args.player:SetValue("SecondLifeEquipped", args.item.equipped == true)

end)