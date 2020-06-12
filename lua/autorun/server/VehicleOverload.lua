VehicleSetHealth = Vehicle.SetHealth
function Vehicle:SetHealth(amt)

    if not IsValid(self) then return end

    self:SetValue("Health", amt)

    if amt <= 0 then
        -- Kick players out of vehicle
        for _, player in pairs(self:GetOccupants()) do
            player:SetPosition(player:GetPosition())
        end
        self:SetNetworkValue("Destroyed", true)

        Events:Fire("Discord", {
            channel = "Vehicles",
            content = string.format("**Possible vehicle health hacking detected!** ")
        })
    end

    VehicleSetHealth(self, amt)

end

VehicleGetHealth = Vehicle.GetHealth
function Vehicle:GetHealth()
    if not IsValid(self) then return end
    
    local client_health = VehicleGetHealth(self)
    
    return client_health < self:GetValue("Health") and client_health or self:GetValue("Health")

end

function Vehicle:GetHealth_() if not IsValid(self) then return end return VehicleGetHealth(self) end
