class 'sSurvivalManager'


function sSurvivalManager:__init()

    self.players_dying = {} -- Players who are dying from hunger or thirst being 0
    self.damage_interval = 5 -- Every 5 seconds, dying players are damaged

    self.perks = 
    {
        [90] = 0.8,
        [163] = 0.6,
        [200] = 0.4,
        [225] = 0.2
    }

    self:SetupIntervals()

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Network:Subscribe("Survival/UpdateClimateZone", self, self.UpdateClimateZone)
    Events:Subscribe("PlayerSpawn", self, self.PlayerSpawn)
    Events:Subscribe("Inventory/UseItem", self, self.UseItem)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("LoadStatus", self, self.LoadStatus)

end

-- Set player's health after the loading screen
function sSurvivalManager:LoadStatus(args)
    if not IsValid(args.player) then return end
    if args.status ~= false then return end
    if not args.player:GetValue("TargetHealth") then return end

    args.player:SetHealth(args.player:GetValue("TargetHealth"))
    args.player:SetValue("Health", args.player:GetValue("TargetHealth"))
    args.player:SetValue("TargetHealth", nil)
end

function sSurvivalManager:PlayerQuit(args)
    self:UpdateDB(args.player)
end

function sSurvivalManager:CheckForDyingPlayer(player)

    local survival = player:GetValue("Survival")

    if survival.hunger == 0 or survival.thirst == 0 then
        self.players_dying[tostring(player:GetSteamId())] = player
    elseif survival.hunger > 0 and survival.thirst > 0 then
        self.players_dying[tostring(player:GetSteamId())] = nil
    end

end

function sSurvivalManager:UseItem(args)

    if not args.item or not IsValid(args.player) then return end

    local restore_data = config.items[args.item.name]
    if not restore_data then return end

    local survival = args.player:GetValue("Survival")

    survival.hunger = math.max(0, math.min(survival.hunger + restore_data.hunger, 100))
    survival.thirst = math.max(0, math.min(survival.thirst + restore_data.thirst, 100))

    if restore_data.health then -- If this food item restores health, like Energy Drink
        args.player:SetValue("Health", math.min(1, args.player:GetHealth() + restore_data.health / 100))
        args.player:Damage(-restore_data.health / 100, DamageEntity.Food)
    end

    args.player:SetValue("Survival", survival)
    self:CheckForDyingPlayer(args.player)

    if not args.item.durable then

        Inventory.RemoveItem({
            player = args.player,
            item = args.item,
            index = args.index
        })

    else -- CamelBak

        args.item.durability = args.item.durability - restore_data.dura_per_use

        Inventory.ModifyDurability({
            player = args.player,
            item = args.item,
            index = args.index
        })

    end

    self:SyncToPlayer(args.player)
    self:UpdateDB(args.player)
    
end

function sSurvivalManager:UpdateClimateZone(args, player)

    if args.zone and config.decaymods[args.zone] then
        player:SetValue("ClimateZone", args.zone)
    else
        player:SetValue("ClimateZone", ClimateZone.Jungle)
    end

end

function sSurvivalManager:PlayerSpawn(args)

    if not IsValid(args.player) then return end

    -- Player Respawned
    if args.player:GetValue("dead") then

        Events:Fire("PlayerRespawned", {player = args.player})

        local survival = args.player:GetValue("Survival")

        if not survival then return end

        if not args.player:GetValue("Suicided") then
            survival.hunger = config.respawn.hunger
            survival.thirst = config.respawn.thirst
        end

        args.player:SetValue("Survival", survival)
        self:CheckForDyingPlayer(args.player)

        self:SyncToPlayer(args.player)
        self:UpdateDB(args.player)

    end

    args.player:SetValue("Suicided", nil)
end

function sSurvivalManager:SetupIntervals()

    Timer.SetInterval(1000 * 60, function()
        for player in Server:GetPlayers() do
            if IsValid(player) then
                self:AdjustSurvivalStats(player)
            end
        end
    end)

    Timer.SetInterval(1000 * self.damage_interval, function()
        self:DamageDyingPlayers()
    end)

end

