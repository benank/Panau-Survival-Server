class 'sSurvivalManager'


function sSurvivalManager:__init()


    self.timer = Timer()

    Network:Subscribe("Survival/Ready", self, self.PlayerReady)
    Network:Subscribe("Survival/UpdateClimateZone", self, self.UpdateClimateZone)
    Events:Subscribe("PostTick", self, self.PostTick)
    Events:Subscribe("PlayerDeath", self, self.PlayerDeath)
    Events:Subscribe("PlayerSpawn", self, self.PlayerSpawn)
    Events:Subscribe("Inventory/UseItem", self, self.UseItem)

end

function sSurvivalManager:UseItem(args)

    if not args.item or not IsValid(args.player) then return end

    local restore_data = config.items[args.item.name]
    if not restore_data then return end

    local survival = args.player:GetValue("Survival")

    survival.hunger = math.max(0, math.min(survival.hunger + restore_data.hunger, 100))
    survival.thirst = math.max(0, math.min(survival.thirst + restore_data.thirst, 100))

    if restore_data.health then -- If this food item restores health, like Energy Drink
        args.player:SetHealth(args.player:GetHealth() + restore_data.health / 100)
    end

    args.player:SetValue("Survival", survival)

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


    -- TODO CHECK IF THEY WERE DYING FROM HUNGER OR THIRST BEING 0

    self:SyncToPlayer(args.player)
    self:UpdateDB(args.player)
    
end

function sSurvivalManager:PlayerDeath(args)

    args.player:SetValue("dead", true)

end

function sSurvivalManager:UpdateClimateZone(args, player)

    if args.zone and config.decaymods[args.zone] then
        player:SetValue("ClimateZone", args.zone)
    else
        player:SetValue("ClimateZone", ClimateZone.Jungle)
    end

end

function sSurvivalManager:PlayerSpawn(args)

    -- Player Respawned
    if args.player:GetValue("dead") then

        Events:Fire("PlayerRespawned", {player = args.player})

        local survival = args.player:GetValue("Survival")

        survival.hunger = config.respawn.hunger
        survival.thirst = config.respawn.thirst

        args.player:SetValue("Survival", survival)

        self:SyncToPlayer(args.player)
        self:UpdateDB(args.player)

    end

    args.player:SetValue("dead", nil)

end

function sSurvivalManager:PostTick(args)

    if self.timer:GetSeconds() > 60 then

        for player in Server:GetPlayers() do

            self:AdjustSurvivalStats(player)

        end
        
        self.timer:Restart()

    end

end

function sSurvivalManager:AdjustSurvivalStats(player)

    local survival = player:GetValue("Survival")

    if not survival then return end

    local zone_mod = config.decaymods[player:GetValue("ClimateZone")]

    survival.hunger = math.max(survival.hunger - config.decay.hunger * zone_mod.hunger, 0)
    survival.thirst = math.max(survival.thirst - config.decay.thirst * zone_mod.thirst, 0)

    player:SetValue("Survival", survival)

    if survival.hunger or survival.thirst == 0 then

        -- ADD THEM TO THE KILL LIST

    end

    self:SyncToPlayer(player)
    self:UpdateDB(player)

end

function sSurvivalManager:PlayerReady(args, player)

    local steamID = tostring(player:GetSteamId().id)
    
	local query = SQL:Query("SELECT * FROM survival WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    if #result > 0 then -- if already in DB
        
        local data = 
        {
            hunger = result[1].hunger,
            thirst = result[1].thirst,
            radiation = result[1].radiation
        }

        player:SetValue("Survival", data)
        
    else
        
		local command = SQL:Command("INSERT INTO survival (steamID, hunger, thirst, radiation) VALUES (?, ?, ?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, config.defaults.hunger)
		command:Bind(3, config.defaults.thirst)
		command:Bind(4, config.defaults.radiation)
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

end

function sSurvivalManager:UpdateDB(player)

    local steamID = tostring(player:GetSteamId().id)
    local survival = player:GetValue("Survival")

    if not survival then return end
    
    local update = SQL:Command("UPDATE survival SET hunger = ?, thirst = ?, radiation = ? WHERE steamID = (?)")
	update:Bind(1, survival.hunger)
	update:Bind(2, survival.thirst)
	update:Bind(3, survival.radiation)
	update:Bind(4, steamID)
	update:Execute()


end

function sSurvivalManager:SyncToPlayer(player)

    if not IsValid(player) then return end
    if not player:GetValue("Survival") then return end

    Network:Send(player, "Survival/Update", player:GetValue("Survival"))

end

SQL:Execute("CREATE TABLE IF NOT EXISTS survival (steamID VARCHAR UNIQUE, hunger REAL, thirst REAL, radiation REAL)")

SurvivalManager = sSurvivalManager()