class 'Notifications'

function Notifications:__init()

	Events:Subscribe("Notification", self, self.GetNotification)
	Network:Subscribe("Notification", self, self.GetNotification)
	Events:Subscribe("Render", self, self.Render)
	
	self.icons = 
	{
		Upgrade		= 	Image.Create(AssetLocation.Resource, "Upgrade"),
		Information	= 	Image.Create(AssetLocation.Resource, "Information"),
		Warning		= 	Image.Create(AssetLocation.Resource, "Warning")
	}

	
	NotificationQueue = {}
	
	MainTxt 	= 	nil
	SubTxt 		= 	nil
	ImageType 	= 	nil
	MainColor	= 	nil
	SubColor	=	nil
	Time		=	nil
	
	ProcessTimer = Timer()
	
	self.presets = 
	{
		default = 
		{
			title_color =  Color.White,
			subtitle_color = Color(200, 200, 200),
			time = 5000,
			icon = "Information"
		},
		upgrade = 
		{
			title_color = Color.White,
			subtitle_color = Color(200, 200, 200),
			time = 5000,
			icon = "Upgrade"
		},
		warning = 
		{
			title_color = Color.Red,
			subtitle_color = Color(200, 0, 0),
			time = 5000,
			icon = "Warning"
		}
	}

end

function Notifications:GetNotification(args)
	
	local n = {}

	-- Copy appropriate preset data
	if self.presets[args.preset] then
		for k,v in pairs(self.presets[args.preset]) do n[k] = v end
	else
		for k,v in pairs(self.presets.default) do n[k] = v end
	end

	-- Overrite preset data with given data
	for k,v in pairs(args) do n[k] = v end

	if not n.title then
		error("Could not create notification without a title")
		return
	end

	table.insert(NotificationQueue, n)

end

function Notifications:ProcessQueue()
	
	if table.count(NotificationQueue) > 0 then
		for k, args in ipairs(NotificationQueue) do 
			MainTxt 	= 	args.title
			ImageType 	= 	args.icon
			SubTxt 		= 	args.subtxt
			Time		=	args.time
			MainColor	=	args.title_color
			SubColor	=	args.subtitle_color
			FadeInTimer =	Timer()
			table.remove(NotificationQueue, k)
		end
	end
end

