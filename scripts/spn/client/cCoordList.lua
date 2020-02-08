class 'CoordList'

function CoordList:__init()
	self.coords = {}
	self.saving = false
	
	Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
	Events:Subscribe("KeyUp", self, self.KeyUp)
	Events:Subscribe("Render", self, self.Render)
	
	Network:Subscribe("LoadCoords", self, self.LoadCoords)
end

function CoordList:LocalPlayerChat(args)
	if args.text == "/recordcoords" then
		self.saving = true
		self.coords = {}
		Chat:Print("Coordinate Recording Mode Activated", Color.Silver)
		return false
	elseif args.text == "/savecoords" then
		Network:Send("SaveCoords", self.coords)
		self.coords = {}
	elseif args.text == "/removeclosest" then
		self:RemoveClosest()
	elseif args.text == "/removeall" then
		self.coords = {}
	end
end

function CoordList:KeyUp(args)
	if self.saving and args.key == string.byte("4") then
		table.insert(self.coords, LocalPlayer:GetPosition() + Vector3(0, .25, 0))
	end
end

function CoordList:Render()
	for index, coord in pairs(self.coords) do
		local transform = Transform3()
		transform:Translate(coord)
		transform:Rotate(Angle(0, 0.5 * math.pi, 0))
		Render:SetTransform(transform)
		Render:FillCircle(Vector3.Zero, 1, Color.Magenta)
		Render:ResetTransform()
	end
end

function CoordList:RemoveClosest()
	local pos = LocalPlayer:GetPosition()
	local remove = nil
	local closest_dist = 999999
	
	for index, coord in pairs(self.coords) do
		if Vector3.Distance(pos, coord) < closest_dist then
			remove = index
			closest_dist = Vector3.Distance(pos, coord)
		end
	end
	
	if remove then
		self.coords[remove] = nil
	end
end

function CoordList:LoadCoords(t)
	self.coords = t
	self.saving = true
	Chat:Print("Coordinates Received - Coordinate Recording Mode Activated", Color.Silver)
end


CoordList = CoordList()