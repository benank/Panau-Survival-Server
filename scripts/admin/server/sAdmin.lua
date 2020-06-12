local admins = 
{
    ["STEAM_0:0:47613644"] = true,
    ["STEAM_0:1:31147722"] = true,
    ["STEAM_0:1:37351623"] = true
}

Events:Subscribe("PlayerAuthenticate", function(args)
    if admins[tostring(args.player:GetSteamId())] then
        args.player:SetNetworkValue("Admin", true)
    else
        args.player:SetNetworkValue("Admin", nil)
    end
end)