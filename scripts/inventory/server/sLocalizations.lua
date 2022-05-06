local players_awaiting_translation = {}
local locales_awaiting_translation = {}
local total_inv_entries = count_table(LocalizedItemNames['en'])

Events:Subscribe("Translation", function(args)

    local split = args.id:split("-")
    local tag = split[1]
    if tag ~= "inv" then return end
    
    local item_name = args.translations['en']
    args.translations['en'] = nil
    
    for locale, text in pairs(args.translations) do
        if not LocalizedItemNames[locale] then
            LocalizedItemNames[locale] = {}
        end
        
        LocalizedItemNames[locale][item_name] = text
        
        -- print(string.format("%d/%d [%s]", count_table(LocalizedItemNames[locale]), total_inv_entries, locale))
        
        if count_table(LocalizedItemNames[locale]) == total_inv_entries then
            locales_awaiting_translation[locale] = nil
            
            for _, player in pairs(players_awaiting_translation[locale] or {}) do
                if IsValid(player) then
                    Network:Send(player, "Inventory/LocalizedItems", {
                        entries = LocalizedItemNames[locale],
                        locale = locale
                    }) 
                end
            end
            
            players_awaiting_translation[locale] = nil
        end
    end
end)

Events:Subscribe("ClientModuleLoad", function(args)
    Timer.SetTimeout(2000, function()
        UpdateItemEntries(args.player)
    end)
end)

Events:Subscribe("NetworkObjectValueChange", function(args)
    if args.object.__type ~= "Player" then return end
    if args.key ~= "Locale" then return end
    
    local locale = args.value
    local player = Player.GetById(args.object:GetId())
    if not IsValid(player) then return end
    
    Timer.SetTimeout(2000, function()
        UpdateItemEntries(player)
    end)
end)

function UpdateItemEntries(player)
    local locale = player:GetValue("Locale")
    if not locale or locale == 'en' then return end
    
    if LocalizedItemNames[locale] and count_table(LocalizedItemNames[locale]) == total_inv_entries then
        Network:Send(player, "Inventory/LocalizedItems", {entries = LocalizedItemNames[locale], locale = locale})
    else
        local steam_id = tostring(player:GetSteamId())
        if not players_awaiting_translation[locale] then
            players_awaiting_translation[locale] = {}
        end
        
        players_awaiting_translation[locale][steam_id] = player
        
        if locales_awaiting_translation[locale] then return end
        locales_awaiting_translation[locale] = true
        
        Thread(function()
            local index = 1
            for item_name, _ in pairs(Items_indexed) do
                Events:Fire("TranslateText", {
                    text = item_name,
                    id = string.format("inv-%s", index),
                    origin_locale = 'en'
                })
                index = index + 1
                Timer.Sleep(5)
            end
        end)
    end 
end