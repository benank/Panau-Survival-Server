class 'QuestCompleteRender'

function QuestCompleteRender:__init()

	self.fades = {}
	self.particles = {}
	
	self.global_a_percent = 1
	self.time = 0
	self.max_time = 5
end

function QuestCompleteRender:Activate(args)

	if self.time > 0 then return end
	
	self.fades = {}
	self.global_a_percent = 0
	self.text = args.text
	self.max_time = args.time or 5
	self.c = args.color
	self:AddFades()
	self.sub = Events:Subscribe("Render", self, self.Render)
	
end

function QuestCompleteRender:AddParticle()

	table.insert(self.particles, {
		pos = Vector2(Render.Size.x / 2 + math.random(-Render.Size.x / 2, Render.Size.x / 2), Render.Size.y * 0.3),
		direction = Vector2(math.random()*math.random(-1,1), math.random() * 0.25 + 0.75),
		speed = 2,
		c = self.c
		})
			
end

function QuestCompleteRender:AddFades()

	table.insert(self.fades, Fade(Vector2(0, Render.Size.y * 0.2), Vector2(Render.Size.x, Render.Size.y * 0.1), self.c))
	table.insert(self.fades, Fade(Vector2(0, Render.Size.y * 0.3), Vector2(Render.Size.x, Render.Size.y * 0.25), self.c, math.pi))
	
end

function QuestCompleteRender:Render(args)
	
	if not self.fades[1].model or not self.fades[2].model then return end
	
	self.time = self.time + args.delta
	
	if self.time > self.max_time then
		self.global_a_percent = self.global_a_percent - args.delta * 2
		if self.global_a_percent < 0 then
			self.global_a_percent = 0
			self.time = 0
			Events:Unsubscribe(self.sub)
			self.sub = nil
			return
		end
	end
		


	if self.global_a_percent < 1 and self.time < self.max_time then
		self.global_a_percent = self.global_a_percent + args.delta * 2.5
		if self.global_a_percent > 1 then self.global_a_percent = 1 end
	end

	Render:FillArea(Vector2(), Render.Size, Color(0,0,0,120*self.global_a_percent))

	for i = 1, 3 do
		self:AddParticle()
	end
	local particle_size = Render.Size.x * 0.001
	for index, obj in pairs(self.particles) do
	
		local c = obj.c
		self.particles[index].pos = obj.pos + obj.direction * obj.speed
	
		Render:FillCircle(obj.pos, particle_size, Color(c.r,c.g,c.b,c.a*self.global_a_percent))
		
		
		c = Color(c.r,c.g,c.b,c.a - 2)
		if c.a > 0 and c.a - 2 > 0 then
			self.particles[index].c = c
		else
			self.particles[index] = nil
		end
		
	end

	local text = self.text
	local size = Render.Size.x * 0.05
	local shadow = Vector2(Render.Size.x * 0.001, Render.Size.x * 0.001)
	local spacing = Render.Size.x * 0.015
	local text_size = Render:GetTextSize(text, size)
	local start_pos = Vector2(Render.Size.x / 2 - spacing * 8 - text_size.x / 2, Render.Size.y * 0.2)
	
	local running_size = 0
	
	if self.global_a_percent < 1 then
		Render:SetClip(true, Vector2(0,0), Vector2(Render.Size.x, Render.Size.y * 0.3))
	end
	
	for i = 1, text:len() do
		local letter = text:sub(i,i)
		local text_size = Render:GetTextSize(letter, size)
		local pos = start_pos + Vector2(running_size,0)
		if self.global_a_percent < 1 and self.time < self.max_time then
			pos = Vector2(pos.x, pos.y + Render.Size.y * 0.1 - Render.Size.y * 0.1 * self.global_a_percent)
		--elseif self.global_a_percent < 1 and self.time > self.max_time then
			--pos = Vector2(pos.x, pos.y + Render.Size.y * 0.1 - Render.Size.y * 0.1 * self.global_a_percent)
		end
		Render:DrawText(pos + shadow, letter, Color(0,0,0,255*self.global_a_percent), size)
		Render:DrawText(pos, letter, Color(self.c.r,self.c.g,self.c.b,255*self.global_a_percent), size)
		Render:DrawText(pos + shadow, letter, Color(0,0,0,100*self.global_a_percent), size)
		running_size = running_size + text_size.x + spacing
	end
	
	Render:SetClip(false)

	for index, fade in ipairs(self.fades) do
		if self.global_a_percent < 1 then
			fade:SetAlphaPercent(self.global_a_percent)
		end
		fade:Render(args)
	end
	
end

QuestCompleteRender = QuestCompleteRender()