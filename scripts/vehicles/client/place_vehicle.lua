class 'Place_Vehicle'
function Place_Vehicle:__init()
	self.maxplacedistance = 27
	self.angle = Angle(math.pi/2,0,0)
	self.timer = Timer() --delay for localplayerinput to be blocked
	self.speed = 100 --smaller number = faster rotation
	Events:Subscribe("V_PlaceVehicleFromItem", self, self.InitPlacing)
	Network:Subscribe("V_RefundVehicleCreate", self, self.Refund)
end
function Place_Vehicle:Refund(id)
	Events:Fire("AddToInventory", {add_item = self.iname, add_amount = 1})
end
function Place_Vehicle:InitPlacing(name)
	--called when the player clicks their vehicle item
	self.iname = name
	for i=1, #vNames do
		if string.find(vNames[i], name) then
			self.id = i
			self.name = vNames[i]
		end
	end
	if not self.id or not self.name then Chat:Print("Invalid vehicle name!", Color.Red) return end
	self.angle = Angle(math.pi/2,0,0)
	if not self.rendersub then
		self.rendersub = Events:Subscribe("Render", self, self.RenderText)
	end
	if not self.grendersub then
		self.grendersub = Events:Subscribe("GameRender", self, self.GameRenderBB)
	end
	if not self.inputsub then
		self.inputsub = Events:Subscribe("LocalPlayerInput", self, self.LPI)
	end
end
function Place_Vehicle:ExitPlacing()
	--subscribe events
	if self.rendersub then
		Events:Unsubscribe(self.rendersub)
	end
	if self.grendersub then
		Events:Unsubscribe(self.grendersub)
		self.grendersub = nil
	end
	self.rendersub = nil
	self.grendersub = nil
	self.timer:Restart()
end
function Place_Vehicle:LPI(args)
	--block firing
	if args.input == Action.FireRight or args.input == Action.FireLeft or args.input == Action.Fire
	or args.input == Action.Reload then
		return false
	end
	if self.timer:GetSeconds() > 1 and not self.rendersub then
		if self.inputsub then
			Events:Unsubscribe(self.inputsub)
			self.inputsub = nil
		end
	end
end
function Place_Vehicle:RenderText()
	local text = "Now placing "..self.name
	local text2 = "Left click to confirm, right click to cancel"
	local text3 = "Press R to rotate"
	local size = Render.Size.y / 20
	local pos = Render.Size/2 - Vector2(Render:GetTextSize(text, size).x/2,0) + Vector2(0,Render.Size.y/3)
	local pos2 = Render.Size/2 - Vector2(Render:GetTextSize(text2, size).x/2,0) + Vector2(0,Render.Size.y/3) + Vector2(0,Render:GetTextSize(text,size).y)
	local pos3 = Render.Size/2 - Vector2(Render:GetTextSize(text3, size).x/2,0) + Vector2(0,Render.Size.y/3)+ Vector2(0,Render:GetTextSize(text,size).y) + Vector2(0,Render:GetTextSize(text2,size).y)
	Render:DrawText(pos, text, Color.Red, size)
	Render:DrawText(pos2, text2, Color.Red, size)
	Render:DrawText(pos3, text3, Color.Red, size)
	if Key:IsDown(1) then
		if #vehGui:GetVehs() >= 10 then
			Chat:Print("Vehicle creation failed; you have too many vehicles already!", Color.Red)
			self:ExitPlacing()
			self.id = nil
			self.name = nil
			return
		end
		local result = Physics:Raycast(LocalPlayer:GetPosition() + Vector3(0,2,0), Camera:GetAngle() * Vector3.Forward, 0, self.maxplacedistance)
		local args = {}
		args.pos = result.position
		args.angle = self.angle
		args.id = self.id
		Network:Send("V_ClientVehicleCreate", args)
		self:ExitPlacing()
		self.id = nil
		self.name = nil
		if self.iname then
			Events:Fire("DeleteFromInventory", {sub_item = self.iname, sub_amount = 1})
		end
	elseif Key:IsDown(2) then
		Chat:Print("Vehicle placement cancelled.", Color.Red)
		self:ExitPlacing()
		self.id = nil
		self.name = nil
	end
	--renders the 2d text
