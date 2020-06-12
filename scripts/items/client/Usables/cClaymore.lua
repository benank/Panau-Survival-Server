class 'cClaymore'

function cClaymore:__init(args)

    self.range = 2
    self.position = args.position
    self.angle = args.angle
    self.id = args.id
    self.owner_id = args.owner_id
    self.cell = GetCell(self.position, ItemsConfig.usables.Claymore.cell_size)
    self.alpha = 0
    self.trigger_timer = Timer()

    self:CreateClaymore()

    self.timer = Timer()

end

function cClaymore:Render()

    local angle = self.angle * Angle(math.pi / 2, 0, 0)
    local start_ray_pos = self.position + angle * Vector3(0, 0.25, 0)

    if IsNaN(angle) then return end

    local ray = Physics:Raycast(start_ray_pos, angle * Vector3.Forward, 0, ItemsConfig.usables.Claymore.trigger_range, false)

    local end_ray_pos = ray.position

    Render:DrawLine(
        start_ray_pos,
        end_ray_pos,
        Color(255, 0, 0, self.alpha)
    )

    if ray.entity and (ray.entity.__type == "LocalPlayer" or ray.entity.__type == "Vehicle") and self.trigger_timer:GetSeconds() > 1 then
        self:Trigger()
        self.trigger_timer:Restart()
    end

    -- Update alpha of laser
    if self.timer:GetSeconds() > 1 then
        self.timer:Restart()
        self.alpha = (1 - math.min(Camera:GetPosition():Distance(self.position), 20) / 20) * 120
    end

    if self.owner_id == tostring(LocalPlayer:GetSteamId()) or
    AreFriends(LocalPlayer, self.owner_id) then
        self.alpha = 200
    end


end

function cClaymore:Trigger(args)
    if self.owner_id == tostring(LocalPlayer:GetSteamId()) then return end -- Don't explode on the owner
    if AreFriends(LocalPlayer, self.owner_id) then return end -- Owner is a friend
    if LocalPlayer:GetValue("Invincible") then return end

    Network:Send(var("items/StepOnClaymore"):get(), {id = self.id})
    cClaymores:ClaymoreExplode({position = self.position, id = self.id, owner_id = self.owner_id})
end

function cClaymore:GetCell()
    return self.cell
end

function cClaymore:CreateClaymore()

    local radius = ItemsConfig.usables.Claymore.trigger_radius

    self.object = ClientStaticObject.Create({
        position = self.position,
        angle = self.angle,
        model = 'km05.blz/gp703-a.lod',
        collision = 'km05.blz/gp703_lod1-a_col.pfx'
    })

end

function cClaymore:Remove()
    self.object:Remove()
end