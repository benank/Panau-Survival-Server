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
    Events:Subscribe(var("LocalPlayerDeath"):get(), self, self.LocalPlayerDeath)
end

function cCollisionChecker:LocalPlayerDeath()
    self.strikes:set(0)
end

function cCollisionChecker:Render(args)
    if not IsValid(self.object) then return end

    local basepos = Camera:GetPosition() + Vector3(0, 300, 0)

    self.object:SetPosition(basepos - Vector3(0, 2, 0))

    local ray = Physics:Raycast(basepos, Vector3.Down, 0, 5)

    if ray.distance == 5 and self.timer:GetSeconds() > 1 and not LocalPlayer:GetValue("Loading") and LocalPlayer:GetHealth() > 0 then
        self.timer:Restart()
        self.strikes:set(tonumber(self.strikes:get()) + 1)

        self.object:Remove()
            
        self.object = ClientStaticObject.Create({
            position = basepos,
            angle = Angle(),
            model = ' ',
            collision = '34x09.nlz/go003_lod1-a_col.pfx'
        })

    end

    if tonumber(self.strikes:get()) >= self.max_strikes and not IsAdmin(LocalPlayer) then
        self.timer:Restart()
        Network:Send(var("anticheat/collisioncheck"):get())
        self.strikes:set(0)
    end

end

cCollisionChecker()