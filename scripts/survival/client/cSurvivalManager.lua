class 'cSurvivalManager'


function cSurvivalManager:__init()

    Events:Fire("loader/RegisterResource", {count = 2})

    self.hud = cSurvivalHUD()
    --self.grapple_manager = cGrapplehookManager()

    self:UpdateClimateZone()

    Events:Fire("loader/CompleteResource", {count = 2})

    Network:Send("Survival/Ready")

    Events:Subscribe("Render", self, self.Render)
    Events:Subscribe("MinuteTick", self, self.MinuteTick)

end

function cSurvivalManager:UpdateClimateZone()
    Network:Send("Survival/UpdateClimateZone", {zone = LocalPlayer:GetClimateZone()})
end

function cSurvivalManager:MinuteTick()
    self:UpdateClimateZone()
end

function cSurvivalManager:Render(args)

    self.hud:Render(args)
    --self.grapple_manager:Render(args)

end

SurvivalManager = nil


Events:Subscribe("LoaderReady", function()

    if not SurvivalManager then
        SurvivalManager = cSurvivalManager()
    end

end)


SurvivalManager = cSurvivalManager()