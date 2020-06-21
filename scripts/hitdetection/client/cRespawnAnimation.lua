class 'cRespawnAnimation'

function cRespawnAnimation:__init()

    self.time_to_respawn = 30 -- 30 seconds to respawn

    self.fx = {} -- Both flames and skull fx

    self.num_skulls = 30

    self.non_interrupt_actions = 
    {
        [Action.LookDown] = true,
        [Action.LookLeft] = true,
        [Action.LookRight] = true,
        [Action.LookUp] = true,
        [Action.HeliTurnLeft] = true,
        [Action.HeliTurnRight] = true,
    }

    Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
    Events:Subscribe("ModuleUnload", self, self.Cancel)

end

function cRespawnAnimation:Cancel()

    if not self.respawning then return end
    
    self.respawning = false
    self.respawn_timer = nil

    self.render = Events:Unsubscribe(self.render)
    self.lpi = Events:Unsubscribe(self.lpi)

    for _, data in pairs(self.fx) do
        data.object:Remove()
        data.effect:Remove()
    end

    self.light = self.light:Remove()

    self.fx = {}

end

function cRespawnAnimation:Render(args)

    -- Render: RESPAWNING IN 30 SECONDS, MOVE TO CANCEL
    local text = string.format("RESPAWNING IN %.0f SECONDS", self.time_to_respawn - self.respawn_timer:GetSeconds())
    local size = Render.Size.y * 0.05

    local text_size = Render:GetTextSize(text, size)

    local pos = Vector2(Render.Size.x / 2 - text_size.x / 2, Render.Size.y * 0.25 - text_size.y / 2)

    Render:DrawText(pos + Vector2(2,2), text, Color.Black, size)
    Render:DrawText(pos, text, Color.Red, size)

    if self.respawn_timer:GetSeconds() >= self.time_to_respawn then
        self:Cancel()
        Network:Send(var("Hitdetection/Respawn"):get())
    end

end

function cRespawnAnimation:LocalPlayerInput(args)

    if not self.non_interrupt_actions[args.input] then
        self:Cancel()
    end

end

function cRespawnAnimation:CreateSkulls()

    -- Create skulls and fire fx
    local radius = 8
    local coords = self:GetCircleCoordinates(Vector2.Zero, radius, self.num_skulls, 0, 1)

    local player_pos = LocalPlayer:GetPosition()

    for _, point in pairs(coords) do

        local pos = player_pos + Vector3(point.x, 1, point.y)
        local angle = Angle.FromVectors(Vector3.Forward, pos - player_pos)

        local data = {}
        data.effect = ClientParticleSystem.Create(AssetLocation.Game, {
            position = pos,
            angle = Angle(),
            path = "fire_lave_small_05.psmb"
        })

        data.object = ClientStaticObject.Create({
            position = pos,
            angle = angle,
            model = "32x34.flz/key040_1-part_d.lod"
        })

        table.insert(self.fx, data)
    end

    self.light = ClientLight.Create({
        position = player_pos + Vector3.Up * 2,
        radius = radius * 2,
        color = Color.Red,
        multiplier = 10
    })

end

function cRespawnAnimation:GetCircleCoordinates(position, radius, resolution, start_percent, final_percent)

    local coords = {}

    for theta = 0 + math.pi * 2 * (start_percent or 0), 2 * math.pi * (final_percent or 1), 2 * math.pi / resolution do
        local x = radius * math.sin(theta)
        local y = radius * math.cos(theta)
        local point = position - Vector2(-x,y)
        table.insert(coords, point)
    end

    return coords

end

function cRespawnAnimation:LocalPlayerChat(args)

    if args.text == "/respawn" then

        local speed = math.floor(math.abs((-LocalPlayer:GetAngle() * LocalPlayer:GetLinearVelocity()).z))

        if LocalPlayer:InVehicle() then
            Chat:Print("You must exit your vehicle to respawn.", Color.Red)
            return
        elseif speed > 0 then
            Chat:Print("You must stand still to respawn.", Color.Red)
            return
        elseif LocalPlayer:GetState() ~= PlayerState.OnFoot then
            Chat:Print("You must be standing to respawn.", Color.Red)
            return
        end

        self.respawning = true
        self.respawn_timer = Timer()

        if not self.render then
            self.render = Events:Subscribe("Render", self, self.Render)
            self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)

            self:CreateSkulls()
        end

        return false

    end

end

cRespawnAnimation = cRespawnAnimation()