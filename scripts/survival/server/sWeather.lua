class "Weather"

function Weather:__init()
    self.hourly_chance = 8 --% chance to change weather every hour
    
    Events:Subscribe("HourTick", self, self.HourTick)
    Events:Subscribe("ModuleUnload", self, self.Unload)
end

function Weather:Unload()
    DefaultWorld:SetWeatherSeverity(0)
end

function Weather:HourTick()
    if math.random() <= self.hourly_chance / 100 then
        DefaultWorld:SetWeatherSeverity(math.random() * 2)
    elseif DefaultWorld:GetWeatherSeverity() > 0 then
        DefaultWorld:SetWeatherSeverity(0)
    end
end

Weather()
