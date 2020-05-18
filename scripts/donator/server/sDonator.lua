class 'sDonator'

function sDonator:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS donators (steamID VARCHAR UNIQUE, level INTEGER, DonatorTagEnabled INTEGER, NameColor VARCHAR(11), DonatorTagColor VARCHAR(11), DonatorTagName VARCHAR(10), ColorStreakEnabled INTEGER, GhostRiderHeadEnabled INTEGER, ShadowWingsEnabled INTEGER)")

    self.commands = 
    {
        ["/donator"] = {level = DonatorLevel.Donator, msg = ""},
        ["/toggletag"] = {level = DonatorLevel.Donator, msg = "Turns your [Donator] tag (or custom tag) on/off."},
        ["/setcolor"] = {level = DonatorLevel.Colorful, msg = "Allows you to set your name color."},
        ["/tagcolor"] = {level = DonatorLevel.Colorful, msg = "Allows you to set your [Donator] tag color (or custom tag color)."},
        ["/togglestreak"] = {level = DonatorLevel.Colorful, msg = "Turns your color streak on/off."},
        ["/toggleghostrider"] = {level = DonatorLevel.GhostRider, msg = "Turns your Ghost Rider head and flame on/off."},
        ["Custom Nametag"] = {level = DonatorLevel.GhostRider, msg = "To get a custom tag instead of [Donator], please contact Lord Farquaad."},
        ["/togglewings"] = {level = DonatorLevel.ShadowWings, msg = "Turns your Shadow Wings on/off."},
    }

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerChat", self, self.PlayerChat)

    Network:Subscribe("Donator/SetColor", self, self.DonatorSetColor)
end

function sDonator:DonatorSetColor(args, player)
    if not args.type or not args.color then return end

    local benefits = player:GetValue("DonatorBenefits")
    if benefits.level < DonatorLevel.Colorful then return end

    if args.type == "name" then
        benefits.NameColor = args.color
        player:SetColor(args.color)
    elseif args.type == "tag" then
        benefits.DonatorTagColor = args.color
    end

    self:UpdatePlayer(player, benefits)
    self:UpdateDB(player)

end

function sDonator:ParseCustomNametag(args)

    if not IsAdmin(args.player) then return end
    
    local words = args.text:split(" ")

    if words[1] == "/tagname" and words[2] then
        local tag_name = ""
        for i = 3, #words do
            tag_name = tag_name .. words[i] .. " "
        end
        tag_name = tag_name:trim()

        local command = SQL:Command("UPDATE donators SET DonatorTagName = ? WHERE steamID = (?)")
        command:Bind(1, tag_name)
        command:Bind(2, tostring(words[2]))
        command:Execute()

        Chat:Send(args.player, string.format("Updated donator tag name to %s for [%s]", tag_name, words[2]), Color.Yellow)

    end
end

function sDonator:PlayerChat(args)

    self:ParseCustomNametag(args)

    local benefits = args.player:GetValue("DonatorBenefits")

    local words = args.text:split(" ")

    if self.commands[words[1]] and (not benefits or benefits.level == DonatorLevel.None) then
        Chat:Send(args.player, "You must be a donator to use this command! Learn more at patreon.com/PanauSurvival", Color.Red)
        return
    end

    local color = DonatorBenefits[DonatorLevel.Colorful].DonatorTagColor

    if words[1] == "/donator" then
        Chat:Send(args.player, "Donator commands:", color)
        for name, cmd_data in pairs(self.commands) do
            if name ~= "/donator" and benefits.level >= cmd_data.level then
                Chat:Send(args.player, string.format("%s", name), Color.Yellow, string.format(" - %s", cmd_data.msg), color)
            end
        end
        return
    end

    if words[1] == "/toggletag" and benefits.level >= self.commands["/toggletag"].level then
        benefits.DonatorTagEnabled = not benefits.DonatorTagEnabled
        Chat:Send(args.player, string.format("Donator tag turned %s.", benefits.DonatorTagEnabled and "on" or "off"), color)
        self:UpdatePlayer(args.player, benefits)
        self:UpdateDB(args.player)
        return
    end

    if words[1] == "/setcolor" and benefits.level >= self.commands["/setcolor"].level then
        Network:Send(args.player, "Donator/SetColor")
        return
    end

    if words[1] == "/tagcolor" and benefits.level >= self.commands["/tagcolor"].level then
        Network:Send(args.player, "Donator/SetTagColor")
        return
    end

    if words[1] == "/togglestreak" and benefits.level >= self.commands["/togglestreak"].level then
        benefits.ColorStreakEnabled = not benefits.ColorStreakEnabled
        Chat:Send(args.player, string.format("Donator color streak turned %s.", benefits.ColorStreakEnabled and "on" or "off"), color)
        self:UpdatePlayer(args.player, benefits)
        self:UpdateDB(args.player)
        return
    end

    if words[1] == "/toggleghostrider" and benefits.level >= self.commands["/toggleghostrider"].level then
        benefits.GhostRiderHeadEnabled = not benefits.GhostRiderHeadEnabled
        Chat:Send(args.player, string.format("Donator ghost rider head turned %s.", benefits.GhostRiderHeadEnabled and "on" or "off"), color)
        self:UpdatePlayer(args.player, benefits)
        self:UpdateDB(args.player)
        return
    end

    if words[1] == "/togglewings" and benefits.level >= self.commands["/togglewings"].level then
        benefits.ShadowWingsEnabled = not benefits.ShadowWingsEnabled
        Chat:Send(args.player, string.format("Donator shadow wings turned %s.", benefits.ShadowWingsEnabled and "on" or "off"), color)
        self:UpdatePlayer(args.player, benefits)
        self:UpdateDB(args.player)
        return
    end


