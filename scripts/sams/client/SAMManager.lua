class 'SAMManager'

function SAMManager:__init()
	
	self.sams = {}
	
	SAMTimer	=	Timer()
	-- Events:Subscribe("Render", self, self.RenderSAMs)
	-- Events:Subscribe("PreTick", self, self.CheckClientPlayers)
	
	Network:Subscribe("sams/SyncSAM", self, self.SyncSAM)
	Network:Subscribe("sams/SAMFire", self, self.FireSAMServer)
    Events:Subscribe("LocalPlayerBulletSplash", self, self.LocalPlayerBulletSplash)

end

function SAMManager:LocalPlayerBulletSplash(args)
	
	if not args.radius then
		args.radius = 10
	end
	
    Thread(function()
        for id, sam in pairs(self.sams) do
            if not sam.destroyed and sam.position:Distance(args.hit_position) < args.radius then
                args.sam_id = sam.id
                Network:Send("sams/SplashHitSAM", args)
            end
            Timer.Sleep(1)
        end
    end)
end

function SAMManager:SyncSAM(args)
	
	-- Too far to sync
	if args.position then
		if args.position:Distance(LocalPlayer:GetPosition()) > 3000 then
			return
		end
	end
	
	if self.sams[args.id] then
		
		-- SAM destroyed
		if not self.sams[args.id].destroyed and args.destroyed then
			SAMAnimationManager:RemoveById(args.id)
			-- 97, 252, 442
			ClientEffect.Play(AssetLocation.Game, {
				effect_id = 252,
				position = self.sams[args.id].position,
				angle = Angle()
			})
			self.sams[args.id] = nil
		else
		
			for key, value in pairs(args) do
				self.sams[args.id][key] = value
			end
		end
	else
		self.sams[args.id] = args
	end
	
	Events:Fire("sams/SamUpdated", args)
end

function SAMManager:RenderSAMs()
	if Game:GetState() ~= GUIState.Game then return end
	local ScreenSize		=	Render.Size
	local DisplaySAMCount	=	0
	for k,v in pairs(SAMAnimationManager.ClientAnimationTable) do
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

function SAMManager:FireSAM(missile, sender, target, targetVehicle, statsTable, sam_id)
	statsTable.sam_id = sam_id
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
			for k,v in pairs(SAMAnimationManager.ClientAnimationTable) do
				if Vector3.Distance(PlayerPosition, v.Anchor) <= v.Radius then
					SAMTimer:Restart()
					self:FireSAM("SAMTableRocket", v.RightBarrel, player, PlayerVehicle, v.config)
					self:FireSAM("SAMTableRocket", v.LeftBarrel, player, PlayerVehicle, v.config)
				end
			end
		end
	end
end

function SAMManager:FireSAMServer(args)
	local vehicle = Vehicle.GetById(args.vehicle_id)
	local player = Player.GetById(args.player_id)
	if not IsValid(vehicle) or not IsValid(player) then return end
	local sam = self.sams[args.sam_id]
	if not sam then return end
	if not SAMAnimationManager.ClientAnimationTable[args.sam_id] then return end
	
	self:FireSAM("SAMTableRocket", SAMAnimationManager.ClientAnimationTable[args.sam_id].RightBarrel, player, vehicle, sam.config, sam.id)
	self:FireSAM("SAMTableRocket", SAMAnimationManager.ClientAnimationTable[args.sam_id].LeftBarrel, player, vehicle, sam.config, sam.id)
end

SAMManager = SAMManager()