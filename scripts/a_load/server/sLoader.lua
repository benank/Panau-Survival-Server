class 'sLoader'

function sLoader:__init()

    self.default_stream_distance = 1024

    Events:Subscribe("PlayerJoin", self, self.PlayerJoin)
    Events:Subscribe("PlayerDeath", self, self.PlayerDeath)
    Events:Subscribe("PlayerSpawn", self, self.PlayerSpawn)

    Network:Subscribe("LoadStatus", self, self.LoadStatus)
end

function sLoader:PlayerJoin(args)
    self:TogglePlayerEnabled(args.player, false)
    Chat:Send(args.player, 
        "Hi! Welcome to Panau Survival. Get food and gear from lootboxes, fight drones and players to level up, and build a base and defend your loot from raiders! If you need help, please check out our " , Color.White, 
        "Panau Survival Guide ", Color.Orange,
        "by pressing ", Color.White,
        "SHIFT + TAB ", Color.Yellow,
        "and going to the \"Guides\" section. If you need extra help, feel free to join our Discord. Link is in the guide!", Color.White)

end

function sLoader:PlayerDeath(args)
    args.player:SetValue("dead", true)
    Timer.SetTimeout(5000, function()
        self:TogglePlayerEnabled(args.player, false)
    end)
end

function sLoader:PlayerSpawn(args)
    self:TogglePlayerEnabled(args.player, false)
end

function sLoader:LoadStatus(args, player)
    if not IsValid(player) then return end

    if args and args.status == "done" then

        player:SetValue("dead", nil)
        self:TogglePlayerEnabled(player, true)

        Events:Fire("LoadStatus", {player = player, status = not (args and args.status == "done")})
    else
        self:TogglePlayerEnabled(player, false)
    end
    
end

function sLoader:TogglePlayerEnabled(player, enabled)
    if not IsValid(player) then return end
    if not enabled then

        player:SetValue("Loading", true)
        player:SetStreamDistance(0)
        player:SetEnabled(false)

    elseif enabled then

        player:SetEnabled(true)
        player:SetStreamDistance(self.default_stream_distance)
        player:SetValue("Loading", false)

    end
end

sLoader = sLoader()