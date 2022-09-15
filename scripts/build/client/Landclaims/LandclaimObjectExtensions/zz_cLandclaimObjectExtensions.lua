LandClaimObjectExtensions = 
{
    ["Door"] = cDoorExtension,
    ["Light"] = cLightExtension,
    ["Jump Pad"] = cJumpPadExtension,
    ["Christmas Tree"] = cChristmasTreeExtension,
    ["Sign"] = cSignExtension,
    ["Teleporter"] = cTeleporterExtension
}

Network:Subscribe("build/TeleporterActivate", function(args)
    ClientEffect.Play(AssetLocation.Game, {position = args.pos1, angle = Angle(0,0,0), effect_id = 135})
    ClientEffect.Play(AssetLocation.Game, {position = args.pos1, angle = Angle(0,0,0), effect_id = 137})
    
    LocalPlayer:SetValue("LocalTeleporting", true)
    Game:FireEvent(var("ply.pause"):get())
    Game:FireEvent("ply.parachute.disable")
    
    if args.id == LocalPlayer:GetId() then
        Thread(function()
            local i = 0
            while LandclaimManager and LandclaimManager:AreAnyLandclaimsLoading() or i < 10 do
                Timer.Sleep(1000)
                i = i + 1
            end
            Game:FireEvent(var("ply.unpause"):get())
            Game:FireEvent("ply.parachute.enable")
            LocalPlayer:SetValue("LocalTeleporting", false)
            Network:Send("build/FinishTeleporting")
            ClientEffect.Play(AssetLocation.Game, {position = args.pos2, angle = Angle(0,0,0), effect_id = 135})
        end)
    end
    
end)

Network:Subscribe("build/TeleporterActivate2", function(args)
    ClientEffect.Play(AssetLocation.Game, {position = args.pos, angle = Angle(0,0,0), effect_id = 137})
end)