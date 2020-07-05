-- This overloads all Player API and makes sure the player is valid before executing methods
local v = function(p) return IsValid(p) end

PlayerBan = Player.Ban
function Player:Ban(reason) if not v(self) then return end PlayerBan(self, reason) end

PlayerClearInventory = Player.ClearInventory
function Player:ClearInventory() if not v(self) then return end PlayerClearInventory(self) end

PlayerDamage = Player.Damage
function Player:Damage(...) 
    if not v(self) then return end 
    local args = {...}
    local actual_health = self:GetValue("Health")
    local health = self:GetHealth_() < actual_health and self:GetHealth_() or actual_health

    local current_time = Server:GetElapsedSeconds()
    local last_check_time = self:GetValue("HealthLastCheckTime")

    if self:GetHealth_() > health then
        if last_check_time and current_time - last_check_time < 4 then
            self:SetHealth(health)
        else
            self:SetValue("Health", self:GetHealth_())
            health = self:GetHealth_()
        end
    end

    self:SetValue("Health", health - args[1])
    self:SetValue("HealthLastCheckTime", Server:GetElapsedSeconds())

    PlayerDamage(self, ...)

    if health - args[1] <= 0 then
        self:SetHealth(0)
        Events:Fire("Discord", {
            channel = "Hitdetection",
            content = string.format("**Possible health hacking detected!** %s [%s] was forced to die. Clientside health: %.2f Serverside health: %.2f",
                self:GetName(), tostring(self:GetSteamId()), health - args[1], self:GetHealth_())
        })
    end

end

PlayerDisableCollision = Player.PlayerDisableCollision
function Player:PlayerDisableCollision(group1, group2) if not v(self) then return end return PlayerDisableCollision(self, group1, group2) end

PlayerEnableCollision = Player.EnableCollision
function Player:EnableCollision(group1, group2) if not v(self) then return end return PlayerEnableCollision(self, group1, group2) end

PlayerGetAimTarget = Player.GetAimTarget
function Player:GetAimTarget() if not v(self) then return end return PlayerGetAimTarget(self) end

PlayerGetColor = Player.GetColor
function Player:GetColor() if not v(self) then return end return PlayerGetColor(self) end

PlayerGetEquippedSlot = Player.GetEquippedSlot
function Player:GetEquippedSlot() if not v(self) then return end return PlayerGetEquippedSlot(self) end

PlayerGetEquippedWeapon = Player.GetEquippedWeapon
function Player:GetEquippedWeapon() if not v(self) then return end return PlayerGetEquippedWeapon(self) end

PlayerGetHealth = Player.GetHealth
function Player:GetHealth() if not v(self) then return end return self:GetValue("Health") or self:GetHealth_() end

function Player:GetHealth_() if not v(self) then return end return PlayerGetHealth(self) end

PlayerGetId = Player.GetId
function Player:GetId() if not v(self) then return end return PlayerGetId(self) end

PlayerGetIP = Player.GetIP
function Player:GetIP() if not v(self) then return end return PlayerGetIP(self) end

PlayerGetInventory = Player.GetInventory
function Player:GetInventory() if not v(self) then return end return PlayerGetInventory(self) end

PlayerGetLinearVelocity = Player.GetLinearVelocity
function PlayerGetLinearVelocity() if not v(self) then return end return PlayerGetLinearVelocity(self) end

PlayerGetModelId = Player.GetModelId
function Player:GetModelId() if not v(self) then return end return PlayerGetModelId(self) end

PlayerGetName = Player.GetName
function Player:GetName() if not v(self) then return end return PlayerGetName(self) end

PlayerGetParachuting = Player.GetParachuting
function Player:GetParachuting() if not v(self) then return end return PlayerGetParachuting(self) end

PlayerGetPing = Player.GetPing
function Player:GetPing() if not v(self) then return end return PlayerGetPing(self) end

PlayerGetState = Player.GetState
function Player:GetState() if not v(self) then return end return PlayerGetState(self) end

PlayerGetSteamId = Player.GetSteamId
function Player:GetSteamId() if not v(self) then return end return PlayerGetSteamId(self) end

PlayerGetVehicle = Player.GetVehicle
function Player:GetVehicle() if not v(self) then return end return PlayerGetVehicle(self) end

PlayerGiveWeapon = Player.GiveWeapon
function Player:GiveWeapon(number, weapon) if not v(self) then return end return PlayerGiveWeapon(self,number, weapon) end

PlayerKick = Player.Kick
function Player:Kick(reason) if not v(self) then return end return PlayerKick(self, reason) end

PlayerSetAngle = Player.SetAngle
function Player:SetAngle(angle) if not v(self) then return end return PlayerSetAngle(self, angle) end

PlayerSetColor = Player.SetColor
function Player:SetColor(color) if not v(self) then return end return PlayerSetColor(self, color) end

PlayerSetHealth = Player.SetHealth
function Player:SetHealth(health) if not v(self) then return end self:SetValue("Health", health) return PlayerSetHealth(self, health) end

PlayerSetModelId = Player.SetModelId
function Player:SetModelId(num) if not v(self) then return end return PlayerSetModelId(self, num) end

PlayerSetPosition = Player.SetPosition
function Player:SetPosition(pos) if not v(self) then return end return PlayerSetPosition(self, pos) end

PlayerTeleport = Player.Teleport
function Player:Teleport(pos, angle) if not v(self) then return end return PlayerTeleport(self, pos, angle) end

PlayerGetAngle = Player.GetAngle
function Player:GetAngle() if not v(self) then return end return PlayerGetAngle(self) end

PlayerGetPosition = Player.GetPosition
function Player:GetPosition() if not v(self) then return end return PlayerGetPosition(self) end

PlayerGetStreamDistance = Player.GetStreamDistance
function Player:GetStreamDistance() if not v(self) then return end return PlayerGetStreamDistance(self) end

PlayerSetEnabled = Player.SetEnabled
function Player:SetEnabled(enabled) if not v(self) then return end return PlayerSetEnabled(self, enabled) end

PlayerSetStreamDistance = Player.SetStreamDistance
function Player:SetStreamDistance(distance) if not v(self) then return end return PlayerSetStreamDistance(self, distance) end

PlayerGetValue = Player.GetValue
function Player:GetValue(string) if not v(self) then return end return PlayerGetValue(self, string) end

PlayerSetNetworkValue = Player.SetNetworkValue
function Player:SetNetworkValue(string, object) if not v(self) then return end return PlayerSetNetworkValue(self, string, object) end

PlayerSetValue = Player.SetValue
function Player:SetValue(string, object) if not v(self) then return end return PlayerSetValue(self, string, object) end