end
function Place_Vehicle:GameRenderBB()
	--renders the bounding box
	if Key:IsDown(82) then -- r
		self.angle = Angle(math.pi/self.speed, 0,0) * self.angle
	end
	--NEED TO MAKE POSITION BASED ON ANGLE AND ANGLE FACE TOWARDS CENTER OR SOMETHING IDK
	local result = Physics:Raycast(LocalPlayer:GetPosition() + Vector3(0,2,0), Camera:GetAngle() * Vector3.Forward, 0, self.maxplacedistance)
	local color = Color.Blue
	local color2 = Color(0,255,255,10)
	local basepos = result.position + Vector3(0,0.1,0)
	local bx = self.angle * Vector3(BBxs[self.id].x,0,0)
	local by = self.angle * Vector3(0,BBxs[self.id].y,0)
	local bz = self.angle * Vector3(0,0,BBxs[self.id].z)
	local pos1a = basepos + (bx/2) + (bz/2)
	local pos1b = basepos + (bx/2) - (bz/2)
	local pos2a = basepos - (bx/2) + (bz/2)
	local pos2b = basepos - (bx/2) - (bz/2)
	--BOTTOM LINES
	Render:DrawLine(pos1a, pos1b, color)
	Render:DrawLine(pos2a, pos2b, color)
	Render:DrawLine(pos1a, pos2a, color)
	Render:DrawLine(pos1b, pos2b, color)
	--TOP LINES
	Render:DrawLine(pos1a + by, pos1b + by, color)
	Render:DrawLine(pos2a + by, pos2b + by, color)
	Render:DrawLine(pos1a + by, pos2a + by, color)
	Render:DrawLine(pos1b + by, pos2b + by, color)
	--SIDE LINES
	Render:DrawLine(pos1a, pos1a + by, color)
	Render:DrawLine(pos1b, pos1b + by, color)
	Render:DrawLine(pos2a, pos2a + by, color)
	Render:DrawLine(pos2b, pos2b + by, color)
	Render:ResetTransform()
	t = Transform3()
	t:Translate(basepos - (bx/2))
	t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
	t:Translate(-Vector3(Render:GetTextWidth("FRONT",50) / 250,0,0))
	Render:SetTransform(t)
	Render:DrawText(Vector3(0,-by.y/2,0), "FRONT", Color(0,200,0), 50, 0.01)
	Render:ResetTransform()
	t = Transform3()
	t:Translate(basepos + (bx/2))
	t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
	t:Translate(-Vector3(Render:GetTextWidth("BACK",50) / 250,0,0))
	Render:SetTransform(t)
	Render:DrawText(Vector3(0,-by.y/2,0), "BACK", Color(175,0,0), 50, 0.01)
	--FILL
	--[[Render:FillArea(pos1a, by - bx, color2)
	Render:FillArea(pos1b, by - bx, color2)
	-----------------------------------------------
	Render:ResetTransform()
	t = Transform3()
	t:Translate(pos1a)
	t:Rotate(Angle(-math.pi/2,0,0))
	Render:SetTransform(t)
	Render:FillArea(Vector3(0,0,0), by - Vector3(bz.z,0,0), color2)
	Render:ResetTransform()
	t = Transform3()
	t:Translate(pos2a)
	t:Rotate(Angle(-math.pi/2,0,0))
	Render:SetTransform(t)
	Render:FillArea(Vector3(0,0,0), by - Vector3(bz.z,0,0), color2)
	Render:ResetTransform()
	---------------------------------------------------
	t = Transform3()
	t:Translate(pos2a)
	t:Rotate(Angle(math.pi/2,math.pi/2,0))
	Render:SetTransform(t)
	Render:FillArea(Vector3(0,0,0), Vector3(bz.z,0,0) + Vector3(0,bx.x,0), color2)
	Render:ResetTransform()
	
	t = Transform3()
	t:Translate(pos2a+by)
	t:Rotate(Angle(math.pi/2,math.pi/2,0))
	Render:SetTransform(t)
	Render:FillArea(Vector3(0,0,0), Vector3(bz.z,0,0) + Vector3(0,bx.x,0), color2)
	Render:ResetTransform()--]]
	--YOU HAVE NO IDEA HOW HARD IT WAS TO DO THIS HOLY MOLY THIS SUCKED SO BAD
end
Place_Vehicle = Place_Vehicle()