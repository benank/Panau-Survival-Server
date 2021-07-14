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
            ['en'] = {
                ['player_tag'] = 'player tag',
                ['message'] = 'chat message contents',
            },
            ['ru'] = {
                ['player_tag'] = 'player tag',
                ['message'] = 'chat message contents',
            }
        }
    }

]]
function NameTags:Translation(args)
    local message_args = self.pending_messages[args.id]
    if not message_args then return end
    
    -- Send individual messages to players
    for p in Server:GetPlayers() do
        local player_locale = p:GetValue("Locale") or 'en'
        local player_translation = args.translations[player_locale] or message_args.translations[player_locale]
        if not player_translation then
            player_translation = message_args.translations['en'] or message_args.translations['en']
        end
        
        if player_translation then
            message_args.message = data.message
            SendMessageToPlayer(message_args, p)
        end
    end
    
    local string_message = message_args.player_name .. ": " .. message_args.message
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
    
    if args.player_tag then
        args.player_tag = "[" .. args.player_tag .. "] "
        Chat:Send(player, args.player_tag, args.player_tag_color, 
                       args.player_name, args.player_color, args.message, Color.White)
    else
        Chat:Send(player, args.player_name, args.player_color, args.message, Color.White)
    end
end

function NameTags:Chat(args)

    if string.sub(args.text, 1, 1) == "/" then return false end
    if args.player:GetValue("Slur") == 1 then return false end
    if args.player:GetValue("Muted") then return false end
    
    local message_args = 
    {
        id = GetNewMessageId(),
        translations = 
        {
            ['en'] = 
            {
                player_name = args.player:GetName(),
                player_color = args.player:GetColor(),
                message = args.text
            }
        }
    }
    
    if args.player:GetValue("NameTag") then
        message_args.translations['en'].player_tag = tostring(args.player:GetValue("NameTag").name)
		message_args.translations['en'].player_tag_color = args.player:GetValue("NameTag").color
    end
    
    self.pending_messages[message_args.id] = message_args
    
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