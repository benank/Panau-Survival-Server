function IsAdmin(p)
    return IsValid(p) and p:GetValue("Admin") == true
end