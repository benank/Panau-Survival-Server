function GetCSOId(cso)
    return string.format("%s_%d", cso:GetModel(), cso:GetId())
end

function GetCSOIdArgs(args)
    return string.format("%s_%d", args.model, args.cso_id)
end
