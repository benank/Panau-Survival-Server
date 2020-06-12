class 'cLogoutIndicators'

function cLogoutIndicators:__init()

    self.indicator_expire_time = 30 -- 30 seconds

    self.size = 200
    self.scale = 0.001

    self.indicators = {}

    Network:Subscribe("HitDetection/PlayerQuit", self, self.PlayerQuit)

end

function cLogoutIndicators:RenderIndicator(indicator, seconds)

    local angle = Camera:GetAngle()
    angle.pitch = 0
    angle.roll = 0

    local t = Transform3():Translate(indicator.position):Rotate(angle * Angle(0, math.pi, 0))
    Render:SetTransform(t)

    local alpha = 255 - 255 * math.min(1, (seconds - indicator.time) / self.indicator_expire_time)
    local color = Color(255, 0, 0, alpha)

    local text_size = Render:GetTextWidth(indicator.name, self.size, self.scale)
    Render:DrawText(Vector3(-text_size * 0.065, -0.5, 0), indicator.name, color, self.size, self.scale)

    local width = 0.4
    Render:FillArea(Vector3(-width / 2, -0.25, 0), Vector3(width, 0.75, 0), color)

    width = 1
    Render:FillTriangle(
        Vector3(-width / 2, 0.5, 0),
        Vector3(width / 2, 0.5, 0),
        Vector3(0, 1, 0),
        color
    )

    Render:ResetTransform()

end

function cLogoutIndicators:GameRender(args)

    local seconds = Client:GetElapsedSeconds()

    for index, indicator in pairs(self.indicators) do
        self:RenderIndicator(indicator, seconds)

        if seconds - indicator.time > self.indicator_expire_time then
            self.indicators[index] = nil
        end
    end

    if count_table(self.indicators) == 0 then
        self.render = Events:Unsubscribe(self.render)
    end

end

function cLogoutIndicators:PlayerQuit(args)

    if args.position:Distance(Camera:GetPosition()) > 500 then return end

    args.time = Client:GetElapsedSeconds()
    args.position = args.position + Vector3.Up

    table.insert(self.indicators, args)

    if not self.render then
        self.render = Events:Subscribe("GameRender", self, self.GameRender)
    end

end

cLogoutIndicators = cLogoutIndicators()