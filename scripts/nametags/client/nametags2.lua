class 'Nametags2'
function Nametags2:__init()

	self.nearplayers = {}
	self.nearvehs = {}
	self.selfenabled = false --enable for your own nametag
	self.vehsenabled = false --enable for car tags lol
    Events:Subscribe("SecondTick", self, self.FindNear)
    
end

function Nametags2:FindNear()

	for p in Client:GetStreamedPlayers() do
		self.nearplayers[p:GetId()] = p
    end
    
	for id, p in pairs(self.nearplayers) do
		if not IsValid(p) then
			self.nearplayers[id] = nil
		end
    end
    
	if not self.rendersub and (table.count(self.nearplayers) > 0 or self.selfenabled) then
		self.rendersub = Events:Subscribe("GameRenderOpaque", self, self.Render)
	elseif self.rendersub and (table.count(self.nearplayers) <= 0 and not self.selfenabled) then
		Events:Unsubscribe(self.rendersub)
		self.rendersub = nil
	end
end
function Nametags2:Render()
    
	for id, player in pairs(self.nearplayers) do
		if not IsValid(player) then
			self.nearplayers[id] = nil
			return
		end
		DrawNameTag(player)
	end
	
	if self.selfenabled then
		if LocalPlayer:GetBaseState() == AnimationState.SCrouch or
		LocalPlayer:GetBaseState() == AnimationState.SCrouchWalk or
		LocalPlayer:GetBaseState() == AnimationState.SDownToCrouch or
		LocalPlayer:GetBaseState() == AnimationState.SUpFromCrouch or
		LocalPlayer:GetBaseState() == AnimationState.SCrouching then return end
		DrawNameTag(LocalPlayer)
	end
end

function DrawNameTag(player)
    
	local pos2 = Camera:GetPosition()
	local name = player:GetName()
	local special = false
	local tagname = ""
	local spcolor = Color(255,255,255)
	local lvl = player:GetValue("Level")
    
	if player:GetValue("NT_TagName") then
		tagname = tostring(player:GetValue("NT_TagName"))
		spcolor = player:GetValue("NT_TagColor")
		special = true
    end
    
    local tcolor = player:GetColor()
    
	local pos = player:GetBonePosition("ragdoll_Head") + Vector3(0,0.35,0)

	local pos5 = Render:WorldToScreen(Vector3(0,0,0))
	local dist = Vector3.Distance(pos, pos2)
    local size = 50 - (dist / 10)
    
	if dist > 75 then
	    size = 0
    end
    
	t = Transform3()
	t:Translate(pos)
    t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
    
	if special then
		t:Translate(-Vector3((Render:GetTextWidth(name) / 250) - (Render:GetTextWidth(tagname.." ") / 250),0,0))
	else
		t:Translate(-Vector3(Render:GetTextWidth(name) / 250,0,0))
    end
    
    Render:SetTransform(t)
    
	if special then
		Render:DrawText(Vector3(0.005,0.005,0.005), name, Color(0,0,0), size, 0.0025)
		Render:DrawText(Vector3(0,0,0), name, tcolor, size, 0.0025)
		Render:ResetTransform()
		t = Transform3()
		t:Translate(pos)
		t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
		t:Translate(-Vector3((Render:GetTextWidth(name) / 250) + (Render:GetTextWidth(tagname.." ") / 250),0,0))
		Render:SetTransform(t)
		Render:DrawText(Vector3(0.005,0.005,0.005), tagname, Color.Black, size, 0.0025)
        Render:DrawText(Vector3(0,0,0), tagname, spcolor, size, 0.0025)
        
		if lvl then
			lvl = "Level "..tostring(lvl)
			Render:ResetTransform()
			t = Transform3()
			t:Translate(pos)
			t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
			t:Translate(-Vector3(Render:GetTextWidth(lvl) / 250,0,0))
			Render:SetTransform(t)
			Render:DrawText(Vector3(0.005,-0.105,0.005), lvl, Color.Black, size, 0.0025)
			Render:DrawText(Vector3(0,-0.11,0), lvl, Color.Yellow, size, 0.0025)
        end
        
	else
		Render:DrawText(Vector3(0.005,0.005,0.005), name, Color(0,0,0), size, 0.0025)
		Render:DrawText(Vector3(0,0,0), name, tcolor, size, 0.0025)
		if lvl then
			lvl = "Level "..tostring(lvl)
			Render:ResetTransform()
			t = Transform3()
			t:Translate(pos)
			t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
			t:Translate(-Vector3(Render:GetTextWidth(lvl) / 250,0,0))
			Render:SetTransform(t)
			Render:DrawText(Vector3(0.005,-0.105,0.005), lvl, Color.Black, size, 0.0025)
			Render:DrawText(Vector3(0,-0.11,0), lvl, Color.Yellow, size, 0.0025)
        end
        
    end
    
	Render:ResetTransform()
end

--Nametags2 = Nametags2()