class 'SAMAnimationManager'

function SAMAnimationManager:__init()
	self.AnimationActive		=	true
	
	--	Timer Integers	--d
	self.AnimateInteger			=	10	--	Milliseconds
	self.ArrangeInteger			=	1.5	--	Seconds
	
	--	Rotation Speeds	--
	self.SAMChasisRotationSpeed	=	0.050--0.005
	self.SAMRadarRotationSpeed	=	0.050
	
	--	Offsets	--
	self.SAMBarrelAngle			=	0.5
	self.SAMRadarOffset			=	Vector3(0, 3.75, 0.7)
	self.SAMBarrelRightOffset	=	Vector3(-1, 2.5, 0.5)
	self.SAMBarrelLeftOffset	=	Vector3(1, 2.5, 0.5)
	
	--	Timers to start	--
	self.AnimateTimer	=	Timer()
	self.ArrangeTimer	=	Timer()
	
	--	Tables to Define	--
	self.ClientAnimationTable	=	{}
	
	--	Arrange Tables to Run at Startup	--
--	self:ArrangeTable()
	
	Events:Subscribe("PreTick", self, self.PreTick)
	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
	Events:Subscribe("ModulesLoad",  self, self.Activate)
end

function SAMAnimationManager:Activate()
	self.SystemActive	=	true
end

function SAMAnimationManager:PreTick()
	if not self.SystemActive then return end
--	if Game:GetState() ~= GUIState.Game then return end
	self:ArrangeTables()
	self:AnimateObjects()
end

function SAMAnimationManager:ArrangeTables()
	if self.ArrangeTimer:GetSeconds() >= self.ArrangeInteger then
		self.ArrangeTimer:Restart()
		self:ArrangeTable()
	end
end

function SAMAnimationManager:AnimateObjects()
	if self.AnimateTimer:GetMilliseconds() >= self.AnimateInteger then
		self.AnimateTimer:Restart()
		self:Animate()
	end
end

function SAMAnimationManager:RemoveById(id)
	if self.ClientAnimationTable[id] then
		self:Remove(self.ClientAnimationTable[id], true)
	end
end

function SAMAnimationManager:Animate()
	if not self.AnimationActive then return false end
	for k,v in pairs(self.ClientAnimationTable) do
		if Vector3.Distance(Camera:GetPosition(), v.Anchor) <= v.Radius then
			self:Animation(v)
		else
			self:Remove(v, true)
		end
	end
end

function SAMAnimationManager:NotBuilt(id)
	return self.ClientAnimationTable[id] == nil
end

function SAMAnimationManager:Animation(objectTable)
	local AnchorPoint			=	objectTable.Anchor
	local AnchorAngle			=	Angle(0, 0, 0)	--objectTable.Anchor:GetAngle()
	
	--	Set Chasis and Mount position relative to Anchor so that all calculations are correct.
	objectTable.Mount:SetPosition(AnchorPoint)
	objectTable.Mount:SetAngle(AnchorAngle)
	objectTable.Chasis:SetPosition(AnchorPoint)
	
	--	Animate Chasis	--
	local ChasisPosition		=	objectTable.Chasis:GetPosition()
	local PreviousChasisAngle	=	objectTable.Chasis:GetAngle()
	local NewChasisAngle		=	Angle(PreviousChasisAngle.yaw + self.SAMChasisRotationSpeed, 0, 0)
	objectTable.Chasis:SetAngle(NewChasisAngle)
	--	Animate Radar	--
	local RadarPosition			=	objectTable.Radar:GetPosition()
	local PreviousRadarAngle	=	objectTable.Radar:GetAngle()
	local NewRadarAngle			=	Angle(PreviousRadarAngle.yaw + self.SAMRadarRotationSpeed, 0, 0)
	local NewRadarPosition		=	ChasisPosition + (NewChasisAngle * self.SAMRadarOffset)
	objectTable.Radar:SetAngle(NewRadarAngle)
	objectTable.Radar:SetPosition(NewRadarPosition)
	--	Animate Right Barrel	--
	local RightBarrelPosition		=	objectTable.RightBarrel:GetPosition()
	local PreviousRightBarrelAngle	=	objectTable.RightBarrel:GetAngle()
	local NewRightBarrelAngle		=	Angle(NewChasisAngle.yaw, self.SAMBarrelAngle, NewChasisAngle.roll)
	local NewRightBarrelPosition	=	ChasisPosition + (NewChasisAngle * self.SAMBarrelRightOffset)
	objectTable.RightBarrel:SetAngle(NewRightBarrelAngle)
	objectTable.RightBarrel:SetPosition(NewRightBarrelPosition)
	--	Animate Left Barrel	--
	local LeftBarrelPosition		=	objectTable.LeftBarrel:GetPosition()
	local PreviousLeftBarrelAngle	=	objectTable.LeftBarrel:GetAngle()
	local NewLeftBarrelAngle		=	Angle(NewChasisAngle.yaw, -self.SAMBarrelAngle, math.pi)
	local NewLeftBarrelPosition		=	ChasisPosition + (NewChasisAngle * self.SAMBarrelLeftOffset)
	objectTable.LeftBarrel:SetAngle(NewLeftBarrelAngle)
	objectTable.LeftBarrel:SetPosition(NewLeftBarrelPosition)
