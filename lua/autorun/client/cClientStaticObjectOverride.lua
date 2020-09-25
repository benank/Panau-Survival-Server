local CSOCreate = ClientStaticObject.Create
local CSORemove = ClientStaticObject.Remove

CSOs = {}

function ClientStaticObject.Create(args)
	local cso = CSOCreate(args)
	local data = {cso = cso, values = {}}
	CSOs[cso:GetId()] = data
	Events:Fire("__CSO_Update", {id = cso:GetId(), data = data})
	return cso
end

function ClientStaticObject:Remove()
	Events:Fire("__CSO_Update", {id = self:GetId(), data = nil})
	CSOs[self:GetId()] = nil
	CSORemove(self)
end

function ClientStaticObject:SetValue(s, value)
	CSOs[self:GetId()].values[s] = value
	Events:Fire("__CSO_Update", {id = self:GetId(), data = CSOs[self:GetId()]})
end

function ClientStaticObject:GetValue(s)
	return CSOs[self:GetId()].values[s]
end

Events:Subscribe("__CSO_Update", function(args)
	CSOs[args.id] = args.data
end)