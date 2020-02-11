class 'cSurvivalHUD'

function cSurvivalHUD:__init()

    -- TODO enable dynamic circle generation on upper level for parachute/wingsuit dura

	self.circle_size = Render.Size.x * 0.02
    self.circle_basepos = Vector2(Render.Size.x - self.circle_size * 8.5, self.circle_size * 1.5)
    
    self.images = {}
    self:LoadIcons()

    self.circles = {}
    self:CreateCircles()
    
    self.windows = {}
    self:CreateIconWindows()

    Network:Subscribe("Survival/Update", self, self.Update)

end

function cSurvivalHUD:Update(data)

    for k,v in pairs(self.circles) do

        v.data[1].amount = data[k]
        v:Update()

        v.visible = not (k == "radiation" and tonumber(data[k]) <= 0.01)

    end

end

function cSurvivalHUD:CreateIconWindows()

    for k,v in pairs(self.images) do

        local imagePanel = ImagePanel.Create()
        imagePanel:SetPosition(self.circles[k].pos - Vector2(self.circle_size / 2, self.circle_size / 2))
        imagePanel:SetSize(Vector2(self.circle_size, self.circle_size))
        imagePanel:SetImage(v)
        imagePanel:SendToBack()

        self.windows[k] = imagePanel

    end


end

function cSurvivalHUD:LoadIcons()

    self.images.hunger = Image.Create(AssetLocation.Resource, "icon_Hunger")
    self.images.thirst = Image.Create(AssetLocation.Resource, "icon_Thirst")
    --self.images.Energy = Image.Create(AssetLocation.Resource, "icon_Energy")
    self.images.radiation = Image.Create(AssetLocation.Resource, "icon_Radiation")

end

function cSurvivalHUD:Render(args)

    if Game:GetState() ~= GUIState.Game then
        for k,v in pairs(self.windows) do v:Hide() end
        return
    else
        for k,v in pairs(self.windows) do if self.circles[k].visible then v:Show() else v:Hide() end end
    end
        
	for name, circle in pairs(self.circles) do

        circle:Render(args)

    end
    

end

function cSurvivalHUD:CreateCircles()

	self.circles.hunger = CircleBar(self.circle_basepos, self.circle_size, 
	{
		[1] = {max_amount = 100, amount = 450, color = Color(184,18,18)}
	})

	self.circles.thirst = CircleBar(self.circle_basepos - Vector2(self.circle_size * 2.25,0), self.circle_size, 
	{
		[1] = {max_amount = 100, amount = 65, color = Color(16,124,179)}
	})

	--[[self.circles.Energy = CircleBar(self.circle_basepos - Vector2(self.circle_size * 4.5,0), self.circle_size, 
	{
		[1] = {max_amount = 100, amount = 25, color = Color(224,123,20)}
	})--]]

	self.circles.radiation = CircleBar(self.circle_basepos - Vector2(self.circle_size * 4.5,0), self.circle_size, 
	{
		[1] = {max_amount = 100, amount = 10, color = Color(235,217,19)}
	})

end