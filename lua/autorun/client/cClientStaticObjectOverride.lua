local CSOCreate = ClientStaticObject.Create
local CSORemove = ClientStaticObject.Remove

CSOs = SharedObject.Create("CSOs")

if not CSOs:GetValue("CSOs") then
    CSOs:SetValue("CSOs", {})
end

function ClientStaticObject.Create(args)
    local cso = CSOCreate(args)
    local tbl = CSOs:GetValue("CSOs")
    tbl[cso:GetId()] = {cso = cso, values = {}}
    CSOs:SetValue("CSOs", tbl)
	return cso
end

function ClientStaticObject:Remove()
	CSOs[self:GetId()] = nil
	CSORemove(self)
end

function ClientStaticObject:SetValue(s, value)
    local tbl = CSOs:GetValue("CSOs")
	tbl[self:GetId()].values[s] = value
    CSOs:SetValue("CSOs", tbl)
end

function ClientStaticObject:GetValue(s)
	return CSOs:GetValue("CSOs")[self:GetId()].values[s]
end