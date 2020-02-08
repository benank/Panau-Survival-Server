class 'NT_Tags'
function NT_Tags:__init()
	Events:Subscribe("PlayerAuthenticate", self, self.SetTagOnJoin)
	Events:Subscribe("ModuleLoad", self, self.SetTagOnReload)
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
		local str1 = tag.." "
		local str2 = args.player:GetName()
		local str3 = ": "..args.text
		local disguised = args.player:GetValue("Disguised")
		if disguised then
			Chat:Broadcast(args.player:GetName(), args.player:GetColor(), str3, Color.White)
		else
			Chat:Broadcast(str1, color, args.player:GetName(), args.player:GetColor(), str3, Color.White)
		end
		print(str1..str2..str3)
		return false
	else
		local color = args.player:GetValue("NT_TagColor")
		local str2 = args.player:GetName()
		local str3 = ": "..args.text
		Chat:Broadcast(args.player:GetName(), args.player:GetColor(), str3, Color.White)
		print(str2..str3)
		return false
	end
end
function NT_Tags:SetTagOnJoin(args)
	local tagname = ""
	local tagcolor = Color(255,255,255)
	for steamid, tagn in pairs(sp) do
		if tostring(args.player:GetSteamId()) == tostring(steamid) then
			tagname = tagn
			tagcolor = spcol[tagn]
			args.player:SetNetworkValue("NT_TagName", tagname)
			args.player:SetNetworkValue("NT_TagColor", tagcolor)
		end
	end
end
function NT_Tags:SetTagOnReload()
	for p in Server:GetPlayers() do
		p:SetNetworkValue("NT_TagName", nil)
		p:SetNetworkValue("NT_TagColor", nil)
		local tagname = ""
		local tagcolor = Color(255,255,255)
		for steamid, tagn in pairs(sp) do
			if tostring(p:GetSteamId()) == steamid then
				tagname = tagn
				tagcolor = spcol[tagn]
				p:SetNetworkValue("NT_TagName", tagname)
				p:SetNetworkValue("NT_TagColor", tagcolor)
			end
		end
	end
end
NT_Tags = NT_Tags()