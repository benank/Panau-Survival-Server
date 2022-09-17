class 'cJumpPadExtension'

-- Jump pad extension for cLandclaimObjects that allows for jumping
function cJumpPadExtension:__init(object)
    self.object = object
    self.color = Color(0, 200, 255, 200)
    self.delta = 0
    self.use_timer = Timer()
    self.y_velo = 150
    self.jump_time = 3
    self.bones = {
        ["ragdoll_Reference"] = true,
        ["ragdoll_Hips"] = true,
        ["ragdoll_Spine"] = true,
        ["ragdoll_Spine1"] = true,
        ["ragdoll_UpperLeftLeg"] = true,
        ["ragdoll_UpperRightLeg"] = true,
        ["ragdoll_LeftLeg"] = true,
        ["ragdoll_RightLeg"] = true,
        ["ragdoll_LeftFoot"] = true,
        ["ragdoll_RightFoot"] = true,
        ["ragdoll_Neck"] = true,
    }
    self.detect_position = self.object.position + self.object.angle * Vector3.Up * 0.3
end

function cJumpPadExtension:GameRenderOpaque(args)
    self.delta = self.delta + args.delta
    local t = Transform3():Translate(self.object.position):Rotate(self.object.angle):Translate(Vector3.Up):Rotate(Angle(0, math.pi / 2, 0))
    Render:SetTransform(t)
    for i = 1, 7 do
        Render:DrawCircle(Vector3(0, 0, -(i * 0.3 + self.delta) % 2 - 7 / 2 * 0.3), 0.2, self.color)
    end

    if self.use_timer:GetSeconds() > self.jump_time and self:IsInRange() then
        Game:FireEvent(var("ply.invulnerable"):get())
        local velo = LocalPlayer:GetLinearVelocity()
        velo = self.object.angle * Vector3(0, self.y_velo, 0)
        LocalPlayer:SetLinearVelocity(velo)
        self.use_timer:Restart()
        ClientEffect.Play(AssetLocation.Game, {position = self.object.position, angle = Angle(0,0,0), effect_id = 135})

        LocalPlayer:SetOutlineEnabled(true)
        LocalPlayer:SetOutlineColor(self.color)
        
        Thread(function()
            while self.use_timer:GetSeconds() < self.jump_time and LocalPlayer:GetHealth() > 0 do
                Game:FireEvent(var("ply.invulnerable"):get())
                LocalPlayer:SetLinearVelocity(velo)
                Timer.Sleep(5)
            end
            
            Game:FireEvent(var("ply.vulnerable"):get())
            LocalPlayer:SetOutlineEnabled(false)
        end)
    end
end

function cJumpPadExtension:IsInRange()
    for bone, _ in pairs(self.bones) do
        if LocalPlayer:GetBonePosition(bone):Distance(self.detect_position) < 0.75 then return true end
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