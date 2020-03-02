function IsAdmin(p)
    return IsValid(p) and p:GetValue("NameTag") and p:GetValue("NameTag").name == "Staff"
end

function IsStaff(p)
    return IsValid(p) and IsAdmin(p)
end