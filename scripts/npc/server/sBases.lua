class "Bases"

function Bases:__init()
    self.bases = {}
end

function Bases:LoadBase(name)
    local base = BaseSerialization:GetFullyLoadedBaseFromFile(name)
    if base then
        self.bases[name] = base
    end
    return base
end

function Bases:Create(name)
    local base = Base()
    base:SetName(name)
    self.bases[name] = base

    BaseSerialization:SaveBase(base)
end

function Bases:GetBaseByName(name)
    return self.bases[name]
end

function Bases:GetAllBases()
    return self.bases
end

Bases = Bases()