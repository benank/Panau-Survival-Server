class 'cHitDetectionMarker'

function cHitDetectionMarker:__init()

    self.color = Color.White
    self.middle_dist = 16
    self.length = 20
    self.duration = 0.25

    Network:Subscribe("HitDetection/DealDamage", self, self.Activate)

end

function cHitDetectionMarker:Activate(args)

    if args and args.red then
        self.color = Color.Red
        self.duration = 2
        self.length = 40
    else
        self.color = Color.White
        self.duration = 0.25
        self.length = 20
    end

    if not self.render then
        self.render = Events:Subscribe("Render", self, self.Render)
    end

    if not self.timer then
        self.timer = Timer()
    else
        self.timer:Restart()
    end
    
end

function cHitDetectionMarker:Render(args)

    local middle = Render.Size / 2

    local seconds = self.timer:GetSeconds()

    if seconds > self.duration then
        Events:Unsubscribe(self.render)
        self.render = nil
        self.timer = nil
        return
    end

    local percentage = seconds / self.duration
    local alpha = 255 * (1 - percentage)
    local color = Color(self.color.r, self.color.g, self.color.b, alpha)

    -- Top Left
    Render:DrawLine(
        middle + Vector2(-self.middle_dist, -self.middle_dist) + Vector2(-self.length, -self.length),
        middle + Vector2(-self.middle_dist, -self.middle_dist) + Vector2(-self.length, -self.length) * percentage,
        color)

    -- Top Right
    Render:DrawLine(
        middle + Vector2(self.middle_dist, -self.middle_dist) + Vector2(self.length, -self.length),
        middle + Vector2(self.middle_dist, -self.middle_dist) + Vector2(self.length, -self.length) * percentage,
        color)
    
    -- Bottom Left
    Render:DrawLine(
        middle + Vector2(-self.middle_dist, self.middle_dist) + Vector2(-self.length, self.length),
        middle + Vector2(-self.middle_dist, self.middle_dist) + Vector2(-self.length, self.length) * percentage,
        color)
    
    -- Bottom Right
    Render:DrawLine(
        middle + Vector2(self.middle_dist, self.middle_dist) + Vector2(self.length, self.length),
        middle + Vector2(self.middle_dist, self.middle_dist) + Vector2(self.length, self.length) * percentage,
        color)
end

cHitDetectionMarker = cHitDetectionMarker()