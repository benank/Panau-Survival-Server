Network:Subscribe("Inventory/LocalizedItems", function(args)
    LocalizedItemNames[args.locale] = args.entries
    ClientInventory.ui:CreateWindow()
    ClientInventory.ui:RefreshInventoryDisplay()
end)