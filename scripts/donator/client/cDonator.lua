class 'cDonator'

function cDonator:__init()

    self.close_donators = {} -- Players that are close that are also donators above level 1
    self.streaks = {} -- Donator streaks
    self.ghost_riders = {} -- Ghost riders
    self.shadow_wings = {} -- Shadow wings

    self.color_picker = HSVColorPicker.Create()
    self.color_picker:SetSize(Vector2(400,300))
    self.color_picker:SetPosition(Render.Size / 2 - self.color_picker:GetSize() / 2)
    self.color_picker:Hide()
    self.submit_button = Button.Create(self.color_picker)
    self.submit_button:SetText("Save")
    self.submit_button:SetTextSize(26)
    self.submit_button:SetHeight(40)
    self.submit_button:SetMargin(Vector2(0, 10), Vector2(0, 0))
    self.submit_button:SetDock(GwenPosition.Bottom)
    self.submit_button:Subscribe("Press", self, self.PressColorSubmitButton)

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

    Network:Subscribe("Donator/SetColor", self, self.DonatorSetColor)
    Network:Subscribe("Donator/SetTagColor", self, self.DonatorSetTagColor)
end

function cDonator:DonatorSetColor()
    self.color_picker:Show()
    self.setting_color = "name"
    Mouse:SetVisible(true)

    if not self.lpi then
        self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    end
end

function cDonator:DonatorSetTagColor()
    self.color_picker:Show()
    self.setting_color = "tag"
    Mouse:SetVisible(true)

    if not self.lpi then
        self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    end
end

function cDonator:LocalPlayerInput(args)
    return false
end

function cDonator:PressColorSubmitButton()
    local color = self.color_picker:GetColor()
    Mouse:SetVisible(false)
    Events:Unsubscribe(self.lpi)
    self.lpi = nil
    self.color_picker:Hide()

    Network:Send("Donator/SetColor", {
        color = color,
        type = self.setting_color
    })

    self.setting_color = nil
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
    elseif self.ghost_riders[steamID] and (donator_data.level < DonatorLevel.GhostRider or not donator_data.GhostRiderHeadEnabled) then
        self.ghost_riders[steamID]:Remove()
        self.ghost_riders[steamID] = nil
    end

end

function cDonator:CheckPlayer(player)

    local donator_data = player:GetValue("DonatorBenefits")
    local steamID = tostring(player:GetSteamId())

    if not donator_data then return end

    if donator_data.level >= DonatorLevel.Colorful then
        self:AddPlayer(player)

        -- Update color in case it has changed
        if self.streaks[steamID] then
            self.streaks[steamID].color = player:GetColor()
        end

        if not donator_data.ColorStreakEnabled and self.streaks[steamID] then
            self.streaks[steamID] = nil
        elseif donator_data.ColorStreakEnabled and not self.streaks[steamID] then
            self:AddPlayer(player)
        end
    end

end

function cDonator:SecondTick()

    for player in Client:GetStreamedPlayers() do
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