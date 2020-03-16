class 'cCollisionChecker'

function cCollisionChecker:__init()

    self.object = ClientStaticObject.Create({
        position = self.position,
        angle = self.angle,
        model = ' ',
        collision = 'km05.blz/gp703_lod1-a_col.pfx'
    })

    self.timer = Timer()

    Events:Subscribe(var("Render"):get(), self, self.Render)
end

function cCollisionChecker:Render(args)
    if not IsValid(self.object) then return end

    local basepos = Camera:GetPosition() + Vector3(0, 500, 0)

    self.object:SetPosition(basepos - Vector3(0, 1, 0))

    local ray = Physics:Raycast(basepos, Vector3.Down, 0, 2)

    if ray.distance == 2 and self.timer:GetSeconds() > 1 then
        self.timer:Restart()
        Network:Send(var("anticheat/collisioncheck"):get())
    end

end

cCollisionChecker()