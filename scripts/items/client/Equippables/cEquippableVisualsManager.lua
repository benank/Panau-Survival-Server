class 'cEquippableVisualsManager'

function cEquippableVisualsManager:__init()

    self.nearby_players = {} -- Nearby players with equipped visuals

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function cEquippableVisualsManager:ModuleUnload()
    for id, visual in pairs(self.nearby_players) do
        visual:Remove()
    end
end

function cEquippableVisualsManager:Render(args)

    for id, visual in pairs(self.nearby_players) do

        if IsValid(visual.player) then
            visual:Render()
        else
            visual:Remove()
            self.nearby_players[id] = nil
        end

    end

end

-- Checks to see if a player has at least one visual item equipped
function cEquippableVisualsManager:CheckPlayer(player)

    if player:GetValue("Loading") then return end

    local equipped_visuals = player:GetValue("EquippedVisuals")
    local steamID = tostring(player:GetSteamId())

    if self.nearby_players[steamID] then

        if count_table(equipped_visuals) == 0 then
            self.nearby_players[steamID]:Remove()
            self.nearby_players[steamID] = nil
        else
            self.nearby_players[steamID].equipped_visuals = equipped_visuals
            self.nearby_players[steamID]:Update()
        end

    else

        if count_table(equipped_visuals) > 0 then
            self.nearby_players[steamID] = cEquippableVisualPlayer({player = player, equipped_visuals = equipped_visuals})
        end

    end

    if not self.render and count_table(self.nearby_players) > 0 then
        self.render = Events:Subscribe("Render", self, self.Render)
    elseif self.render and count_table(self.nearby_players) == 0 then
        Events:Unsubscribe(self.render)
        self.render = nil
    end

end

function cEquippableVisualsManager:SecondTick()

    if LocalPlayer:GetValue("Loading") then return end
    self:CheckPlayer(LocalPlayer)

    for p in Client:GetStreamedPlayers() do
        self:CheckPlayer(p)
    end

end

cEquippableVisualsManager = cEquippableVisualsManager()