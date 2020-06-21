class 'cExplosivesDetector'

function cExplosivesDetector:__init()

    self.nearby_explosives = {}

    self.active = false
    self.base_range = 50
    self.range = self.base_range

    self.circle_size = 12
    self.alpha = 255
    self.circle_color = Color(255, 0, 0, self.alpha)
    self.circle_color_owned = Color(0, 200, 0, self.alpha)
    self.border_color = Color(0, 0, 0, self.alpha)

    self.perks = 
    {
        [57] = {[2] = 1.25},
        [116] = {[2] = 1.5}
    }
    
    Thread(function()
        while true do
            self:CheckForNearbyExplosives()
            self:UpdateRangeBasedOnPerks()
            Timer.Sleep(1000)
        end
    end)
    
    Network:Subscribe(var("items/ToggleEquippedExplosivesDetector"):get(), self, self.ToggleEquipped)

end

function cExplosivesDetector:UpdateRangeBasedOnPerks()

    local perks = LocalPlayer:GetValue("Perks")

    if not perks then return end

    local perk_mod = 1

    for perk_id, perk_mod_data in pairs(self.perks) do
        local choice = perks.unlocked_perks[perk_id]
        if choice and perk_mod_data[choice] then
            perk_mod = math.max(perk_mod, perk_mod_data[choice])
        end
    end

    self.range = self.base_range * perk_mod

end

function cExplosivesDetector:CheckForNearbyExplosives()

    if not cClaymores or not cMines then return end

    local nearby_explosives = {}
    local local_pos = LocalPlayer:GetPosition()

    for id, obj in pairs(cClaymores.CSO_register) do
        local dist = obj.position:Distance(local_pos)
        if dist < self.range and IsValid(obj.object) then
            local is_friendly = obj.owner_id == tostring(LocalPlayer:GetSteamId()) or AreFriends(LocalPlayer, obj.owner_id)
            nearby_explosives[id] = {
                pos = obj.position, 
                name = string.format("Claymore%s", is_friendly and " (Friendly)" or " (Enemy)"), 
                is_mine = is_friendly,
                show_name = dist < self.range * 0.75}
        end
        Timer.Sleep(1)
    end

    for id, obj in pairs(cMines.CSO_register) do
        local dist = obj.position:Distance(local_pos)
        if dist < self.range and IsValid(obj.object) then
            local is_friendly = obj.owner_id == tostring(LocalPlayer:GetSteamId()) or AreFriends(LocalPlayer, obj.owner_id)
            nearby_explosives[id] = {
                pos = obj.position, 
                name = string.format("Mine%s", is_friendly and " (Friendly)" or " (Enemy)"), 
                is_mine = is_friendly,
                show_name = dist < self.range * 0.75}
        end
        Timer.Sleep(1)
    end

    self.nearby_explosives = nearby_explosives

end

function cExplosivesDetector:ToggleEquipped(args)

    self.active = args.equipped

    if self.active and not self.render then
        self.render = Events:Subscribe("Render", self, self.Render)
        cBattery:ToggleEnabled(true)
    elseif not self.active and self.render then
        Events:Unsubscribe(self.render)
        self.render = nil
        cBattery:ToggleEnabled(false)
    end

end

function cExplosivesDetector:Render(args)

    if cBattery:GetNumBatteries() == 0 then return end

    for id, data in pairs(self.nearby_explosives) do
        self:DrawExplosive(data)
    end

end

function cExplosivesDetector:DrawExplosive(data)
    local pos_2d, on_screen = Render:WorldToScreen(data.pos)

    if on_screen then
        local circle_adjustment = Vector2(self.circle_size / 2, self.circle_size / 2)
        local circle_pos = pos_2d - circle_adjustment

        local color = data.is_mine and self.circle_color_owned or self.circle_color

        Render:FillCircle(circle_pos, self.circle_size, self.border_color)
        Render:FillCircle(circle_pos, self.circle_size - 3, color)

        if data.show_name then
            self:DrawShadowedText(
                circle_pos + Vector2(self.circle_size / 2 + 8, -self.circle_size / 2 - 2), data.name, color, self.circle_size * 1.5)
        end
    end
end

function cExplosivesDetector:DrawShadowedText(pos, text, color, number)
    Render:DrawText(pos + Vector2(2,2), text, Color.Black, number)
    Render:DrawText(pos, text, color, number)
end

cExplosivesDetector = cExplosivesDetector()