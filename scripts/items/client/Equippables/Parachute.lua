local equipped = false

Game:FireEvent("ply.parachute.disable") -- Disable parachute

Network:Subscribe("items/ToggleEquippedParachute", function(args)

    equipped = args.equipped

    if equipped then
        Game:FireEvent("ply.parachute.enable")
    else
        Game:FireEvent("ply.parachute.disable")
    end

end)

local parachute_actions = 
{
    [Action.DeployParachuteWhileReelingAction] = true,
    [Action.ExitToStuntposParachute] = true,
    [Action.ParachuteOpenClose] = true,
    [Action.StuntposToParachute] = true,
    [Action.ActivateParachuteThrusters] = true
}

Events:Subscribe("LocalPlayerInput", function(args)
    if parachute_actions[args.input] and not equipped then return false end
end)