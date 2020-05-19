class 'Wings'

function Wings:__init(p)

	self.player = p
	self.objName = "models/wing.obj"
	self.texture = Image.Create(AssetLocation.Resource, "WingTexture_IMG")
	self.model = nil
	self.timer = Timer()
	self.size = 2
	self.takingOff = false --if we want takeoff animation

	self.flapTime = 5 - (math.abs((self.player:GetAngle() * self.player:GetLinearVelocity()).z) / 10)
	if self.flapTime < 0.25 then self.flapTime = 0.25 end
	if self.flapTime > 5 then self.flapTime = 5 end
	
	OBJLoader.Request({path = self.objName}, self, self.ReceiveModel)
	self.renderSub = Events:Subscribe("GameRender", self, self.Render)

end

function Wings:SetPosition(position)
	self.position = position
end

function Wings:SetAnimation(anim)
	self.animation = anim
	self.timer:Restart()
end

function Wings:Remove()
	self.player = nil
	self.objName = nil
	self.texture = nil
	self.model = nil
	self.timer = nil
	self.size = nil
	self.takingOff = nil
	self.flapTime = nil
	Events:Unsubscribe(self.renderSub)
	self.renderSub = nil
	self = nil
end

function Wings:ReceiveModel(model, name)
	self.model = model
	self.model:SetTexture(self.texture)
	self.model:SetTextureAlpha(150)
	self.model:SetColor(Color(0, 0, 0, 150))
end

function Wings:GetFlapTime()

	self.flapTime = 5 - (math.abs((self.player:GetAngle() * self.player:GetLinearVelocity()).z) / 10)
	if self.flapTime < 0.25 then self.flapTime = 0.25 end
	if self.flapTime > 5 then self.flapTime = 5 end
	
end

function Wings:GetFlapAngle()
	local seconds = self.timer:GetSeconds()
	if seconds >= self.flapTime and seconds < self.flapTime * 2 then
		seconds = self.flapTime - (seconds - self.flapTime)
	elseif seconds >= self.flapTime * 2 then
		seconds = 0
		self:GetFlapTime()
		self.timer:Restart()
	end
	--print(self.flapTime)
	local divisor = 2.4 --increase to have them meet farther at the top, decrease for opposite
	return seconds * math.pi / self.flapTime / divisor
end

function Wings:Render()

	--LEFT WING
	if IsValid(self.player) then
		local transform = Transform3()
		local angleAdj = Angle(0,-0.2,0)
		local add = self.player:GetBoneAngle("ragdoll_Spine1") * Vector3(0,-0.65,0.0)
		transform:Translate(self.player:GetBonePosition("ragdoll_Spine1") + add)
		transform:Scale(self.size)
		transform:Rotate(self.player:GetBoneAngle("ragdoll_Spine1") * Angle(math.pi,0,0) * angleAdj)
		if self.animation == "TAKEOFF" then
			--transform:Rotate(Angle(self:GetFlapAngle(),0,0))
		else
			transform:Rotate(Angle(self:GetFlapAngle(),0,0))
		end
		Render:SetTransform(transform)
		
		if self.model then
			self.model:Draw()
		end
		
		Render:ResetTransform()
		--RIGHT WING
		local transform = Transform3()
		transform:Translate(self.player:GetBonePosition("ragdoll_Spine1") + add)
		transform:Scale(-self.size)
		transform:Rotate(self.player:GetBoneAngle("ragdoll_Spine1") * Angle(math.pi,math.pi,0) * angleAdj)
		if self.animation == "TAKEOFF" then
			--transform:Rotate(Angle(self:GetFlapAngle(),0,0))
		else
			transform:Rotate(Angle(self:GetFlapAngle(),0,0))
		end
		Render:SetTransform(transform)
		
		if self.model then
			self.model:Draw()
		end
	
		Render:ResetTransform()
	end
	
end