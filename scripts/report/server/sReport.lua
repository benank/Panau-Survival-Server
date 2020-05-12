Events:Subscribe("PlayerChat", function(args)
    local words = args.text:split(" ")

    if words[1] == "/report" then
        local message = args.text:gsub("/report ", "")

        if message:len() < 5 then return false end

        Events:Fire("Discord", {    
            channel = "Reports",
            content = string.format("%s [%s] report: %s", args.player:GetName(), tostring(args.player:GetSteamId()), message)
        })

        Chat:Send(args.player, "Thank you for submitting a report. The staff will be looking at it shortly.", Color.Yellow)

        return false
    end

end)