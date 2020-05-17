class 'NameTags'
function NameTags:__init()

	Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerChat", self, self.Chat)

    self.local_chat_distance = 200
    
end
function NameTags:Chat(args)

	local timeTable = os.date("*t", os.time())
	timeTable.sec = tostring(timeTable.sec)
	timeTable.min = tostring(timeTable.min)
    timeTable.hour = tostring(timeTable.hour)
    
	local timeString = string.format("[%s:%s:%s] ",
                                timeTable.hour, timeTable.min, timeTable.sec)
                                
    if string.sub(args.text, 1, 1) == "/" then return false end
    if args.player:GetValue("Slur") == 1 then return false end
    if args.player:GetValue("Muted") then return false end
    
    if args.player:GetValue("NameTag") then
        
		local tag = tostring(args.player:GetValue("NameTag").name)
		local color = args.player:GetValue("NameTag").color
		local str1 = "[" .. tag .. "] "
		local str2 = args.player:GetName()
        local str3 = ": "..args.text
        
        if args.player:GetValue("LocalChat") then

            local func = coroutine.wrap(function()
                local nearby_players = {}
                local pos = args.player:GetPosition()

                for p in Server:GetPlayers() do

                    if p:GetCameraPosition():Distance(pos) < self.local_chat_distance then
                        table.insert(nearby_players, p)
                    end
                    Timer.Sleep(1)

                end

                for _, p in pairs(nearby_players) do
                    if IsValid(p) then
                        Chat:Send(p, "[LOCAL] ", Color.Yellow, str1, color, args.player:GetName(), args.player:GetColor(), str3, Color.White)
                    end
                end
            end)()
        else
            Chat:Broadcast(str1, color, args.player:GetName(), args.player:GetColor(), str3, Color.White)
        end

        if args.player:GetValue("LocalChat") then
            str1 = "[LOCAL] " .. str1
        end
        
        print(str1..str2..str3)
        Events:Fire("Discord", {
            channel = "Chat",
            content = str1..str2..str3
        })
        return false
        
    else
        
		local str2 = args.player:GetName()
        local str3 = ": "..args.text
        
		Chat:Broadcast(args.player:GetName(), args.player:GetColor(), str3, Color.White)
		print(str2..str3)
        Events:Fire("Discord", {
            channel = "Chat",
            content = str2..str3
        })
        return false
        
	end
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