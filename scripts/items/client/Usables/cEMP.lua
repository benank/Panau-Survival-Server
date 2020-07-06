class 'cEMP'

function cEMP:__init()

    self.disabled_vehicles = {}

    self.disabled_controls = 
    {
        [Action.MoveBackward] = 0,
        [Action.MoveForward] = 0,
        [Action.MoveLeft] = 0,
        [Action.MoveRight] = 0,
        [Action.McFire] = 0,
        [Action.HeliTurnRight] = 0,
        [Action.HeliTurnLeft] = 0,
        [Action.HeliRollRight] = 0,
        [Action.HeliRollLeft] = 1,
        [Action.HeliIncAltitude] = 0,
        [Action.HeliForward] = 0,
        [Action.HeliDecAltitude] = 1,
        [Action.HeliBackward] = 0,
        [Action.Handbrake] = 0,
        [Action.FireVehicleWeapon] = 0,
        [Action.BoatTurnRight] = 0,
        [Action.BoatTurnLeft] = 0,
        [Action.BoatForward] = 0,
        [Action.BoatBackward] = 0,
        [Action.BikeTiltForward] = 0,
        [Action.BikeTiltBackward] = 0,
        [Action.Accelerate] = -1,
        [Action.PlaneDecTrust] = 1,
        [Action.PlaneIncTrust] = 0,
        [Action.PlanePitchDown] = 0.25,
        [Action.PlanePitchUp] = 0,
        [Action.PlaneRollLeft] = 0,
        [Action.PlaneRollRight] = 0,
        [Action.PlaneTurnLeft] = 0,
        [Action.PlaneTurnRight] = 0,
        [Action.Reverse] = 0,
        [Action.SoundHornSiren] = 0,
        [Action.TurnLeft] = 0,
        [Action.TurnRight] = 0,
        [Action.VehicleFireLeft] = 0,
        [Action.VehicleFireRight] = 0
    }

    Network:Subscribe("items/ActivateEMP", self, self.ActivateEMP)
    Events:Subscribe("LocalPlayerEnterVehicle", self, self.LocalPlayerEnterVehicle)
    Events:Subscribe("LocalPlayerExitVehicle", self, self.LocalPlayerExitVehicle)
    Events:Subscribe("LocalPlayerDeath", self, self.LocalPlayerDeath)
    
    Thread(function()
        while true do
            Timer.Sleep(200)
            self:Tick()
        end
    end)

end

function cEMP:LocalPlayerDeath()
    if self.input_poll then
        self.input_poll = Events:Unsubscribe(self.input_poll)
    end
end

function cEMP:Tick()

    for v in Client:GetVehicles() do
        if v:GetValue("DisabledByEMP") then
            ClientEffect.Play(AssetLocation.Game, {
                position = v:GetPosition() + Vector3.Up,
                angle = v:GetAngle(),
                effect_id = 92
            })
            Timer.Sleep(100 + math.random(200))
        end
    end

end

function cEMP:InputPoll(args)
    if LocalPlayer:GetHealth() <= 0 or not LocalPlayer:InVehicle() or not LocalPlayer:GetVehicle():GetValue("DisabledByEMP") then
        self.input_poll = Events:Unsubscribe(self.input_poll)
        return
    else
        for action, value in pairs(self.disabled_controls) do
            Input:SetValue(action, value)
        end
    end
end

function cEMP:LocalPlayerEnterVehicle(args)
    if not self.input_poll then
        self.input_poll = Events:Subscribe("InputPoll", self, self.InputPoll)
    end
end

function cEMP:LocalPlayerExitVehicle(args)
    if self.input_poll then
        self.input_poll = Events:Unsubscribe(self.input_poll)
    end
end

function cEMP:ActivateEMP(args)

    if args.position:Distance(Camera:GetPosition()) > 2000 then return end

    ClientEffect.Play(AssetLocation.Game, {
        position = args.position,
        angle = Angle(),
        effect_id = 137
    })

    if LocalPlayer:InVehicle() and not self.input_poll then
        self.input_poll = Events:Subscribe("InputPoll", self, self.InputPoll)
    end

end

cEMP = cEMP()