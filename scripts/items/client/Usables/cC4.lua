class 'cC4'

function cC4:__init(args)
    self.position = args.position
    self.angle = args.angle
    self.attach_entity = args.attach_entity
    self.values = args.values

    self.object = ClientStaticObject.Create({
        position = self.position,
        angle = self.angle,
        model = "f1t05bomb01.eez/key019_01-z.lod"
    })

    self.angle_offset = Angle(math.pi, 0, 0)

    self.render = Events:Subscribe("Render", self, self.Render)
end

function cC4:Render(args)
    if IsValid(self.object) and IsValid(self.attach_entity) then

        local entity = self.attach_entity

        if self.values.parent_bone then

            -- Attached to player
            local bone_pos = entity:GetBonePosition(self.values.parent_bone)
            local bone_angle = entity:GetBoneAngle(self.values.parent_bone)

            self.object:SetAngle(bone_angle * self.values.angle_offset)
            self.object:SetPosition(bone_pos + bone_angle * self.values.position_offset)

        else

            -- Attached to vehicle
            self.object:SetAngle(entity:GetAngle() * self.values.angle_offset)
            self.object:SetPosition(entity:GetPosition() + entity:GetAngle() * self.values.position_offset)

        end

    end
end

function cC4:Remove()
    if IsValid(self.object) then self.object:Remove() end
    Events:Unsubscribe(self.render)
end