local oxygen = var(50)
local oxygen_per_sec_above = var(5)
local oxygen_per_sec_below = var(1)

function GetOxygen()
    local o2 = oxygen:get()
    if o2 then
        return tonumber(o2)
    else
        return 50
    end
end

Network:Subscribe("Survival/UpdateOxygen", function(args)
    oxygen:set(args.oxygen * 100)
end)


Events:Subscribe("Render", function(args)
    if LocalPlayer:GetHealth() > 0 and not LocalPlayer:GetValue("Loading") then
        LocalPlayer:SetOxygen(GetOxygen() / 100)
    else
        LocalPlayer:SetOxygen(1)
    end
end)

Events:Subscribe("SecondTick", function()
    if LocalPlayer:GetValue("Loading") or LocalPlayer:GetHealth() <= 0 then return end
    
    local above_water = LocalPlayer:GetBonePosition("ragdoll_Head").y > 199
    local current_oxygen = GetOxygen()
    
    if above_water then
        oxygen:set(math.min(100, current_oxygen + tonumber(oxygen_per_sec_above:get())))
    else
        oxygen:set(math.max(0, current_oxygen - tonumber(oxygen_per_sec_below:get())))
    end
    
    if current_oxygen ~= GetOxygen() then
        Network:Send("Survival/UpdateOxygen", {oxygen = GetOxygen() / 100})
    end
end)