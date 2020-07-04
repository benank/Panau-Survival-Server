class 'cLandClaimPlacer'

function cLandClaimPlacer:__init()

    Events:Subscribe("build/CancelLandclaimPlacement", self, self.CancelLandclaimPlacement)
    Network:Subscribe(var("items/StartLandclaimPlacement"):get(), self, self.StartLandclaimPlacement)

end

function cLandClaimPlacer:CancelLandclaimPlacement(args)
    Network:Send(var("items/CancelLandclaimPlacement"):get())
end

function cLandClaimPlacer:StartLandclaimPlacement(args)

    Events:Fire("build/StartPlacingLandclaim", {
        size = args.size
    })

end

cLandClaimPlacer = cLandClaimPlacer()