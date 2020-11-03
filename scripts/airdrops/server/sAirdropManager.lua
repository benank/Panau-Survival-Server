class 'sAirdropManager'

function sAirdropManager:__init()
    
    self.airdrops = {}

    self:InitializeAirdropsTable()

    Timer.SetInterval(1000 * 60 * 10, function()
        self:CheckIfShouldCreateAirdrop()
    end)

end

function sAirdropManager:InitializeAirdropsTable()
    for airdrop_type, _ in pairs(AirdropConfig.Spawn) do
        self.airdrops[airdrop_type] = {active = false}
    end
end

function sAirdropManager:CanCreateAirdropOfType(type)

    -- Airdrop is already active
    if self.airdrops[type].active then
        return false
    end

    -- Not enough time has passed since the last time an airdrop of this type was dropped
    if self.airdrops[type].cooldown_timer 
    and self.airdrops[type].cooldown_timer:GetMinutes() < AirdropConfig.Spawn[type].interval then
        return false
    end

    return true
end

-- Called every 10 minutes. Check player counts and in progress drops
function sAirdropManager:CheckIfShouldCreateAirdrop()

    local num_players_online = Server:GetPlayerCount()

    local spawn_type = 0 -- Airdrop type that we are going to spawn, 0 means that we are not going to spawn
    for type, data in pairs(AirdropConfig.Spawn) do
        if self:CanCreateAirdropOfType(type) then
            spawn_type = math.max(spawn_type, type) -- Max to get the highest level airdrop possible
        end
    end

    if spawn_type > 0 then
        self:BeginSpawningAirdrop(spawn_type)
    end

end

-- Called when an airdrop is beginning to spawn. First puts out announcement ingame and on discord, 
-- adds the zone to the map, and then eventually drops it
function sAirdropManager:BeginSpawningAirdrop(type)
    
end

sAirdropManager = sAirdropManager()