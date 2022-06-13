function RefreshInventory()
    if not ClientInventory.ui then
        Thread(function()
            Timer.Sleep(5000)
            RefreshInventory()
        end)
        return
    end
    
    ClientInventory.ui:CreateWindow()
    ClientInventory.ui:RefreshInventoryDisplay()
end

Network:Subscribe("Inventory/LocalizedItems", function(args)
    LocalizedItemNames[args.locale] = args.entries
    RefreshInventory()
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