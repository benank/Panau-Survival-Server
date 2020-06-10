class 'cStickDisguise'

function cStickDisguise:__init()

    self.players_equipped = {}

    self.connected_bones = 
    {
        ["ragdoll_Neck"] = {"ragdoll_RightShoulder", "ragdoll_LeftShoulder", "ragdoll_Spine1"},
        ["ragdoll_RightShoulder"] = {"ragdoll_RightArm"},
        ["ragdoll_RightArm"] = {"ragdoll_RightForeArm"},
        ["ragdoll_RightForeArm"] = {"ragdoll_RightHand"},
        ["ragdoll_RightHand"] = {"ragdoll_AttachHandRight"},
        ["ragdoll_LeftShoulder"] = {"ragdoll_LeftArm"},
        ["ragdoll_LeftArm"] = {"ragdoll_LeftForeArm"},
        ["ragdoll_LeftForeArm"] = {"ragdoll_LeftHand"},
        ["ragdoll_LeftHand"] = {"ragdoll_AttachHandLeft"},
        ["ragdoll_Spine1"] = {"ragdoll_Spine"},
        ["ragdoll_Spine"] = {"ragdoll_Hips"},
        ["ragdoll_Hips"] = {"ragdoll_RightUpLeg", "ragdoll_LeftUpLeg"},
        ["ragdoll_RightUpLeg"] = {"ragdoll_RightLeg"},
        ["ragdoll_RightLeg"] = {"ragdoll_RightFoot"},
        ["ragdoll_LeftUpLeg"] = {"ragdoll_LeftLeg"},
        ["ragdoll_LeftLeg"] = {"ragdoll_LeftFoot"}
    }

    self.color = Color.White

    Events:Subscribe("SecondTick", self, self.SecondTick)

end

function cStickDisguise:GameRenderOpaque(args)

    for id, p in pairs(self.players_equipped) do
        if IsValid(p) then

            for parent_bone_name, connected_bones in pairs(self.connected_bones) do
                for _, bone_name in pairs(connected_bones) do
                    local start_pos = p:GetBonePosition(parent_bone_name)
                    local end_pos = p:GetBonePosition(bone_name)
                    Render:DrawLine(start_pos, end_pos, self.color)
                end
            end
            local t = Transform3():Translate(p:GetBonePosition("ragdoll_Head")):Rotate(p:GetBoneAngle("ragdoll_Head"))
            Render:SetTransform(t)
            Render:DrawCircle(Vector3.Zero, 0.1, self.color)
            Render:ResetTransform()

        else
            self.players_equipped[id] = nil
        end
    end

end

function cStickDisguise:SecondTick()

    for p in Client:GetStreamedPlayers() do
        self:CheckPlayer(p)
    end

    self:CheckPlayer(LocalPlayer)

end

function cStickDisguise:CheckPlayer(p)

    local enabled = p:GetValue("StickDisguiseEquipped")
    local id = p:GetId()

    self.players_equipped[id] = enabled and p or nil


    if count_table(self.players_equipped) > 0 and not self.render then
        self.render = Events:Subscribe("GameRenderOpaque", self, self.GameRenderOpaque)
    elseif count_table(self.players_equipped) == 0 and self.render then
        self.render = Events:Unsubscribe(self.render)
    end

end

cStickDisguise = cStickDisguise()