class "InstantBullet"

function InstantBullet:__init(args)
    getter_setter(self, "active")
    self:SetActive(true)
    getter_setter(self, "id")
    self:SetId(args.id)
    self.weapon_enum = args.weapon_enum

    self:DetectHit()
end

function InstantBullet:PreTick(delta)

end

function InstantBullet:Render()

end

function InstantBullet:DetectHit()
    local target = LocalPlayer:GetAimTarget()

    if target and target.entity then
        Events:Fire("LocalPlayerBulletDirectHitEntity", {
            entity_type = target.entity.__type,
            entity_id = target.entity:GetId(),
            weapon_enum = self.weapon_enum,
            hit_position = target.position
        })
    end

    self:SetActive(true)
end

function InstantBullet:Destroy()
    -- remove any CSOs, effects, or event subscriptions here
end
