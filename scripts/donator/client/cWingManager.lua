class 'cWingManager'

function cWingManager:__init()

	self.wings = {} --player id, wing class
	
	self.default_speed = 51
	self.max_speed = 100
	self.min_speed = 1
	self.timer = Timer()
	
	self.speed = self.default_speed
	
	Events:Subscribe("SecondTick", self, self.CheckForWings)
	--Events:Subscribe("LocalPlayerChat", self, self.Chat)
end

function cWingManager:Chat(args)
	
	--if args.text == "/anim" then
	--	self.wings[LocalPlayer:GetId()]:SetAnimation("TAKEOFF")
	--end
	
end

function cWingManager:CheckForWings()
	
	for p in Client:GetStreamedPlayers() do
		self:CheckPlayer(p)
	end
    
    self:CheckPlayer(LocalPlayer)

end

function cWingManager:CheckPlayer(p)
    --DonatorBenefits

    local benefits = p:GetValue("DonatorBenefits")
    local shadow_wings_enabled = benefits.ShadowWingsEnabled and benefits.level >= DonatorLevel.ShadowWings

    if shadow_wings_enabled and not self.wings[p:GetId()] then
        self.wings[p:GetId()] = Wings(p)
    elseif not shadow_wings_enabled and self.wings[p:GetId()] then
        self.wings[p:GetId()]:Remove()
        self.wings[p:GetId()] = nil
    end
end

cWingManager = cWingManager()