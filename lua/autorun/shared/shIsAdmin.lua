function IsAdmin(p)
    return IsValid(p) and p:GetValue("NT_TagName") == "Staff"
end

function IsMod(p)
    return IsValid(p) and p:GetValue("NT_TagName") == "Mod"
end

function IsStaff(p)
    return IsValid(p) and (IsAdmin(p) or IsMod(p))
end