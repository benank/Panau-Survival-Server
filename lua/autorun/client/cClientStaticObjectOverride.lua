local CSOCreate = ClientStaticObject.Create
local CSORemove = ClientStaticObject.Remove

CSOs = {}

function ClientStaticObject.Create(args)
	local cso = CSOCreate(args)
	local data = {cso = cso, values = {}}
	CSOs[cso:GetId()] = data
	return cso
end

function ClientStaticObject:Remove()
	CSOs[self:GetId()] = nil
	CSORemove(self)
end

function ClientStaticObject:SetValue(s, value)
	CSOs[self:GetId()].values[s] = value
end

function ClientStaticObject:GetValue(s)
    if not CSOs[self:GetId()] then return end
	return CSOs[self:GetId()].values[s]
end