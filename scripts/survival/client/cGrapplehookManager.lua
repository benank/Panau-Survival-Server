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

	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("PreTick", self, self.PreTick)

end

function cGrapplehookManager:PreTick(args)

	local leftarmstate = LocalPlayer:GetLeftArmState()

	-- They hit something, now subtract a charge
	if self.firing and leftarmstate == AnimationState.LaSHookHit then
		self.firing = false
		
		if self.charges_unencrypted > 0 then -- If they can use it
			
			Events:Fire("FireGrapplehookHit")
			self.timeout:Restart()

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
		
        self.firing = true
        Events:Fire("FireGrapplehook")
		
	end

	if args.input == Action.FireGrapple 
	and state ~= AnimationState.SRemoveGrapplinghook
	and state ~= AnimationState.SReelFlight
    and self.timeout:GetMilliseconds() > 500 then -- If they are trying to grapple
        
        Events:Fire("FireGrapplehookPre")
		
	end

end