class 'Nametags2'
function Nametags2:__init()
	self.nearplayers = {}
	self.nearvehs = {}
	self.selfenabled = false --enable for your own nametag
	self.vehsenabled = false --enable for car tags lol
	Events:Subscribe("SecondTick", self, self.FindNear)
end
function AddHelp()
    Events:Fire( "HelpAddItem",
        {
            name = "Nametags",
            text = 
                "Some players will have special tags with their names, such as [Admin], [Mod], or "..
                "[Beta] for example.  This verifies that these people are actually what the tag says, " ..
                "so if someone is attempting to impersonate an admin but does not have a RED [Admin] tag, "..
				"you will know they are not actually an admin.  Some tags are achieved by being part "..
				"of certain events, such as the [Beta] tag.  Remember that these tags always have special colors."..
				"\n\nYou can find more info about tags at: "..
				"\nhttp://fallen-civilization.wikia.com/wiki/Tags"
        } )
end

function RemoveHelp()
    Events:Fire( "HelpRemoveItem",
        {
            name = "Nametags"
        } )
end

Events:Subscribe("ModulesLoad", AddHelp)
Events:Subscribe("ModuleUnload", RemoveHelp)
function Nametags2:FindNear()
	for p in Client:GetStreamedPlayers() do
		self.nearplayers[p:GetId()] = p
	end
	for id, p in pairs(self.nearplayers) do
		if not IsValid(p) then
			self.nearplayers[id] = nil
		end
	end
	if self.vehsenabled then
		for v in Client:GetVehicles() do
			self.nearvehs[v:GetId()] = v
		end
		for id, p in pairs(self.nearvehs) do
			if not IsValid(p) then
				self.nearvehs[id] = nil
			end
		end
		if not self.rendersub and (table.count(self.nearvehs) > 0) then
			self.rendersub = Events:Subscribe("GameRenderOpaque", self, self.Render)
		elseif self.rendersub and (table.count(self.nearvehs) <= 0) then
			Events:Unsubscribe(self.rendersub)
			self.rendersub = nil
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
	Render:SetFont(AssetLocation.SystemFont, "Calibri")
	for id, player in pairs(self.nearplayers) do
		if not IsValid(player) then
			self.nearplayers[id] = nil
			return
		end
		DrawNameTag(player)
	end
	
	for id, v in pairs(self.nearvehs) do
		if not IsValid(v) then
			self.nearvehs[id] = nil
			return
		end
		DrawNameTag(v, 1)
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
function CheckSocial(p, str)
	if p:GetValue(str) and string.len(tostring(p:GetValue(str))) > 3 then
		return tostring(p:GetValue(str))
	else
		return false
	end
end
function DrawNameTag(player, v)
	if CheckSocial(player, "SOCIAL_Disguise") then return end
	local pos2 = Camera:GetPosition()
	local name = player:GetName()
	local special = false
	local tagname = ""
	local spcolor = Color(255,255,255)
	local lvl = player:GetValue("Level")
	local faction = player:GetValue("Faction"), ""
	if not v and player:GetValue("NT_TagName") then
		tagname = tostring(player:GetValue("NT_TagName"))
		spcolor = player:GetValue("NT_TagColor")
		special = true
	end
	local tcolor = Color(255,255,255)
	if not v then
		tcolor = player:GetColor()
	end
	local pos
	if v then
		local one,two = player:GetBoundingBox()
		local addy = math.abs(one.y-two.y)
		--add = Vector3(0,add[1].y,0)
		pos = player:GetPosition() + Vector3(0,addy,0) + Vector3(0,0.5,0)
	else
		pos = player:GetBonePosition("ragdoll_Head") + Vector3(0,0.35,0)
	end
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
		if string.len(tostring(faction)) > 1 and faction ~= nil then
			faction = "Faction: "..tostring(faction)
			Render:ResetTransform()
			t = Transform3()
			t:Translate(pos)
			t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
			t:Translate(-Vector3(Render:GetTextWidth(faction) / 250,0,0))
			Render:SetTransform(t)
			Render:DrawText(Vector3(0.005,0.105,0.005), faction, Color.Black, size, 0.0025)
			Render:DrawText(Vector3(0,0.11,0), faction, Color.Green, size, 0.0025)
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
		if string.len(tostring(faction)) > 1 and faction ~= nil then
			faction = "Faction: "..tostring(faction)
			Render:ResetTransform()
			t = Transform3()
			t:Translate(pos)
			t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
			t:Translate(-Vector3(Render:GetTextWidth(faction) / 250,0,0))
			Render:SetTransform(t)
			Render:DrawText(Vector3(0.005,0.105,0.005), faction, Color.Black, size, 0.0025)
			Render:DrawText(Vector3(0,0.11,0), faction, Color.Green, size, 0.0025)
		end
	end
	Render:ResetTransform()
end
Nametags2 = Nametags2()