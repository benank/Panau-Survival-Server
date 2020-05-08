class 'sStunting'

function sStunting:__init()

    Events:Subscribe("PlayerEnterStunt", self, self.PlayerEnterStunt)
    Events:Subscribe("PlayerExitStunt", self, self.PlayerExitStunt)
end

function sStunting:PlayerEnterStunt(args)
    args.player:SetNetworkValue("StuntingVehicle", args.vehicle)
end

function sStunting:PlayerExitStunt(args)
    args.player:SetNetworkValue("StuntingVehicle", nil)
end

sStunting = sStunting()