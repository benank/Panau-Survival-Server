class 'cSafezone'

function cSafezone:__init()

    self.in_safezone = nil
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

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("GameRenderOpaque", self, self.Render)

end

function cSafezone:SecondTick()
    self.near_safezone = LocalPlayer:GetPosition():Distance(config.safezone.position) < config.safezone.radius * 4

    for player in Client:GetStreamedPlayers() do
        player:SetOutlineEnabled(player:GetValue("InSafezone") == true)
        player:SetOutlineColor(config.safezone.color)
    end

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

        if self.in_safezone ~= old_in_safezone then
            Network:Send("EnterExitSafezone", {in_sz = self.in_safezone})
            if self.in_safezone then 
                Events:Fire("EnterSafezone")
                self:EnterSafezone()
                LocalPlayer:SetOutlineEnabled(self.in_safezone)
                LocalPlayer:SetOutlineColor(config.safezone.color)            
            else 
                self:ExitSafezone()
                Events:Fire("ExitSafezone") 
                LocalPlayer:SetOutlineEnabled(self.in_safezone)
                LocalPlayer:SetOutlineColor(config.safezone.color)            
            end
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