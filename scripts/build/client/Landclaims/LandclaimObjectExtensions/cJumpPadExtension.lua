class 'cJumpPadExtension'

-- Jump pad extension for cLandclaimObjects that allows for jumping
function cJumpPadExtension:__init(object)
    self.object = object
    self.color = Color(0, 200, 255, 200)
    self.delta = 0
    self.use_timer = Timer()
    self.y_velo = 150
    self.jump_time = 3
end

function cJumpPadExtension:GameRenderOpaque(args)
    self.delta = self.delta + args.delta
    local t = Transform3():Translate(self.object.position + Vector3.Up):Rotate(Angle(0, math.pi / 2, 0))
    Render:SetTransform(t)
    for i = 1, 7 do
        Render:DrawCircle(Vector3(0, 0, -(i * 0.3 + self.delta) % 2), 0.25, self.color)
    end

    local bone_pos = LocalPlayer:GetBonePosition("ragdoll_Reference")
    if self.use_timer:GetSeconds() > self.jump_time and bone_pos:Distance(self.object.position) < 0.25 then
        local velo = LocalPlayer:GetLinearVelocity()
        velo.y = self.y_velo
        LocalPlayer:SetLinearVelocity(velo)
        self.use_timer:Restart()

        Thread(function()
            while self.use_timer:GetSeconds() < self.jump_time do
                LocalPlayer:SetLinearVelocity(velo)
                Timer.Sleep(10)
            end
        end)
    end
end

function cJumpPadExtension:StreamIn()
    self:Remove()
    self.render = Events:Subscribe("GameRenderOpaque", self, self.GameRenderOpaque)
end

function cJumpPadExtension:StreamOut()
    self:Remove()
end

function cJumpPadExtension:Remove()
    if self.render then
        self.render = Events:Unsubscribe(self.render)
    end
end

function cJumpPadExtension:StateUpdated()
end

function cJumpPadExtension:Activate()
end