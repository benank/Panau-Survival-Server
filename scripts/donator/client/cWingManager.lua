class 'cWingManager'

function cWingManager:__init()

	self.wings = {} --player id, wing class
	
	Events:Subscribe("SecondTick", self, self.CheckForWings)
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

    if not benefits then return end

    local shadow_wings_enabled = benefits.ShadowWingsEnabled and benefits.level >= DonatorLevel.ShadowWings

    if shadow_wings_enabled and not self.wings[p:GetId()] then
        self.wings[p:GetId()] = Wings(p)
    elseif not shadow_wings_enabled and self.wings[p:GetId()] then
        self.wings[p:GetId()]:Remove()
        self.wings[p:GetId()] = nil
    end
end

cWingManager = cWingManager()