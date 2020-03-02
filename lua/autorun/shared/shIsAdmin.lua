function IsAdmin(p)
    return IsValid(p) and p:GetValue("Nametag") and p:GetValue("Nametag").name == "Staff"
end

function IsStaff(p)
    return IsValid(p) and (IsAdmin(p) or IsMod(p))
end