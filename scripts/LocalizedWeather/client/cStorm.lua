class 'cStorm'

function cStorm:__init(wno)

    self.wno = wno
    self.pos = wno:GetPosition();
    --self.pos.y = 0
    self.color = Color(11, 16, 20, 16)
    self.alpha = 16

    self.global_alpha = 0 -- Modifier to fade in storm when it first appears

    self.models = {}

    self.radius = wno:GetValue("radius")
    self.velocity = wno:GetValue("velocity")
    self.layers = 80
    self.width = 300 -- Storm layers occur over this distance
    self.roundness = 20 -- Bigger number = rounder cylinder, must be at least 4
    self.height = 2000 -- Height of cylinder
    self.delta = math.random(0, 10);
    self.in_storm = false;
    self.storm_max_alpha = 160 -- Max alpha inside storm

    self:CreateModel()

    -- TODO remove event subscriptions when storm subsides
	Events:Subscribe("ShapeTriggerEnter", self, self.STEnter)
	Events:Subscribe("ShapeTriggerExit", self, self.STExit)
    Events:Subscribe("ModuleUnload", self, self.Unload)
    

end

function cStorm:Unload()

    self.trigger:Remove()

end


function cStorm:STEnter(args)

	if args.trigger:GetId() == self.trigger:GetId() then
	
		if args.entity == LocalPlayer then
		
			--Network:Send("PlayerEnterStorm", self.wno:GetId())
            Network:Send("PlayerEnterStorm")
            self.in_storm = true
			
		end
		
	end
	
end

function cStorm:STExit(args)

	if args.trigger:GetId() == self.trigger:GetId() then
	
		if args.entity == LocalPlayer then
		
			--Network:Send("PlayerExitStorm", self.wno:GetId())
            Network:Send("PlayerExitStorm")
            self.in_storm = false
			
		end
		
	end
	
end


function cStorm:CreateModel()

    for i = 1, self.layers do
        
        local vertices = {}

        local radius = (self.radius - (self.width - self.width * (i / self.layers)))

        for j = 0, self.roundness do 

            local color = self.color

            local x = math.cos((j / self.roundness)  * math.pi * 2 ) * radius
            local z = math.sin((j / self.roundness)  * math.pi * 2 ) * radius

            table.insert( vertices, Vertex(--self.pos + 
                Vector3(
                    x,
                    0, 
                    z), 
                    color))

            table.insert( vertices, Vertex(--self.pos + 
                Vector3(
                    x,
                    self.height, 
                    z), 
                    color))

        end
    
        local model = Model.Create(vertices)
        model:SetTopology(Topology.TriangleStrip)

        table.insert( self.models, {model = model, radius = radius})
        
    end

    -- TODO make multiple triggers to create a "cylinder"
	self.trigger = ShapeTrigger.Create({
		position = self.pos,
		angle = Angle(0,0,0),
		components = {
			{
				type = TriggerType.Sphere,
				size = Vector3(self.radius,self.radius,self.radius),
				position = Vector3()
			}
		},
		trigger_player = true,
		trigger_player_in_vehicle = true,
		trigger_vehicle = false,
		trigger_npc = false
		})
    
	

end

function cStorm:GameRender(args)


    local cam_pos = Camera:GetPosition()
    local p1 = cam_pos + (Camera:GetAngle() * (Vector3.Forward * 0.52))
    local dist_to_center = (p1 - self.pos):Length()

    local t = Transform3()
    t:Translate(self.pos):Rotate(Angle(self.delta, 0, 0))
    Render:SetTransform(t)
    --self.delta = self.delta + 0.05

    for k,v in pairs(self.models) do

        local alpha = 255

        local dist_to_edge = dist_to_center - self.models[k].radius
        local fade_dist = 20

        if dist_to_edge < fade_dist then
            alpha = alpha * ((dist_to_edge * 1.5) / fade_dist)
        end

        if dist_to_edge < fade_dist * 1.5 then
            alpha = 0
        end


            
        self.models[k].model:SetTextureAlpha(alpha * self.global_alpha)

        if alpha > 0 then

            self.models[k].model:Draw()

        end

    end

    if self.in_storm then

        local t = Transform3()
        t:Translate(p1)
        t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
        Render:SetTransform(t)
        local dist = 1 - math.min((LocalPlayer:GetPosition() - self.pos):Length() / self.radius, 1)
        local alpha = math.min(self.storm_max_alpha * dist * 7, self.storm_max_alpha)

        local color = Color(self.color.r,self.color.g,self.color.b,alpha)
        Render:FillArea(Vector3(0,0,0), Vector3(100,100,100), color)
        Render:FillArea(Vector3(0,0,0), Vector3(-100,-100,-100), color)
        Render:FillArea(Vector3(0,0,0), Vector3(100,-100,-100), color)
        Render:FillArea(Vector3(0,0,0), Vector3(-100,100,100), color)
        Render:ResetTransform()

    end

    if self.global_alpha < 1 then
        self.global_alpha = self.global_alpha + 0.05 * args.delta
    else
        self.global_alpha = 1
    end


    self.pos = self.pos + self.velocity * args.delta

    self.trigger:SetPosition(self.pos)

    Render:ResetTransform()

end

function cStorm:Dissipate()

    self.trigger:Remove()

end