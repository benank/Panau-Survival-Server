class 'sStorm'

function sStorm:__init(pos, radius, velocity)

    print("Storm created")

    self.position = pos or Vector3(math.random(config.min_x, config.max_x), 0, math.random(config.min_z, config.max_z))
    self.radius = radius or math.random(config.min_size, config.max_size)
    self.velocity = velocity or Vector3(1, 0, 1) * math.random(config.min_speed, config.max_speed)

    self.wno = WorldNetworkObject.Create(self.position, {isStorm = true, radius = self.radius, velocity = self.velocity})
    self.wno:SetStreamDistance(config.stream_distance)

	self.interval = Timer.SetInterval(1000, function()
        self:Interval()
    end)
	
end

function sStorm:Interval()

    self.position = self.position + self.velocity;
    self.wno:SetPosition(self.position)

end

function sStorm:Remove()

    self.wno:Remove()
    Timer.Clear(self.interval)
    self.interval = nil

end
