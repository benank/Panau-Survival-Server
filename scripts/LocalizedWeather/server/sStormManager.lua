class 'sStormManager'

function sStormManager:__init()

	self.storms = {}

	-- Interval every hour
	Timer.SetInterval(1000 * 60 * 60, function()
	--Timer.SetInterval(1000 * 5, function()
	
		if math.random() < config.chance_per_hour and #self.storms < config.max_storms then

			self:CreateStorm()

		end

    end)

    Events:Subscribe("ModuleUnload", self, self.Unload)

end

function sStormManager:CreateStorm()

	table.insert( self.storms, sStorm() ) -- Just let the storm class handle random stuff

    local up_time = 1000 * 60 * 60 * math.random(config.min_time, config.max_time)

    Timer.SetTimeout(up_time)

end

function sStormManager:Unload()

    for k, v in pairs(self.storms) do

        self.storms[k]:Remove()

    end

end


stormManager = sStormManager()