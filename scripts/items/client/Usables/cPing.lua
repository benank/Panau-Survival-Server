class 'cPing'

function cPing:__init()

    self.speed_mod = 4
    self.num_circles = 3

    Network:Subscribe("Items/PingSound", self, self.PingSound)
    Network:Subscribe("Items/Ping", self, self.Ping)
    Events:Subscribe("drones/PingUsedResponse", self, self.Ping)

end

function cPing:Ping(args)

    -- Get nearby drones
    if not args.is_drone then
        args.position = LocalPlayer:GetPosition()
        Events:Fire("items/PingUsed", args)
        return
    end

    self.timer = Timer()
    self.range = args.range

    self.position = LocalPlayer:GetPosition()

    self.nearby_players = args.nearby_players

    for id, data in pairs(self.nearby_players) do
        data.id = id

        local delay = data.position:Distance(self.position) * self.speed_mod

        Timer.SetTimeout(delay, function()
            if self.nearby_players[id] then
                cPingPlayerIndicators:AddPlayer(self.nearby_players[id])
            end
        end)

    end

    if not self.render then
        self.render = Events:Subscribe("GameRender", self, self.GameRender)
    end

end

function cPing:GameRender(args)

    local t = Transform3()
    t:Translate(self.position):Rotate(Angle(0, math.pi / 2, 0))
    Render:SetTransform(t)

    local size = self.timer:GetMilliseconds() / self.speed_mod

    for i = 1, self.num_circles do
        Render:DrawCircle(Vector3.Zero, size + i * 5, Color(255, 255, 0, 255 - math.min(1, size / self.range) * 255))
    end

    if size > self.range then
        Events:Unsubscribe(self.render)
        self.render = nil
    end
 
end

function cPing:PingSound(args)

    if IsValid(self.sound) then
        self.sound:Remove()
        Timer.Clear(self.timeout)
    end

    self.sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 31,
        sound_id = 15,
        position = args.position,
        angle = Angle()
    })

    self.sound:SetParameter(0,0)
    self.sound:SetParameter(1,1)

    self.timeout = Timer.SetTimeout(args.range * self.speed_mod, function()
        self.sound:Remove()
    end)

end

cPing = cPing()