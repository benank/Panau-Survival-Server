class 'StreakBone'

function StreakBone:__init(player, bone1, bone2, c, t, gravity)

	self.player = player
	self.bone1 = bone1
    self.bone2 = bone2
    self.alpha = 150
    self.color = Color(c.r, c.g, c.b, self.alpha)
	self.vertexes = {}
	self.t = t or 1
	self.gravity = gravity or Vector3()
	
end

function StreakBone:Remove()

	self.player = nil
	self.bone1 = nil
	self.bone2 = nil
	self.color = nil
	self.vertexes = nil
	self.model = nil
	self = nil
	
end

function StreakBone:Render(args)

	if not IsValid(self.player) then return end

	table.insert(self.vertexes, Vertex(self.player:GetBonePosition(self.bone1), self.color))
	table.insert(self.vertexes, Vertex(self.player:GetBonePosition(self.bone2), self.color))
	
	self.model = Model.Create(self.vertexes)
	self.model:SetTopology(Topology.TriangleStrip)
	
	
	if self.model then
		self.model:Draw()
	end
	
	local newvertexes = {}
	
	for index, v in pairs(self.vertexes) do
    
        local alpha = math.min(math.max(v.color.a - args.delta * 255 * 1 / self.t, 0), self.alpha)
		if alpha > 0 then
			table.insert(newvertexes, Vertex(v.position + self.gravity, Color(v.color.r, v.color.g, v.color.b, alpha)))
		end
		
	end
	
	self.vertexes = newvertexes
	
end