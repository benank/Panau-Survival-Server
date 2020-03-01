class 'cDonator'

function cDonator:__init()

    self.close_donators = {} -- Players that are close that are also donators above level 1
    self.streaks = {} -- Donator streaks
    self.ghost_riders = {} -- Ghost riders
    self.shadow_wings = {} -- Shadow wings

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function cDonator:ModuleUnload()
    
    for id, ghost_rider in pairs(self.ghost_riders) do
        ghost_rider:Remove()
    end

end

function cDonator:GameRender(args)

    for id, player in pairs(self.close_donators) do
        if not IsValid(player) then
            self.close_donators[id] = nil
            self.streaks[id] = nil
            if self.ghost_riders[id] then
                self.ghost_riders[id]:Remove()
                self.ghost_riders[id] = nil
            end
        end
    end

    for id, streak in pairs(self.streaks) do
        streak:Render(args)
    end

    for id, ghost_rider in pairs(self.ghost_riders) do
        ghost_rider:Render(args)
    end

end

function cDonator:AddPlayer(player)
    
    local steamID = tostring(player:GetSteamId())
    local donator_data = player:GetValue("DonatorBenefits")
    self.close_donators[steamID] = player

    if donator_data.level >= DonatorLevel.Colorful and donator_data.ColorStreakEnabled and not self.streaks[steamID] then
        self.streaks[steamID] = StreakBone(player, "ragdoll_Hips", "ragdoll_Neck", player:GetColor(), 2)
    elseif self.streaks[steamID] and (donator_data.level < DonatorLevel.Colorful or not donator_data.ColorStreakEnabled) then
        self.streaks[steamID] = nil
    end

    if donator_data.level >= DonatorLevel.GhostRider and donator_data.GhostRiderHeadEnabled and not self.ghost_riders[steamID] then
        self.ghost_riders[steamID] = GhostRider(player)
    elseif self.ghost_riders[steamID] and (donator_data.level < DonatorLevel.GhostRider or not donator_data.GhostRider) then
        self.ghost_riders[steamID]:Remove()
        self.ghost_riders[steamID] = nil
    end

end

function cDonator:CheckPlayer(player)

    local donator_data = player:GetValue("DonatorBenefits")
    local steamID = tostring(player:GetSteamId())

    if not donator_data then return end

    if donator_data.level >= DonatorLevel.Colorful then
        if not self.close_donators[steamID] then
            self:AddPlayer(player)
        end

        -- Update color in case it has changed
        if self.streaks[steamID] then
            self.streaks[steamID].color = player:GetColor()
        end
    end

end

function cDonator:SecondTick()

    for player in Client:GetPlayers() do
        self:CheckPlayer(player)
    end

    self:CheckPlayer(LocalPlayer)

    if count_table(self.close_donators) > 0 and not self.render then
        self.render = Events:Subscribe("GameRender", self, self.GameRender)
    elseif count_table(self.close_donators) == 0 and self.render then
        Events:Unsubscribe(self.render)
        self.render = nil
    end

end

cDonator = cDonator()