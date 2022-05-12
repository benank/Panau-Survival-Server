class 'cEquippableVisualPlayer'

function cEquippableVisualPlayer:__init(args)

    self.equipped_visuals = args.equipped_visuals
    self.objs = {}
    self.player = args.player
    self.time = Client:GetElapsedSeconds()
    self.delta = 0
    self:Update()

end

function cEquippableVisualPlayer:RenderVisual(name)

    local visual = EquippableVisuals[name]
    
    if not visual.render then
        local angle = self.player:GetBoneAngle(visual.bone) * visual.angle
        self.objs[name]:SetAngle(angle)
        self.objs[name]:SetPosition(self.player:GetBonePosition(visual.bone) + angle * visual.offset)
    else
        local angle = self.player:GetBoneAngle(visual.bone) * visual.angle
        local position = self.player:GetBonePosition(visual.bone) + angle * visual.offset
        local t = Transform3():Translate(position):Rotate(angle)
        Render:SetTransform(t)
        Render:SetFont(AssetLocation.Disk, "Archivo.ttf")
        Render:DrawText(Vector3.Zero, visual.text, visual.color(self.delta), visual.fontsize, visual.scale)
        Render:ResetTransform()
    end

end

function cEquippableVisualPlayer:Update()

    for name, obj in pairs(self.objs) do

        if not self.equipped_visuals[name] then
            if IsValid(obj) and not obj.render then obj:Remove() end
            self.objs[name] = nil
        end

    end


    for name, _ in pairs(self.equipped_visuals) do

        local equippable_visual = EquippableVisuals[name]

        if equippable_visual then

            if not IsValid(self.objs[name]) then
                if equippable_visual.render then
                    self.objs[name] = equippable_visual
                else
                    self.objs[name] = ClientStaticObject.Create({
                        position = Vector3(),
                        angle = Angle(),
                        model = equippable_visual.model
                    })
                end
                
            end

        end
    end

end

function cEquippableVisualPlayer:Render(args)

    if not IsValid(self.player) then return end
    
    self.delta = self.delta + args.delta

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
        if not obj.render and IsValid(obj) then obj:Remove() end
    end
end