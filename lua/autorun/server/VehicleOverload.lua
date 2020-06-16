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

        local vehicle_data = self:GetValue("VehicleData")

        if vehicle_data.owner_steamid then
            Events:Fire("Discord", {
                channel = "Vehicles",
                content = string.format("**Possible vehicle health hacking detected!** Vehicle: %s Vehicle id: %d Owner steam id: %s",
                    vehicle_data.name, vehicle_data.vehicle_id, vehicle_data.owner_steamid)
            })
        end
    end

    VehicleSetHealth(self, amt)

end

VehicleGetHealth = Vehicle.GetHealth
function Vehicle:GetHealth()
    if not IsValid(self) then return end
    
    local client_health = VehicleGetHealth(self)
    if not client_health then return self:GetValue("Health") end
    if not self:GetValue("Health") then self:SetValue("Health", client_health) end
    
    return client_health < self:GetValue("Health") and client_health or self:GetValue("Health")

end

function Vehicle:GetHealth_() if not IsValid(self) then return end return VehicleGetHealth(self) end
