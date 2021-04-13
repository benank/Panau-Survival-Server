class 'SAMManager'

function SAMManager:__init()
	SAMTimer	=	Timer()
	Events:Subscribe("Render", self, self.RenderSAMs)
	Events:Subscribe("PreTick", self, self.CheckClientPlayers)
end

function SAMManager:RenderSAMs()
	if Game:GetState() ~= GUIState.Game then return end
	local ScreenSize		=	Render.Size
	local DisplaySAMCount	=	0
	for k,v in ipairs(SAMAnimationManager.ClientAnimationTable) do
		if Vector3.Distance(LocalPlayer:GetPosition(), v.Anchor) <= v.Radius then
			DisplaySAMCount	=	DisplaySAMCount + 1
			local SAMLocation	=	Render:WorldToMinimap(v.Anchor)
			local SAMMapIndicatorRadius	=	3
			local SAMMapVectorRadius	=	Vector2(SAMMapIndicatorRadius, SAMMapIndicatorRadius)
			Render:FillArea(Vector2(SAMLocation.x - SAMMapVectorRadius.x / 2, SAMLocation.y - SAMMapVectorRadius.y / 2), SAMMapVectorRadius, SAMDisplayMiniMapColor)
			local SAMRay = Physics:Raycast(v.Chasis:GetPosition(), (v.RightBarrel:GetAngle() * Vector3(0, 0, -1)), 10, 512)
			local SAMChasisMapPoint	=	Render:WorldToMinimap(v.Chasis:GetPosition())
			local SAMRayMapPoint	=	Render:WorldToMinimap(SAMRay.position)
			Render:DrawLine(SAMChasisMapPoint, SAMRayMapPoint, SAMDisplayMiniMapColor)
		end
	end
	if DisplaySAMCount > 0 then
		local DisplayText			=	"Nearby SAMs: " .. DisplaySAMCount
		local EffectiveFontSize		=	SAMDisplayCountFontSize * ScreenSize.y / 1000
		local Textsize				=	Render:GetTextSize(DisplayText, EffectiveFontSize)
		local EffectiveTextColor	=	SAMDisplayColor
		local SAMDisplayPointX		=	ScreenSize.x * SAMDisplayOffsetX
		local SAMDisplayPointY		=	ScreenSize.y * SAMDisplayOffsetY
		Render:FillArea(Vector2(SAMDisplayPointX - Textsize.x / 2 -2, SAMDisplayPointY -2), Vector2(Textsize.x +4, Textsize.y +4), Color(0, 0, 0, 150))
		Render:DrawText(Vector2(SAMDisplayPointX - Textsize.x / 2, SAMDisplayPointY), DisplayText, EffectiveTextColor, EffectiveFontSize)
	end
end

function SAMManager:CheckClientPlayers()
	if SAMTimer:GetSeconds() < SAMInteger / 10 then return end
	self:CheckSAMs(LocalPlayer)
	for players in Client:GetPlayers() do
		self:CheckSAMs(players)
	end
end

function SAMManager:FireSAM(missile, sender, target, targetVehicle, statsTable)
	local NewMissile					=	{}
		NewMissile.name				=	missile
		NewMissile.senderObject		=	target
		NewMissile.targetObject		=	targetVehicle
		NewMissile.originPosition	=	sender:GetPosition()
		NewMissile.originAngle		=	sender:GetAngle()
		NewMissile.string			=	infoString
		NewMissile.print			=	infoPrint
		NewMissile.statsTable		=	statsTable
	EntityManager:CreateEntity(NewMissile)
end

function SAMManager:CheckSAMs(player)
	local PlayerPosition		=	player:GetPosition()
	local PlayerVehicle			=	player:GetVehicle()
	
	if PlayerVehicle then
		if IsValidVehicle(PlayerVehicle:GetModelId(), SAMMissileVehicles) then
			if SAMTimer:GetSeconds() < SAMInteger then return end
			for k,v in ipairs(SAMAnimationManager.ClientAnimationTable) do
				if Vector3.Distance(PlayerPosition, v.Anchor) <= v.Radius then
					SAMTimer:Restart()
					self:FireSAM("SAMTableRocket", v.RightBarrel, player, PlayerVehicle, SAMStatsTable)
					self:FireSAM("SAMTableRocket", v.LeftBarrel, player, PlayerVehicle, SAMStatsTable)
				end
			end
		end
	end
end

SAMManager = SAMManager()