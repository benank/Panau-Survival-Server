class 'cEquippableVisualPlayer'

function cEquippableVisualPlayer:__init(args)

    self.equipped_visuals = args.equipped_visuals
    self.objs = {}
    self.player = args.player
    self.time = Client:GetElapsedSeconds()
    self:Update()

end

function cEquippableVisualPlayer:RenderVisual(name)

    local angle = self.player:GetBoneAngle(EquippableVisuals[name].bone) * EquippableVisuals[name].angle
    self.objs[name]:SetAngle(angle)
    self.objs[name]:SetPosition(self.player:GetBonePosition(EquippableVisuals[name].bone) + angle * EquippableVisuals[name].offset)

end

function cEquippableVisualPlayer:Update()

    for name, obj in pairs(self.objs) do

        if not self.equipped_visuals[name] then
            if IsValid(obj) then obj:Remove() end
            self.objs[name] = nil
        end

    end


    for name, _ in pairs(self.equipped_visuals) do

        local equippable_visual = EquippableVisuals[name]

        if equippable_visual then

            if not IsValid(self.objs[name]) then
                self.objs[name] = ClientStaticObject.Create({
                    position = Vector3(),
                    angle = Angle(),
                    model = equippable_visual.model
                })
            end

        end
    end

end

function cEquippableVisualPlayer:Render(args)

    if not IsValid(self.player) then return end

    for name, obj in pairs(self.objs) do

        if not self.equipped_visuals[name] then
            if IsValid(obj) then obj:Remove() end
            self.objs[name] = nil
        else
            self:RenderVisual(name)
        end

    end

end

function cEquippableVisualPlayer:Remove()
    for name, obj in pairs(self.objs) do
        if IsValid(obj) then obj:Remove() end
    end
end