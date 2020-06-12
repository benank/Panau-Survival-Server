class "BoneEnum"

-- picture of where bones are:
-- https://wiki.jc-mp.com/Lua/Client/Character/Functions/GetBones
function BoneEnum:__init()
    self.Head = "ragdoll_Head"
    self.Neck = "ragdoll_Neck"
    self.Spine1 = "ragdoll_Spine1"
    self.Spine2 = "ragdoll_Spine"
    self.Hips = "ragdoll_Hips"
    self.LeftForeArm = "ragdoll_LeftForeArm"
    self.RightForeArm = "ragdoll_RightForeArm"
    self.LeftArm = "ragdoll_LeftArm"
    self.RightArm = "ragdoll_RightArm"
    self.UpperLeftLeg = "ragdoll_LeftUpLeg"
    self.UpperRightLeg = "ragdoll_RightUpLeg"
    self.RightLeg = "ragdoll_RightLeg"
    self.LeftLeg = "ragdoll_LeftLeg"
    self.RightFoot = "ragdoll_RightFoot"
    self.LeftFoot = "ragdoll_LeftFoot"
    self.RightHand = "ragdoll_RightHand"
    self.LeftHand = "ragdoll_LeftHand"

    self.descriptions = {
        [self.Head] = "Head",
        [self.Neck] = "Neck",
        [self.Spine1] = "Spine",
        [self.Spine2] = "Spine",
        [self.Hips] = "Hips",
        [self.LeftForeArm] = "ragdoll_LeftForeArm",
        [self.RightForeArm] = "ragdoll_RightForeArm",
        [self.LeftArm] = "ragdoll_LeftArm",
        [self.RightArm] = "ragdoll_RightArm",
        [self.UpperLeftLeg] = "ragdoll_LeftUpLeg",
        [self.UpperRightLeg] = "ragdoll_RightUpLeg",
        [self.RightLeg] = "ragdoll_RightLeg",
        [self.LeftLeg] = "ragdoll_LeftLeg",
        [self.RightFoot] = "ragdoll_RightFoot",
        [self.LeftFoot] = "ragdoll_LeftFoot",
        [self.RightHand] = "ragdoll_RightHand",
        [self.LeftHand] = "ragdoll_LeftHand"
    }
    
end

function BoneEnum:GetDescription(bone_enum)
    return self.descriptions[bone_enum]
end

BoneEnum = BoneEnum()