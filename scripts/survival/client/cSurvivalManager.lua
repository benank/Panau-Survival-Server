class 'cSurvivalManager'

local event = var("gsy.exit.settlement")

function cSurvivalManager:__init()

    Events:Fire("loader/RegisterResource", {count = 2})

    self.hud = cSurvivalHUD()
    self.grapple_manager = cGrapplehookManager()
    self.survival_data = {hunger = 100, thirst = 100}
    self.hunger_sprint_threshold = 10
    self.thirst_sprint_threshold = 20

    self:UpdateClimateZone()

    Events:Fire("loader/CompleteResource", {count = 2})

    Network:Subscribe("Survival/Update", self, self.Update)
    Events:Subscribe("Render", self, self.Render)
    Events:Subscribe("MinuteTick", self, self.MinuteTick)

end

function cSurvivalManager:Update(args)
    self.survival_data = args

    if (self.survival_data.hunger < self.hunger_sprint_threshold or self.survival_data.thirst < self.thirst_sprint_threshold) 
    and not self.lpi then
        self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    elseif self.survival_data.hunger >= self.hunger_sprint_threshold and self.survival_data.thirst >= self.thirst_sprint_threshold 
    and self.lpi then
        Events:Unsubscribe(self.lpi)
        self.lpi = nil
    end
end

function cSurvivalManager:LocalPlayerInput(args)
    if args.input == Action.Dash then return false end
end

function cSurvivalManager:UpdateClimateZone()
    --Network:Send("Survival/UpdateClimateZone", {zone = LocalPlayer:GetClimateZone()})
end

function cSurvivalManager:MinuteTick()
    self:UpdateClimateZone()
end

function cSurvivalManager:Render(args)

    Game:FireEvent(event:get())
    self.hud:Render(args)

end

SurvivalManager = nil


Events:Subscribe("LoaderReady", function()

    if not SurvivalManager then
        SurvivalManager = cSurvivalManager()
    end

end)


SurvivalManager = cSurvivalManager()