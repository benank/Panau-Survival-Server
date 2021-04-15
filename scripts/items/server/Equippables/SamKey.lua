Events:Subscribe("Inventory/ToggleEquipped", function(args)

    if not args.item or not IsValid(args.player) then return end
    if args.item.name ~= "SAM Key" then return end
    if not ItemsConfig.equippables[args.item.name] then return end

    args.player:SetNetworkValue("SAM Key", args.item.equipped == true and tonumber(args.item.custom_data.level) or 0)
end)

Events:Subscribe("ClientModuleLoad", function(args)
    args.player:SetNetworkValue("SAM Key", 0)
end)