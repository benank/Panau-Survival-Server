Events:Subscribe("PlayerChat", function(args)
    local words = args.text:split(" ")

    if words[1] == "/me" then
        local msg = args.text:gsub("/me ", "")
        Chat:Broadcast(string.format("*%s %s*", args.player:GetName(), msg), args.player:GetColor())
    end
end)