class 'NameTags'

local message_id = 0
function GetNewMessageId()
    message_id = message_id + 1
    return "cm_" .. message_id
end

function NameTags:__init()
    
    self.pending_messages = {}

	Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerChat", self, self.Chat)
    
    Events:Subscribe("Translation", self, self.Translation)
    
end

--[[
    Called when we receive a translation from the server.
    
    Comes in the form of:
    {
        [id] = 'cm_323982', -- Chat message id
        [translations] = {
            ['en'] = 'chat message contents',
            ['ru'] = 'chat message contents'
        }
    }

]]
function NameTags:Translation(args)
    local message_args = self.pending_messages[args.id]
    if not message_args then return end
    
    local original_message_args = Copy(message_args)
    
    -- Send individual messages to players
    for p in Server:GetPlayers() do
        local player_locale = p:GetValue("Locale") or 'en'
        local player_translation = args.translations ~= nil and 
            (args.translations[player_locale] or args.translations['en']) or
            nil
        
        -- Use original message if no translation is available
        if not player_translation then
            player_translation = original_message_args.message
        end
        
        if player_translation then
            message_args.message = player_translation
            SendMessageToPlayer(message_args, p)
        end
    end
    
    local string_message = message_args.player_name .. ": " .. (args.translations ~= nil and args.translations['en'] or original_message_args.message)
    if message_args.player_tag then
        string_message = "[" .. message_args.player_tag .. "] " .. string_message
    end
    
    Events:Fire("Discord", {
        channel = "Chat",
        content = string_message
    })
    
    self.pending_messages[args.id] = nil
end

function SendMessageToPlayer(args, player)
    args.message = ": " .. args.message
    args.locale = "[" .. string.upper(args.locale) .. "] "
    
    if args.player_tag then
        args.player_tag = "[" .. args.player_tag .. "] "
        Chat:Send(player, args.locale, args.locale_color, args.player_tag, args.player_tag_color, 
                       args.player_name, args.player_color, args.message, Color.White)
    else
        Chat:Send(player, args.locale, args.locale_color, args.player_name, args.player_color, args.message, Color.White)
    end
end

function NameTags:Chat(args)

    if string.sub(args.text, 1, 1) == "/" then return false end
    if args.player:GetValue("Slur") == 1 then return false end
    if args.player:GetValue("Muted") then return false end
    
    local message_args = 
    {
        id = GetNewMessageId(),
        player_name = args.player:GetName(),
        player_color = args.player:GetColor(),
        locale = args.player:GetValue("Locale") or 'en',
        locale_color = Color(45, 252, 214),
        message = args.text
    }
    
    if args.player:GetValue("NameTag") then
        message_args.player_tag = tostring(args.player:GetValue("NameTag").name)
		message_args.player_tag_color = args.player:GetValue("NameTag").color
    end
    
    self.pending_messages[message_args.id] = message_args
    
    Events:Fire("TranslateText", {
        id = message_args.id,
        text = args.text,
        player = args.player
    })
    
    -- If no response in 5 seconds, display original message
    Timer.SetTimeout(1000 * 5, function()
        if self.pending_messages[message_args.id] then
            self:Translation({id = message_args.id})
        end
    end)
    
    return false
end

function NameTags:ClientModuleLoad()

    for p in Server:GetPlayers() do
        
        if not p:GetValue("DonatorBenefits") or p:GetValue("DonatorBenefits").level == 0 then

            p:SetNetworkValue("NameTag", nil)
            
            if sp[tostring(p:GetSteamId())] then
                local tag_name = sp[tostring(p:GetSteamId())]
                p:SetNetworkValue("NameTag", {name = tag_name, color = spcol[tag_name]})
            end

        end
        
    end
    
end

NameTags = NameTags()