class 'cProxAlarms'

function cProxAlarms:__init(args)

    self.c4s = {} -- [wno id] = cC4() 

    self.placing_c4 = false

    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    
    Network:Subscribe(var("items/StartProxPlacement"):get(), self, self.StartProxPlacement)

end

function cProxAlarms:StartProxPlacement()

    Events:Fire("build/StartObjectPlacement", {
        model = 'samsite.animated.eez/key036sam-d2.lod',
        offset = Vector3(0, 0, 0.125),
        angle = Angle(0, -math.pi / 2, 0),
        display_bb = true
    })

    self.place_subs = 
    {
        Events:Subscribe("ObjectPlacerGameRender", self, self.Render),
        Events:Subscribe("build/PlaceObject", self, self.PlaceObject),
        Events:Subscribe("build/CancelObjectPlacement", self, self.CancelObjectPlacement)
    }
    
    self.placing_alarm = true
end

function cProxAlarms:Render(args)

    if not self.placing_alarm then return end

    local angle = args.object:GetAngle() * Angle(0, math.pi / 2, 0)
    local start_ray_pos = args.object:GetPosition() + angle * Vector3(0, 0, 0)

    angle = angle * Angle(0, math.pi / 2, 0)

    local num_rays = 5
    for i = 1, num_rays do

        angle = angle * Angle(0, -math.pi / 6, 0)

        local ray = Physics:Raycast(start_ray_pos, angle * Vector3.Forward, 0, 4, false)
        local end_ray_pos = ray.position

        Render:DrawLine(
            start_ray_pos,
            end_ray_pos,
            Color(0, 0, 255, 255)
        )

        local angle2 = angle * Angle(math.pi / 2, 0, 0)
        for i = 1, 5 do

            angle2 = angle2 * Angle(-math.pi / 6, 0, 0)

            local ray = Physics:Raycast(start_ray_pos, angle2 * Vector3.Forward, 0, 10, false)
            local end_ray_pos = ray.position
    
            Render:DrawLine(
                start_ray_pos,
                end_ray_pos,
                Color(0, 0, 255, 255)
            )
        end


    end

end

function cProxAlarms:PlaceObject(args)
    if not self.placing_alarm then return end

    Network:Send("items/PlaceProx", {
        position = args.position,
        angle = args.angle
    })

    self:StopPlacement()
end

function cProxAlarms:CancelObjectPlacement()
    Network:Send("items/CancelProxPlacement")
    self:StopPlacement()
end

function cProxAlarms:StopPlacement()
    for k, v in pairs(self.place_subs) do
        Events:Unsubscribe(v)
    end

    self.place_subs = {}
    self.placing_alarm = false
end

function cProxAlarms:ProxExplode(args)

    -- TODO

end

function cProxAlarms:ModuleUnload()

end

cProxAlarms = cProxAlarms()