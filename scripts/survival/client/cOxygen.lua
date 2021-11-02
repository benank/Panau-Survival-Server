local oxygen = var(0.5)
local oxygen_per_sec_above = var(0.05)
local oxygen_per_sec_below = var(-0.01)

function GetOxygen()
    local o2 = oxygen:get()
    if o2 then
        return tonumber(o2)
    else
        return 0.5
    end
end

Network:Subscribe("Survival/UpdateOxygen", function(args)
    oxygen:set(args.oxygen)
end)


Events:Subscribe("Render", function(args)
    if LocalPlayer:GetHealth() > 0 and not LocalPlayer:GetValue("Loading") then
        LocalPlayer:SetOxygen(GetOxygen())
    else
        LocalPlayer:SetOxygen(1)
    end
end)

Events:Subscribe("SecondTick", function()
    if LocalPlayer:GetValue("Loading") or LocalPlayer:GetHealth() <= 0 then return end
    
    local above_water = LocalPlayer:GetBonePosition("ragdoll_Head").y > 199
    local current_oxygen = GetOxygen()
    
    if above_water then
        oxygen:set(math.min(1, current_oxygen + tonumber(oxygen_per_sec_above:get())))
    else
        oxygen:set(math.min(1, current_oxygen + tonumber(oxygen_per_sec_below:get())))
    end
    
    if current_oxygen ~= GetOxygen() then
        Network:Send("Survival/UpdateOxygen", {oxygen = GetOxygen()})
    end
end)