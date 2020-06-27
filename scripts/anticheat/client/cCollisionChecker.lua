class 'cCollisionChecker'

function cCollisionChecker:__init()

    self.strikes = var(0)
    self.max_strikes = 10

    self.object = ClientStaticObject.Create({
        position = LocalPlayer:GetPosition(),
        angle = Angle(),
        model = ' ',
        collision = '34x09.nlz/go003_lod1-a_col.pfx'
    })

    self.timer = Timer()

    Events:Subscribe(var("Render"):get(), self, self.Render)
end

function cCollisionChecker:Render(args)
    if not IsValid(self.object) then return end

    local basepos = Camera:GetPosition() + Vector3(0, 300, 0)

    self.object:SetPosition(basepos - Vector3(0, 1.5, 0))

    local ray = Physics:Raycast(basepos, Vector3.Down, 0, 3)

    if ray.distance == 3 and self.timer:GetSeconds() > 1 and not LocalPlayer:GetValue("Loading") then
        self.timer:Restart()
        self.strikes:set(tonumber(self.strikes:get()) + 1)
    end

    if tonumber(self.strikes:get()) >= self.max_strikes and not IsAdmin(LocalPlayer) then
        self.timer:Restart()
        Network:Send(var("anticheat/collisioncheck"):get())
        self.strikes:set(0)
    end

end

cCollisionChecker()