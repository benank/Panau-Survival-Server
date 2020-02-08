function IsAdmin(p)
    return IsValid(p) and p:GetValue("NT_TagName") == "Admin"
end

function IsMod(p)
    return IsValid(p) and p:GetValue("NT_TagName") == "Mod"
end

function IsStaff(p)
    return IsValid(p) and (IsAdmin(p) or IsMod(p))
end