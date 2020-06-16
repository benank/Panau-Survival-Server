class 'cExp'

function cExp:__init()

    Events:Subscribe("NetworkObjectValueChange", self, self.NetworkObjectValueChange)

end

function cExp:NetworkObjectValueChange(args)

    if args.object.__type ~= "LocalPlayer" then return end

    self:CheckForExpChange(args)
    self:CheckForPerkChange(args)

end

function cExp:CheckForExpChange(args)

    if args.key ~= "Exp" then return end
    Events:Fire("PlayerExpUpdated", args.value)

end

function cExp:CheckForPerkChange(args)

    if args.key ~= "Perks" then return end
    Events:Fire("PlayerPerksUpdated", args.value)

end

cExp = cExp()