function sSurvivalManager:DamageDyingPlayers()

    for id, player in pairs(self.players_dying) do
        if not IsValid(player) then
            self.players_dying[id] = nil
        else

            local survival = player:GetValue("Survival")
            if survival.hunger == 0 then
                Events:Fire("HitDetection/PlayerSurvivalDamage", {
                    type = DamageEntity.Hunger,
                    amount = 0.03,
                    player = player
                })
            end

            if survival.thirst == 0 then
                Events:Fire("HitDetection/PlayerSurvivalDamage", {
                    type = DamageEntity.Thirst,
                    amount = 0.05,
                    player = player
                })
            end
        end

    end

end

function sSurvivalManager:AdjustSurvivalStats(player)

    local survival = player:GetValue("Survival")

    if not survival then return end
    if player:GetValue("InSafezone") then return end
    if player:GetValue("Invincible") then return end

    local zone_mod = config.decaymods[player:GetValue("ClimateZone")] or config.decaymods[ClimateZone.City]

    local perks = player:GetValue("Perks")

    if not perks then return end

    local perk_mod = 1

    for perk_id, perk_mod_data in pairs(self.perks) do
        if perks.unlocked_perks[perk_id] then
            perk_mod = math.min(perk_mod, perk_mod_data)
        end
    end

    survival.hunger = math.max(survival.hunger - config.decay.hunger * zone_mod.hunger * perk_mod, 0)
    survival.thirst = math.max(survival.thirst - config.decay.thirst * zone_mod.thirst * perk_mod, 0)

    player:SetValue("Survival", survival)
    self:CheckForDyingPlayer(player)

    self:SyncToPlayer(player)

    local diff = Server:GetElapsedSeconds() - player:GetValue("SurvivalLastUpdate")

    if diff > 120 then
        self:UpdateDB(player)
        player:SetValue("SurvivalLastUpdate", Server:GetElapsedSeconds())
    end

end

function sSurvivalManager:ClientModuleLoad(args)

    local player = args.player
    local steamID = tostring(player:GetSteamId())
    
	local query = SQL:Query("SELECT * FROM survival WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        
        local data = 
        {
            hunger = tonumber(result[1].hunger),
            thirst = tonumber(result[1].thirst),
            radiation = tonumber(result[1].radiation)
        }

        -- Don't set health here because it's too early and won't work
        player:SetValue("TargetHealth", tonumber(result[1].health))
        player:SetValue("Health", tonumber(result[1].health))

        player:SetValue("Survival", data)
        
    else
        
		local command = SQL:Command("INSERT INTO survival (steamID, health, hunger, thirst, radiation) VALUES (?, ?, ?, ?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, 1)
		command:Bind(3, config.defaults.hunger)
		command:Bind(4, config.defaults.thirst)
		command:Bind(5, config.defaults.radiation)
        command:Execute()

        local data = 
        {
            hunger = config.defaults.hunger,
            thirst = config.defaults.thirst,
            radiation = config.defaults.radiation
        }

        player:SetValue("Survival", data)
        
    end
    
    self:SyncToPlayer(player)
    self:CheckForDyingPlayer(player)

    player:SetValue("SurvivalLastUpdate", Server:GetElapsedSeconds())

end

function sSurvivalManager:UpdateDB(player)

    if not IsValid(player) then return end

    local steamID = tostring(player:GetSteamId())
    local survival = player:GetValue("Survival")

    if not survival then return end

    local health = player:GetHealth_()
    if health <= 0 then health = 1 end
    
    local update = SQL:Command("UPDATE survival SET health = ?, hunger = ?, thirst = ?, radiation = ? WHERE steamID = (?)")
	update:Bind(1, health)
	update:Bind(2, survival.hunger)
	update:Bind(3, survival.thirst)
	update:Bind(4, survival.radiation)
	update:Bind(5, steamID)
    update:Execute()
    
end

function sSurvivalManager:SyncToPlayer(player)

    if not IsValid(player) then return end
    if not player:GetValue("Survival") then return end

    Network:Send(player, "Survival/Update", player:GetValue("Survival"))

end

SQL:Execute("CREATE TABLE IF NOT EXISTS survival (steamID VARCHAR UNIQUE, health REAL, hunger REAL, thirst REAL, radiation REAL)")

SurvivalManager = sSurvivalManager()