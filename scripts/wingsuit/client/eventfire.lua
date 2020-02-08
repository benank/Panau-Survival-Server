local sounds = {}

Events:Subscribe("LocalPlayerChat", function(args)

    local split = args.text:split(" ")

    if args.text:sub(1, 4) == "/ev " then
        args.text = string.gsub(args.text, "/ev ", "")
        Game:FireEvent(args.text)
        Chat:Print("fired event " .. args.text, Color.Green)
    elseif split[1] == "/s" then

        for i = 1, 100 do
            for j = 1, 5000 do
                table.insert(sounds, ClientSound.Create(AssetLocation.Game, {
                    position = LocalPlayer:GetPosition(),
                    bank_id = i,
                    sound_id = j,
                    variable_id_focus = 0
                }))
                Chat:Print("played sound with bank " .. tostring(i) .. " and id " .. tostring(j), Color.Green)
            end
        end
    end

end)

Events:Subscribe("ModuleUnload", function()

    for k,v in pairs(sounds) do v:Remove() end

end)