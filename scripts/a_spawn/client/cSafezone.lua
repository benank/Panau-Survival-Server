class 'cSafezone'

function cSafezone:__init()

    self.sz_sync_timer = Timer()

    self.in_safezone = false
    self.in_neutralzone = false
    self.near_safezone = true

    self.num_sz_circles = math.floor(config.safezone.radius / 2)
    self.num_nz_circles = math.floor(config.neutralzone.radius / 2)

    self.sz_blacklisted = 
    {
        [Action.FireRight] = true,
        [Action.FireLeft] = true,
        [Action.McFire] = true,
        [Action.Fire] = true,
        [Action.Kick] = true,
        [Action.FireVehicleWeapon] = true,
        [Action.VehicleFireLeft] = true,
        [Action.VehicleFireRight] = true
    }

    Events:Subscribe(var("SecondTick"):get(), self, self.SecondTick)
    Events:Subscribe(var("GameRenderOpaque"):get(), self, self.Render)
    Events:Subscribe("Render", self, self.RenderText)

end

function cSafezone:RenderText(args)

    if LocalPlayer:GetValue("InSafezone") then

        self:RenderSafezoneText("In Safezone", "You cannot be killed here", config.safezone.color)

    elseif self.in_neutralzone then

        self:RenderSafezoneText("In Neutralzone", "You don't lose items on death here", config.neutralzone.color)

    elseif LocalPlayer:GetValue("InCombat") then

        self:RenderSafezoneText("In Combat", "Do not log off now", Color(255, 0, 0, 150))

    end

end

function cSafezone:RenderSafezoneText(text, subtext, color)

    local c = Color(color.r, color.g, color.b, 200)

    local top_margin = 10
    local text_size =  24
    local text_size_subtext = 14
    
    local text_textsize = Render:GetTextSize(text, text_size)
    local subtext_textsize = Render:GetTextSize(subtext, text_size_subtext)

    local pos = Vector2(Render.Size.x / 2, top_margin + text_textsize.y)

    Render:DrawText(pos - text_textsize / 2, text, c, text_size)
    Render:DrawText(pos - subtext_textsize / 2 + Vector2(0, text_textsize.y), subtext, c, text_size_subtext)

end

function cSafezone:SecondTick()
    self.near_safezone = LocalPlayer:GetPosition():Distance(config.safezone.position) < config.safezone.radius * 4

    for player in Client:GetStreamedPlayers() do
        player:SetOutlineEnabled(player:GetValue(var("InSafezone"):get()) == true)
        player:SetOutlineColor(config.safezone.color)
    end

    self.in_neutralzone = LocalPlayer:GetPosition():Distance(config.neutralzone.position) < config.neutralzone.radius

end

function cSafezone:EnterSafezone()

    self.sz_subs = {}

    table.insert(self.sz_subs, Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput))
    table.insert(self.sz_subs, Events:Subscribe("InputPoll", self, self.InputPoll))

end

function cSafezone:ExitSafezone()

    if self.sz_subs then
        for k,v in pairs(self.sz_subs) do Events:Unsubscribe(v) end
    end

    self.sz_subs = {}

end

function cSafezone:LocalPlayerInput(args)
    if self.sz_blacklisted[args.input] then return false end
end

function cSafezone:InputPoll(args)
    for action, _ in pairs(self.sz_blacklisted) do
        Input:SetValue(action, 0)
    end
end

function cSafezone:Render(args)

    local old_in_safezone = self.in_safezone

    if self.near_safezone then
        self.in_safezone = LocalPlayer:GetPosition():Distance(config.safezone.position) < config.safezone.radius

        if (self.in_safezone ~= old_in_safezone or (self.in_safezone ~= LocalPlayer:GetValue("InSafezone")))
        and self.sz_sync_timer:GetSeconds() > 0.5 then
            Network:Send(var("EnterExitSafezone"):get(), {in_sz = self.in_safezone})
            if self.in_safezone then 
                Events:Fire("EnterSafezone")
                self:EnterSafezone()         
            else 
                self:ExitSafezone()
                Events:Fire("ExitSafezone")        
            end
            LocalPlayer:SetOutlineEnabled(self.in_safezone)
            LocalPlayer:SetOutlineColor(config.safezone.color)
            self.sz_sync_timer:Restart()
            self.in_safezone = LocalPlayer:GetValue("InSafezone")
        end
    end

    local t = Transform3():Translate(config.safezone.position):Rotate(Angle(0,math.pi / 2,0))
    for i = 1, self.num_sz_circles do

        t:Translate(Vector3(0, 0, math.cos(i / self.num_sz_circles) * -config.safezone.radius / self.num_sz_circles))
        Render:SetTransform(t)
        Render:DrawCircle(Vector3.Zero, math.cos((i / self.num_sz_circles) * math.pi / 2) * config.safezone.radius, config.safezone.color)

    end

    Game:FireEvent(self.in_safezone and "ply.invulnerable" or "ply.vulnerable")

end


Safezone = cSafezone()