end

function sDonator:ClientModuleLoad(args)
    
    args.player:SetNetworkValue("DonatorBenefits", nil)

    local steamID = tostring(args.player:GetSteamId())
	local query = SQL:Query("SELECT * FROM donators WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    local donator_data = Donators[steamID]

    if not donator_data then return end

    local donator_benefits = self:GetDefaultBenefits(donator_data.level)
    donator_benefits.NameColor = args.player:GetColor()
    donator_benefits.level = donator_data.level

    if count_table(result) > 0 and tonumber(donator_data.level) == tonumber(result[1].level) then -- if already in DB and level did not change

        for benefit_name, benefit_value in pairs(result[1]) do
            donator_benefits[benefit_name] = self:Deserialize(benefit_name, benefit_value)
        end

    elseif count_table(result) == 0 then

        local command = SQL:Command("INSERT INTO donators (steamID, level, DonatorTagEnabled, NameColor, DonatorTagColor, DonatorTagName, ColorStreakEnabled, GhostRiderHeadEnabled, ShadowWingsEnabled) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")
        command:Bind(1, steamID) -- Steam id
        command:Bind(2, donator_data.level) -- Donator level
        command:Bind(3, self:Serialize(DonatorBenefits[DonatorLevel.Donator].DonatorTagEnabled)) -- DonatorTagEnabled
        command:Bind(4, self:Serialize(args.player:GetColor())) -- NameColor
        command:Bind(5, self:Serialize(DonatorBenefits[DonatorLevel.Colorful].DonatorTagColor)) -- DonatorTagColor
        command:Bind(6, self:Serialize(DonatorBenefits[DonatorLevel.GhostRider].DonatorTagName)) -- DonatorTagName
        command:Bind(7, self:Serialize(DonatorBenefits[DonatorLevel.Colorful].ColorStreakEnabled)) -- ColorStreakEnabled
        command:Bind(8, self:Serialize(DonatorBenefits[DonatorLevel.GhostRider].GhostRiderHeadEnabled)) -- GhostRiderHeadEnabled
        command:Bind(9, self:Serialize(DonatorBenefits[DonatorLevel.ShadowWings].ShadowWingsEnabled)) -- ShadowWingsEnabled
        command:Execute()

    end

    if count_table(result) > 0 and donator_data.level ~= result[1].level then
        donator_benefits.level = donator_data.level
    end

    self:UpdatePlayer(args.player, donator_benefits)
    self:UpdateDB(args.player) -- Update in case player donator level changed

    Chat:Send(args.player, 
        "Hey there! Thanks for supporting the project. You can access your Patreon benefits with /donator", 
        DonatorBenefits[DonatorLevel.Colorful].DonatorTagColor)

end

function sDonator:UpdatePlayer(player, donator_benefits)

    player:SetColor(donator_benefits.NameColor)
    player:SetNetworkValue("DonatorBenefits", donator_benefits)

    player:SetNetworkValue("NameTag", donator_benefits.DonatorTagEnabled and
    {
        name = donator_benefits.DonatorTagName,
        color =donator_benefits.DonatorTagColor
    })

end

function sDonator:UpdateDB(player)

    local donator_data = player:GetValue("DonatorBenefits")
    
    local command = SQL:Command("UPDATE donators SET level = ?, DonatorTagEnabled = ?, NameColor = ?, DonatorTagColor = ?, DonatorTagName = ?, ColorStreakEnabled = ?, GhostRiderHeadEnabled = ?, ShadowWingsEnabled = ? WHERE steamID = (?)")
    command:Bind(1, donator_data.level) -- Donator level
    command:Bind(2, self:Serialize(donator_data.DonatorTagEnabled)) -- DonatorTagEnabled
    command:Bind(3, self:Serialize(donator_data.NameColor)) -- NameColor
    command:Bind(4, self:Serialize(donator_data.DonatorTagColor)) -- DonatorTagColor
    command:Bind(5, self:Serialize(donator_data.DonatorTagName)) -- DonatorTagName
    command:Bind(6, self:Serialize(donator_data.ColorStreakEnabled)) -- ColorStreakEnabled
    command:Bind(7, self:Serialize(donator_data.GhostRiderHeadEnabled)) -- GhostRiderHeadEnabled
    command:Bind(8, self:Serialize(donator_data.ShadowWingsEnabled)) -- ShadowWingsEnabled
    command:Bind(9, tostring(player:GetSteamId())) -- Steam id
    command:Execute()

end

function sDonator:GetDefaultBenefits(level)
    local benefits = {}

    for benefit_level, benefit in pairs(DonatorBenefits) do
        for benefit_name, b in pairs(benefit) do
            benefits[benefit_name] = b
        end
    end

    return benefits
end

function sDonator:Deserialize(type, data)
    if type:find("Enabled") then
        return tonumber(data) == 1 and true or false
    elseif type == "NameColor" or type == "DonatorTagColor" then
        local split = data:split(",")
        return Color(tonumber(split[1]), tonumber(split[2]), tonumber(split[3]))
    end
    return tostring(data)
end

function sDonator:Serialize(data)
    if type(data) == "boolean" then
        return data == true and 1 or 0
    elseif data.r and data.g and data.b then
        return string.format("%i,%i,%i", data.r, data.g, data.b)
    end
    return data
end

sDonator = sDonator()