class 'sWhisper'

function sWhisper:__init()
    self.color = Color(108, 70, 221)
    Events:Subscribe("PlayerChat", self, self.PlayerChat)
end

function sWhisper:PlayerChat(args)

    local words = args.text:split(" ")

    if string.lower(words[1]) == "/w" and words[2] and words[3] then
        self:WhisperPlayer(args)
    elseif string.lower(words[1]) == "/r" and words[2] then
        self:ReplyPlayer(args)
    end

end

function sWhisper:WhisperPlayer(args)

    local words = args.text:split(" ")

    local target = words[2]

    if target:sub(1,3) == "id:" then
        -- Player typed /w id:5 hello!
        target = target:gsub("id:", "")
        target = Player.GetById(tonumber(target))
    else
        -- Player types /w NAME hello!
        target = Player.Match(target)[1]
    end

    if not IsValid(target) then
        Chat:Send(args.player, "Player not found for whisper! Try using /w id:[number] [message]", Color.Red)
        return
    end

    if target == args.player then
        Chat:Send(args.player, "You cannot whisper to yourself!", Color.Red)
        return
    end

    local index1 = string.find(args.text, " ") + 1
    local message_start_index = string.find(args.text:sub(index1, args.text:len()), " ")
    local message = args.text:sub(message_start_index + index1, args.text:len())

    Chat:Send(target, string.format("%s whispers: %s", args.player:GetName(), message), args.player:GetColor())
    Chat:Send(args.player, string.format("You whisper to %s: %s", target:GetName(), message), target:GetColor())

    target:SetValue("LastMessagedPlayer", args.player)
    args.player:SetValue("LastMessagedPlayer", target)

    Events:Fire("Discord", {
        channel = "Private Messages",
        content = string.format("%s whispers to %s: %s", args.player:GetName(), target:GetName(), message)
    })
end

function sWhisper:ReplyPlayer(args)

    local words = args.text:split(" ")

    local target = args.player:GetValue("LastMessagedPlayer")

    if not IsValid(target) then
        Chat:Send(args.player, "No one to reply to!", Color.Red)
        return
    end

    if target == args.player then
        Chat:Send(args.player, "You cannot whisper to yourself!", Color.Red)
        return
    end

    local message = args.text:sub(4, args.text:len())

    Chat:Send(target, string.format("%s whispers: %s", args.player:GetName(), message), args.player:GetColor())
    Chat:Send(args.player, string.format("You whisper to %s: %s", target:GetName(), message), target:GetColor())

    target:SetValue("LastMessagedPlayer", args.player)
    args.player:SetValue("LastMessagedPlayer", target)

    Events:Fire("Discord", {
        channel = "Private Messages",
        content = string.format("%s whispers to %s: %s", args.player:GetName(), target:GetName(), message)
    })
end

sWhisper = sWhisper()