end

function SAMAnimationManager:ArrangeTable()
	if not self.AnimationActive then return false end
	if not SAMManager.sams then return end
--	print("Arranging SAM Table...")
	local TableCount		=	0
	for id, sam in pairs(SAMManager.sams) do
		if not sam.destroyed and sam.position and Vector3.Distance(Camera:GetPosition(), sam.position) <= 1024 then
			if self:NotBuilt(sam.id) then
				self:Create(sam)
				TableCount		=	TableCount + 1
			end
		end
	end
--	print("Table Count: " .. TotalTableCount, #self.ClientAnimationTable)
end

function SAMAnimationManager:Create(sam)
--	print("Creating SAM...")
	local SAMTable	=	sam
	sam.Anchor = sam.position
	sam.Radius = 1024
	local BuildLocation	=	sam.position
	
	local args		=	{}
	args.position	=	BuildLocation
	args.angle		=	Angle(0, 0, 0)
	args.model		=	"general.blz/wea31-a.lod"
	args.collision	=	"wea31_lod1-a_col.pfx"
	args.world		=	LocalPlayer:GetWorld()
	args.enabled	=	true
	args.fixed		=	true	--	Set to false to allow players to move with it and it move slower
	SAMTable.Mount = ClientStaticObject.Create(args)
	Events:Fire("sams/CreateSAM", {
		id = sam.id, 
		cso_id = SAMTable.Mount:GetId(),
		cso = SAMTable.Mount
	})
	
	local args		=	{}
	args.position	=	BuildLocation
	args.angle		=	Angle(math.random(-1, 1), 0, 0)	--Angle(0, 0, 0)
	args.model		=	"general.blz/wea31-b.lod"
	args.collision	=	"wea31_lod1-b_col.pfx"
	args.world		=	LocalPlayer:GetWorld()
	args.enabled	=	true
	args.fixed		=	false	--	Set to false to allow players to move with it and it move slower
	SAMTable.Chasis = ClientStaticObject.Create(args)
	Events:Fire("sams/CreateSAM", {
		id = sam.id, 
		cso_id = SAMTable.Chasis:GetId(),
		cso = SAMTable.Chasis
	})
	
	local args		=	{}
	args.position	=	BuildLocation
	args.angle		=	Angle(0, 0, 0)
	args.model		=	"general.blz/wea31-e.lod"
	args.collision	=	"wea31_lod1-e_col.pfx"
	args.world		=	LocalPlayer:GetWorld()
	args.enabled	=	true
	args.fixed		=	true	--	Set to false to allow players to move with it and it move slower
	SAMTable.Radar = ClientStaticObject.Create(args)
	Events:Fire("sams/CreateSAM", {
		id = sam.id, 
		cso_id = SAMTable.Radar:GetId(),
		cso = SAMTable.Radar
	})
	
	local args		=	{}
	args.position	=	BuildLocation
	args.angle		=	Angle(0, 0, 0)
	args.model		=	"general.blz/wea31-c.lod"
	args.collision	=	"wea31_lod1-c_col.pfx"
	args.world		=	LocalPlayer:GetWorld()
	args.enabled	=	true
	args.fixed		=	true	--	Set to false to allow players to move with it and it move slower
	SAMTable.RightBarrel = ClientStaticObject.Create(args)
	Events:Fire("sams/CreateSAM", {
		id = sam.id, 
		cso_id = SAMTable.RightBarrel:GetId(),
		cso = SAMTable.RightBarrel
	})
	
	local args		=	{}
	args.position	=	BuildLocation
	args.angle		=	Angle(0, 0, 0)
	args.model		=	"general.blz/wea31-c.lod"
	args.collision	=	"wea31_lod1-c_col.pfx"
	args.world		=	LocalPlayer:GetWorld()
	args.enabled	=	true
	args.fixed		=	true	--	Set to false to allow players to move with it and it move slower
	SAMTable.LeftBarrel = ClientStaticObject.Create(args)
	Events:Fire("sams/CreateSAM", {
		id = sam.id, 
		cso_id = SAMTable.LeftBarrel:GetId(),
		cso = SAMTable.LeftBarrel
	})
	
	self.ClientAnimationTable[sam.id] = SAMTable
end

function SAMAnimationManager:ModuleUnload()
--	print("Module Unload")
	for k,v in pairs(self.ClientAnimationTable) do
		self:Remove(v, false)
	end
end

function SAMAnimationManager:Remove(samTable, clearTable)
--	print("Removing...", key, samTable)
	if IsValid(samTable.Mount) then
		samTable.Mount:Remove()
	end
	if IsValid(samTable.Chasis) then
		samTable.Chasis:Remove()
	end
	if IsValid(samTable.Radar) then
		samTable.Radar:Remove()
	end
	if IsValid(samTable.RightBarrel) then
		samTable.RightBarrel:Remove()
	end
	if IsValid(samTable.LeftBarrel) then
		samTable.LeftBarrel:Remove()
	end
	if clearTable then
		self.ClientAnimationTable[samTable.id] = nil
	end
end

SAMAnimationManager = SAMAnimationManager()