function Notifications:Render()

	if FadeInTimer ~= nil or DelayTimer ~= nil or FadeOutTimer ~= nil then
	
	
	if MainTxt == nil then
		Console:Print(" -- [Notifications] Warning! Notifications cannot be printed without a main text! --", Color.Red)
		FadeInTimer = nil
		return
	end
	
	if Render:GetTextWidth(MainTxt, 15) > 200 then
		Console:Print(" -- [Notifications] Warning! Your main text is too long to fit! --", Color.Red)
		FadeInTimer = nil
		return
	end
	
	if SubTxt ~= nil then
		if Render:GetTextWidth(SubTxt, 15) > 230 then
			Console:Print(" -- [Notifications] Warning! Your sub text is too long to fit! --", Color.Red)
			FadeInTimer = nil
			return
		end
	end
	
	if FadeInTimer ~= nil then
		TxtAlpha 		= 	math.clamp(0 + (FadeInTimer:GetSeconds() * 400), 0, 200)
		RenderAlpha1	= 	math.clamp(0 + (FadeInTimer:GetSeconds() * 360), 0, 180)
		RenderAlpha2	= 	math.clamp(0 + (FadeInTimer:GetSeconds() * 340), 0, 170)
		ImageAlpha 		= 	math.clamp(0 + (FadeInTimer:GetSeconds() * 2), 0, 1)
		if TxtAlpha >= 200 or  RenderAlpha1 >= 180 or RenderAlpha2 >= 170 or ImageAlpha >= 1 then
			TxtAlpha 	 = 200
			RenderAlpha1 = 180
			RenderAlpha2 = 170
			ImageAlpha 	 = 1
			DelayTimer 	= Timer()
			FadeInTimer = nil
		end
	end
	
	if DelayTimer ~= nil then
		if DelayTimer:GetMilliseconds() >= Time then
			DelayTimer = nil
			FadeOutTimer = Timer()
		end
	end
	
	if FadeOutTimer ~= nil then
		TxtAlpha 		= 	math.clamp(200 - (FadeOutTimer:GetSeconds() * 66.66666666666667), 0, 200)
		RenderAlpha1	= 	math.clamp(180 - (FadeOutTimer:GetSeconds() * 60), 0, 180)
		RenderAlpha2	= 	math.clamp(170 - (FadeOutTimer:GetSeconds() * 56.66666666666667), 0, 170)
		ImageAlpha		= 	math.clamp(1 - (FadeOutTimer:GetSeconds() / 3), 0, 	1)
		if TxtAlpha <= 0 or  RenderAlpha1 <= 0 or RenderAlpha2 <= 0 or ImageAlpha <= 0 then
			FadeOutTimer = nil
			self.ProcessQueue()
		end
	end
	
	local MainTxt 	= 	MainTxt
	local SubTxt	=	SubTxt
	local ImageType	=	tostring(ImageType)
	
	Render:FillArea(Vector2((Render.Width - 255),40), Vector2((250),40), Color(0,0,0,RenderAlpha1))
	Render:FillArea(Vector2((Render.Width - 255),40), Vector2((1),40), Color(170,170,170,RenderAlpha2))
	Render:FillArea(Vector2((Render.Width - 210),40), Vector2((1),40), Color(130,130,130,RenderAlpha2))
	Render:FillArea(Vector2((Render.Width - 5),40), Vector2((1),40), Color(170,170,170,RenderAlpha2))
	Render:FillArea(Vector2((Render.Width - 255),40), Vector2((250),1), Color(170,170,170,RenderAlpha2))
	Render:FillArea(Vector2((Render.Width - 255),80), Vector2((250),1), Color(170,170,170,RenderAlpha2))
	
	if ImageType == "Upgrade" or ImageType == "3" then
		Upgrade:SetAlpha(ImageAlpha)
		Upgrade:Draw(Vector2((Render.Width - 249), 42.5), Vector2(35,35), Vector2(0,0),Vector2(1,1))
	elseif ImageType == "Information" or ImageType == "1" then
		Information:SetAlpha(ImageAlpha)
		Information:Draw(Vector2((Render.Width - 249), 42.5), Vector2(35,35), Vector2(0,0),Vector2(1,1))
	elseif ImageType == "Warning" or ImageType == "2" then
		Warning:SetAlpha(ImageAlpha)
		Warning:Draw(Vector2((Render.Width - 249), 42.5), Vector2(35,35), Vector2(0,0),Vector2(1,1))
	else
		Information:SetAlpha(ImageAlpha)
		Information:Draw(Vector2((Render.Width - 249), 42.5), Vector2(35,35), Vector2(0,0),Vector2(1,1))
	end

	local MainTxtColor = MainColor
	MainTxtColor.a = TxtAlpha
	local SubTxtColor = SubColor
	SubTxtColor.a = TxtAlpha
	
	if SubTxt ~= nil then
		Render:DrawText(Vector2((Render.Width - 107.5 ) - (Render:GetTextWidth(MainTxt, 15) / 2), 46), MainTxt, MainTxtColor, 15)
		Render:DrawText(Vector2((Render.Width - 107.5 ) - (Render:GetTextWidth(SubTxt, 12) / 2), 63), SubTxt, SubTxtColor, 12)
	else
		Render:DrawText(Vector2((Render.Width - 107.5 ) - (Render:GetTextWidth(MainTxt, 15) / 2), 54), MainTxt, MainTxtColor, 15)
	end
	
	else
	
		if ProcessTimer then
			if ProcessTimer:GetSeconds() >= 1 then
				self.ProcessQueue()
				ProcessTimer:Restart()
			end
		end
		
	end
end

Notifications = Notifications()