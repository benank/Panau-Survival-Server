class 'NT_Tags'
function NT_Tags:__init()

	Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("PlayerChat", self, self.Chat)
    
end
function NT_Tags:Chat(args)

	local timeTable = os.date("*t", os.time())
	timeTable.sec = tostring(timeTable.sec)
	timeTable.min = tostring(timeTable.min)
    timeTable.hour = tostring(timeTable.hour)
    
	local timeString = string.format("[%s:%s:%s] ",
                                timeTable.hour, timeTable.min, timeTable.sec)
                                
    if string.sub(args.text, 1, 1) == "/" then return false end
    if args.player:GetValue("Slur") == 1 then return false end
    if args.player:GetValue("Muted") then return false end
    
    if args.player:GetValue("NT_TagName") then
        
		local tag = tostring(args.player:GetValue("NT_TagName"))
		local color = args.player:GetValue("NT_TagColor")
		local str1 = "[" .. tag .. "] "
		local str2 = args.player:GetName()
		local str3 = ": "..args.text
        
		Chat:Broadcast(str1, color, args.player:GetName(), args.player:GetColor(), str3, Color.White)
        
		print(str1..str2..str3)
        return false
        
    else
        
		local str2 = args.player:GetName()
        local str3 = ": "..args.text
        
		Chat:Broadcast(args.player:GetName(), args.player:GetColor(), str3, Color.White)
		print(str2..str3)
        return false
        
	end
end

function NT_Tags:ClientModuleLoad()

    for p in Server:GetPlayers() do
        
        if not p:GetValue("DonatorBenefits") or p:GetValue("DonatorBenefits").level == 0 then

            p:SetNetworkValue("NT_TagName", nil)
            p:SetNetworkValue("NT_TagColor", nil)
            
            if sp[tostring(p:GetSteamId())] then
                local tag_name = sp[tostring(p:GetSteamId())]
                p:SetNetworkValue("NT_TagName", tag_name)
                p:SetNetworkValue("NT_TagColor", spcol[tag_name])
            end

        end
        
    end
    
end
NT_Tags = NT_Tags()