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
