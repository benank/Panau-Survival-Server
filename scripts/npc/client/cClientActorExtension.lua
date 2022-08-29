function ClientActor:GetClosestBone(position)
    local bones = self:GetBones()
    local closest_bone_distance = 999999
    local closest_bone = "ragdoll_Spine"
    
    for bone_name, bone in pairs(bones) do
        if BoneEnum:GetDescription(bone_name) ~= nil then
            local distance = Vector3.Distance(position, bone.position)
            if distance < closest_bone_distance then
                closest_bone_distance = distance
                closest_bone = bone_name
            end
        end
    end

    return closest_bone
end

local CACreate = ClientActor.Create
local CARemove = ClientActor.Remove

CAs = {}

function ClientActor.Create(actor_profile_instance, args)
    local client_actor = CACreate(1, args)
    CAs[client_actor:GetId()] = {ca = client_actor, values = {}}
    client_actor:SetValue("ActorProfileInstance", actor_profile_instance)
	return client_actor
end

function ClientActor:Remove()
    self:SetValue("ActorProfileInstance", nil)
	CAs[self:GetId()] = nil
	CARemove(self)
end

function ClientActor:SetValue(s, value)
	CAs[self:GetId()].values[s] = value
end

function ClientActor:GetValue(s)
	return CAs[self:GetId()].values[s]
end
