local CSOCreate = ClientStaticObject.Create
local CSORemove = ClientStaticObject.Remove

CSOs = {}

function ClientStaticObject.Create(args)
	local cso = CSOCreate(args)
	CSOs[cso:GetId()] = {cso = cso, values = {}}
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
	return CSOs[self:GetId()].values[s]
end