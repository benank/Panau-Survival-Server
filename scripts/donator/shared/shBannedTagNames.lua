BannedTagNames =  -- Custom tag names that people cannot use
{
    ["admin"] = true,
    ["dev"] = true,
    ["developer"] = true,
    ["staff"] = true,
    ["mod"] = true,
    ["moderator"] = true,
    ["owner"] = true
}

function CheckTagName(name)
    name = name:trim()
    if name:len() == 0 then return false end
    if BannedTagNames[name:lower()] then return end
    return true 
end