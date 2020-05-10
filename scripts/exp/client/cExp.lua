class 'cExp'

function cExp:__init()

    Events:Subscribe("NetworkObjectValueChange", self, self.NetworkObjectValueChange)

end

function cExp:NetworkObjectValueChange(args)

    if args.object.__type ~= "LocalPlayer" then return end
    if args.key ~= "Exp" then return end

    Events:Fire("PlayerExpUpdated", args.value)

end

cExp = cExp()