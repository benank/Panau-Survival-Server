local players_awaiting_translation = {}
local locales_awaiting_translation = {}
local total_help_entries = count_table_deep(shHelpEntries['en'])

Events:Subscribe("Translation", function(args)

    local split = args.id:split("-")
    local tag = split[1]
    if tag ~= "help" then return end
    
    local key1 = split[2]
    local key2 = split[3]
    args.translations['en'] = nil
    
    for locale, text in pairs(args.translations) do
        if not shHelpEntries[locale] then
            shHelpEntries[locale] = {}
        end
        
        if not shHelpEntries[locale][key1] then
            shHelpEntries[locale][key1] = {}
        end
        
        shHelpEntries[locale][key1][key2] = text
        
        -- print(string.format("%d/%d [%s]", count_table_deep(shHelpEntries[locale]), total_help_entries, locale))
        
        if count_table_deep(shHelpEntries[locale]) == total_help_entries then
            locales_awaiting_translation[locale] = nil
            
            for _, player in pairs(players_awaiting_translation[locale]) do
                if IsValid(player) then
                    Network:Send(player, "help/LocalizedHelpEntries", {
                        entries = shHelpEntries[locale],
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
        UpdateHelpEntries(args.player)
    end)
end)

Events:Subscribe("NetworkObjectValueChange", function(args)
    if args.object.__type ~= "Player" then return end
    if args.key ~= "Locale" then return end
    
    local locale = args.value
    local player = Player.GetById(args.object:GetId())
    if not IsValid(player) then return end
    
    Timer.SetTimeout(2000, function()
        UpdateHelpEntries(player)
    end)
end)

function UpdateHelpEntries(player)
    local locale = player:GetValue("Locale")
    if not locale or locale == 'en' then return end
    
    if shHelpEntries[locale] and count_table_deep(shHelpEntries[locale]) == total_help_entries then
        Network:Send(player, "help/LocalizedHelpEntries", {entries = shHelpEntries[locale], locale = locale})
    else
        local steam_id = tostring(player:GetSteamId())
        if not players_awaiting_translation[locale] then
            players_awaiting_translation[locale] = {}
        end
        
        players_awaiting_translation[locale][steam_id] = player
        
        if locales_awaiting_translation[locale] then return end
        locales_awaiting_translation[locale] = true
        
        Thread(function()
            for key, text_table in pairs(shHelpEntries['en']) do
                for key2, text in pairs(text_table) do
                    Events:Fire("TranslateText", {
                        text = text,
                        id = string.format("help-%s-%s", key, key2),
                        origin_locale = 'en'
                    })
                    Timer.Sleep(5)
                end
            end
        end)
    end 
end