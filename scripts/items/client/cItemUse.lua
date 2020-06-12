class 'cItemUse'

function cItemUse:__init()

	self.circle_size = Render.Size.x * 0.02
    self.circle_basepos = Vector2(Render.Size.x / 2, Render.Size.y / 2)
    self.offset = Vector2(Render.Size.x * 0.001, Render.Size.x * 0.001)

    self.item_name = "None"

    self.allowed_actions = 
    {
        [Action.LookDown] = true,
        [Action.LookLeft] = true,
        [Action.LookRight] = true,
        [Action.LookUp] = true,
        [Action.HeliRollLeft] = true,
        [Action.HeliRollRight] = true,
        [Action.HeliTurnLeft] = true,
        [Action.HeliTurnRight] = true,
        [Action.HeliBackward] = true,
        [Action.HeliForward] = true,
        [Action.BoatBackward] = true,
        [Action.BoatForward] = true,
        [Action.BoatTurnLeft] = true,
        [Action.BoatTurnRight] = true,
        [Action.PlanePitchDown] = true,
        [Action.PlanePitchUp] = true,
        [Action.PlaneRollLeft] = true,
        [Action.PlaneRollRight] = true,
        [Action.PlaneTurnLeft] = true,
        [Action.PlaneTurnRight] = true,
        [Action.Weapon4] = true,
        [Action.Weapon6] = true,
        [Action.EquipLeftSlot] = true
    }

    self.events = {}

    self.progress = {
        max = 0,
        current = 0
    }
    
	self.progress_circle = CircleBar(self.circle_basepos, self.circle_size, 
	{
		[1] = {max_amount = 100, amount = 0, color = Color(200,200,200,255)}
    })
    

    Network:Subscribe(var("items/UseItem"):get(), self, self.StartUsage)

end

function cItemUse:StartUsage(args)

    self.item_name = args.name
    self.progress.max = args.time
    self.progress.current = 0
    Events:Fire("SetInventoryState", false)

    table.insert(self.events, Events:Subscribe("InputPoll", self, self.InputPoll))
    table.insert(self.events, Events:Subscribe("Render", self, self.Render))
    table.insert(self.events, Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput))
    table.insert(self.events, Events:Subscribe("LocalPlayerExplosionHit", self, self.CancelUsage))
    table.insert(self.events, Events:Subscribe("LocalPlayerBulletHit", self, self.CancelUsage))
    table.insert(self.events, Events:Subscribe("LocalPlayerDeath", self, self.CancelUsage))

    if LocalPlayer:GetBaseState() ~= AnimationState.SUprightIdle
    and LocalPlayer:GetBaseState() ~= AnimationState.SSwimIdle then
        self:CancelUsage()
    end

end

function cItemUse:CancelUsage()

    Network:Send("items/CancelUsage")
    self:UnsubscribeEvents()

end

function cItemUse:CompleteUsage()

    local ray = Physics:Raycast(LocalPlayer:GetPosition(), Vector3.Down, 0, 5)
    if ray.entity and ray.entity.__type == "ClientStaticObject" then
        ray.model = ray.entity:GetModel()
        ray.entity = nil
        ray.hit_type = "ClientStaticObject"
    end

    local forward_ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 500)
    if forward_ray.entity and forward_ray.entity.__type == "ClientStaticObject" then
        forward_ray.model = forward_ray.entity:GetModel()
        forward_ray.entity = nil
        forward_ray.hit_type = "ClientStaticObject"
    end

    local waypoint_pos, waypoint_set = Waypoint:GetPosition()
    Network:Send(var("items/CompleteItemUsage"):get(), {ray = ray, forward_ray = forward_ray, waypoint = waypoint_pos, waypoint_set = waypoint_set})
    self:UnsubscribeEvents()

end

function cItemUse:LocalPlayerInput(args)
    if not self.allowed_actions[args.input] then
        self:CancelUsage()
    end
end

function cItemUse:InputPoll(args)
    Input:SetValue(Action.Crouch, 1.0)
end

function cItemUse:UnsubscribeEvents()

    for k,v in pairs(self.events) do
        Events:Unsubscribe(v)
        self.events[k] = nil
    end

end

function cItemUse:Render(args)

    self.progress_circle:Render(args)

    self:RenderCountdown(args)
    self:RenderInfo(args)

    self.progress.current = self.progress.current + args.delta
    
    self.progress_circle.data[1].amount = (self.progress.current / self.progress.max) * 100
    self.progress_circle:Update()

    if self.progress.current >= self.progress.max then
        self:CompleteUsage()
    end

end

function cItemUse:RenderCountdown(args)

    local text = string.format("%.1f", self.progress.max - self.progress.current)
    local font_size = Render.Size.x * 0.015
    local text_size = Render:GetTextSize(text, font_size)
    Render:DrawText(Render.Size / 2 - text_size / 2 + self.offset, text, Color.Black, font_size)
    Render:DrawText(Render.Size / 2 - text_size / 2, text, Color.White, font_size)
    
end

function cItemUse:RenderInfo(args)

    local text = string.format("Using %s", self.item_name)
    local font_size = Render.Size.x * 0.015
    local text_size = Render:GetTextSize(text, font_size)
    Render:DrawText(Render.Size / 2 - Vector2(0, text_size.y / 2) + self.offset + Vector2(self.circle_size + 10, 0), text, Color.Black, font_size)
    Render:DrawText(Render.Size / 2 - Vector2(0, text_size.y / 2) + Vector2(self.circle_size + 10, 0), text, Color.White, font_size)

end

ItemUse = cItemUse()