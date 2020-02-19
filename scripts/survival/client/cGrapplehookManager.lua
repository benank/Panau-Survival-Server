class 'cGrapplehookManager'

function cGrapplehookManager:__init()

	self.rechargeModifier = 1
	self.rechargeTime = 4
    self.charges = xor_cipher(1)
	self.charges_unencrypted = tonumber(xor_cipher(self.charges))
	self.max_charges = 3
	self.currentTime = self.rechargeTime -- Current cooldown time in seconds
	self.grappleVisualEnabled = true -- If the visual indicator is enabled or not for the grapple
	self.distanceHUDEnabled = false
	self.distance = 0
	self.timeout = Timer()

	self.recharge_color = Color(190, 190, 190)
	self.recharge_color_text = Color(0,0,0, 150)
	self.circle_size = Render.Size.x * 0.02
	self.circle_basepos = Vector2(self.circle_size * 1.5, Render.Size.y * 0.6 - self.circle_size / 2)
	self.circle = CircleBar(self.circle_basepos, self.circle_size, 
	{
		[1] = {max_amount = 100, amount = 25, color = self.recharge_color}
	})

	self.small_circle_pos = self.circle_basepos + Vector2(self.circle_size, self.circle_size) * 0.8
	self.small_circle_size = self.circle_size * 0.25
	self.text_size = self.small_circle_size * 1.5
	self.offset = Vector2(self.text_size * 0.125, self.text_size * 0.125)

	self.grapple_image = Image.Create(AssetLocation.Resource, "icon_Grapplehook")
	self.grapple_window = ImagePanel.Create()
	self.grapple_window:SetPosition(self.circle_basepos - Vector2(self.circle_size / 2, self.circle_size / 2))
	self.grapple_window:SetSize(Vector2(self.circle_size, self.circle_size))
	self.grapple_window:SetImage(self.grapple_image)
	self.grapple_window:SendToBack()

	self.upgrades = {[1] = 1.5, [2] = 2, [3] = 2.5, [4] = 3} -- How much faster it recharges with upgrades

	--self.grapple_red = Image.Create(AssetLocation.Resource, "Grapple_Red_IMG")
	--self.grapple_green = Image.Create(AssetLocation.Resource, "Grapple_Green_IMG")
	--self.grapple_blue = Image.Create(AssetLocation.Resource, "Grapple_Blue_IMG")
	
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("PreTick", self, self.PreTick)
	Events:Subscribe("ChangeGrappleRechargeTime", self, self.ChangeGrappleRechargeTime)

end

function cGrapplehookManager:ChangeGrappleRechargeTime(num_upgrades)
	if num_upgrades == 0 then
		self.rechargeModifier = 1
	else
		self.rechargeModifier = self.upgrades[num_upgrades]
	end
end

function cGrapplehookManager:PreTick(args)

	if self.charges_unencrypted < self.max_charges then

		self.currentTime = self.currentTime + args.delta * self.rechargeModifier

		if self.currentTime >= self.rechargeTime then

			local charges_unencrypted = tonumber(xor_cipher(self.charges))

			if charges_unencrypted >= self.max_charges then return end

			charges_unencrypted = charges_unencrypted + 1
			self.charges_unencrypted = charges_unencrypted
			self.charges = xor_cipher(charges_unencrypted)
			self.currentTime = 0
			LocalPlayer:SetValue("NumGrappleCharges", self.charges_unencrypted)

		end

		local percent = (self.charges_unencrypted == self.max_charges) 
		and 100
		or math.floor(self.currentTime * 100 / self.rechargeTime)

		self.circle.data[1].color = Color.FromHSV(120 * self.charges_unencrypted / self.max_charges, 0.85, 0.85)

		self.circle.data[1].amount = percent
		self.circle:Update()

	end

	
	local leftarmstate = LocalPlayer:GetLeftArmState()

	-- They hit something, now subtract a charge
	if self.firing and leftarmstate == AnimationState.LaSHookHit then
		self.firing = false
		
		if self.charges_unencrypted > 0 then -- If they can use it
			
			Events:Fire("FireGrapplehookHit")
			local charges_unencrypted = tonumber(xor_cipher(self.charges))

			if charges_unencrypted <= 0 or charges_unencrypted > self.max_charges then return false end

			self.timeout:Restart()

			charges_unencrypted = charges_unencrypted - 1
			self.charges_unencrypted = charges_unencrypted
			self.charges = xor_cipher(charges_unencrypted)
			LocalPlayer:SetValue("NumGrappleCharges", self.charges_unencrypted)

		end
		
	end

end

function cGrapplehookManager:LocalPlayerInput(args)

	local state = LocalPlayer:GetBaseState()
	local leftarmstate = LocalPlayer:GetLeftArmState()

	if args.input == Action.FireGrapple 
	and state ~= AnimationState.SRemoveGrapplinghook
	and state ~= AnimationState.SReelFlight
	and leftarmstate == AnimationState.LaSRaiseGrapple
	and self.timeout:GetMilliseconds() > 500 then -- If they are trying to grapple
		
		if self.charges_unencrypted > 0 then -- If they can use it
			self.firing = true
			Events:Fire("FireGrapplehook")
		else -- If they cannot use it
			return false -- Block the input
		end
		
	end

	if args.input == Action.FireGrapple 
	and state ~= AnimationState.SRemoveGrapplinghook
	and state ~= AnimationState.SReelFlight
	and self.timeout:GetMilliseconds() > 500 then -- If they are trying to grapple
		if self.charges_unencrypted > 0 then -- If they can use it
			Events:Fire("FireGrapplehookPre")
		else -- If they cannot use it
			return false -- Block the input
		end
		
	end

end

function cGrapplehookManager:Render()

    if Game:GetState() ~= GUIState.Game or not self.grappleVisualEnabled then
        self.grapple_window:Hide()
        return
    else
        self.grapple_window:Show()
    end
        
	self.circle:Render()
	Render:FillCircle(self.small_circle_pos, self.small_circle_size, self.recharge_color_text)
	Render:DrawText(
		self.small_circle_pos - Render:GetTextSize(tostring(self.charges_unencrypted), self.text_size) / 2, 
		tostring(self.charges_unencrypted), 
		Color.White,
		self.text_size)

end