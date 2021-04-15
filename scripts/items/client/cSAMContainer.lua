class 'cSAMContainer'

function cSAMContainer:__init()

    self.cso_id_to_SAM_id = {}
    self.sams = {}

    Events:Subscribe("sams/SamUpdated", self, self.UpdateCSO)
    Events:Subscribe("sams/CreateSAM", self, self.CreateSAM)

end

-- Called when the SAM CSOs are created
function cSAMContainer:CreateSAM(args)
    self.cso_id_to_SAM_id[args.cso_id] = args.id
end

function cSAMContainer:CSOIdToSAM(cso_id)
    local sam_id = self.cso_id_to_SAM_id[cso_id]
    if sam_id then
        return self.sams[sam_id]
    end
end

-- Called when the properties of the SAM update
function cSAMContainer:UpdateCSO(args)
    if self.sams[args.id] then
        for key, value in pairs(args) do
            self.sams[args.id][key] = value
        end
    else
        self.sams[args.id] = args
    end
    
    if args.destroyed then
        self.sams[args.id] = nil
    end
end

cSAMContainer = cSAMContainer()