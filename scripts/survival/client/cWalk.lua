local inputsub = nil
local walking = false
local z_key = string.byte("Z")

Events:Subscribe("KeyDown", function(args)

    if args.key == z_key and not inputsub then
        walking = true

        inputsub = Events:Subscribe("InputPoll", function(args)
            Input:SetValue(Action.Walk, walking and 1 or 0)
            if not walking then
                Events:Unsubscribe(inputsub)
                inputsub = nil
            end
        end)

    end

end)

Events:Subscribe("KeyUp", function(args)
    walking = false
end)