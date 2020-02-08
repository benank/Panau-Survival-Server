class 'cLightningStrike'

function cLightningStrike:__init(pos)


    self.radius = 1
    self.layers = 100
    self.width = 1 -- Storm layers occur over this distance
    self.roundness = 300 -- Bigger number = rounder cylinder, must be at least 4
    self.height = 0.1 -- Height of cylinder
    self.delta = 0;

    self.render = Events:Subscribe("GameRender", self, self.GameRender)

end

function cLightningStrike:GenerateLightning()


    for i = 1, self.layers do
        
        local vertices = {}

        for j = 0, self.roundness do 

            local color = Color.White
            --local color = self.color

            local x = (math.cos((j / self.roundness) * math.pi * 2 ) * self.radius - (self.width * (i / self.layers))) * math.sin(i / self.layers * math.pi)
            local z = (math.sin((j / self.roundness) * math.pi * 2 ) * self.radius - (self.width * (i / self.layers))) * math.sin(i / self.layers * math.pi)

            table.insert( vertices, Vertex(--self.pos + 
                Vector3(
                    x,
                    self.height * (i - 1), 
                    z), 
                    color))

            table.insert( vertices, Vertex(--self.pos + 
                Vector3(
                    x,
                    self.height * i, 
                    z), 
                    color))

        end
    
        local model = Model.Create(vertices)
        model:SetTopology(Topology.TriangleStrip)

        table.insert( self.models, model)
        
    end
	

end

function cLightningStrike:GameRender(args)



end