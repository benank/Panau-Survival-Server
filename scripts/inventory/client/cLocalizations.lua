Network:Subscribe("Inventory/LocalizedItems", function(args)
    LocalizedItemNames[args.locale] = args.entries
    ClientInventory.ui:CreateWindow()
    ClientInventory.ui:RefreshInventoryDisplay()
end)

Events:Subscribe("NetworkObjectValueChange", function(args)
    if args.object.__type ~= "Player" and args.object.__type ~= "LocalPlayer" then return end
    if args.object ~= LocalPlayer then return end
    if args.key ~= "Locale" then return end
    
    local locale = args.value
    if LocalizedItemNames[locale] and ClientInventory and ClientInventory.ui then
        ClientInventory.ui:CreateWindow()
        ClientInventory.ui:RefreshInventoryDisplay()
    end
end)