class 'cSurvivalHUDElement'

function cSurvivalHUDElement:__init(args)
    self.name = args.name
    self.percent = args.percent
    self.percent2 = args.percent2
    self.color = args.color
    self.color2 = args.color2
    self.type = args.type
    self.visible = args.visible
    self.dual = args.dual

    self.large_size = args.large_size
    self.small_size = args.small_size

    self.dual_complete_color = Color(190, 190, 190, 150)

    if self.dual then
        self.level = 0
        self:UpdateExp()
        Events:Subscribe("PlayerExpUpdated", function(args)
            self:UpdateExp()
        end)
    end
end

function cSurvivalHUDElement:UpdateExp()

    local exp_data = LocalPlayer:GetValue("Exp")
    if not exp_data then return end

    self.percent = exp_data.combat_exp / exp_data.combat_max_exp
    self.percent2 = exp_data.explore_exp / exp_data.explore_max_exp
    self.level = exp_data.level
end

-- Renders the large version of the element
function cSurvivalHUDElement:RenderLarge()

    if self.type == "separator" then
        Render:FillArea(
            -SurvivalManager.hud.border_size, 
            self.large_size + SurvivalManager.hud.border_size, 
            self.color)
        return
    end

    local conversion = Render.Size.y / 1080

    local text = string.format("%s:", self.name)

    if self.level then
        text = string.format("%s %s:", self.name, self.level)
    end

    Render:DrawText(Vector2.Zero, text, Color.White, 18 * conversion)

    local text_size = Vector2(self.level == 100 and 90 or 80, 0) * conversion
    local percent_size = Vector2(50, 0)
    local margin = 4

    local fill_size_y = self.large_size.y
    local fill_size_x = self.large_size.x - text_size.x - percent_size.x

    if self.dual then
        fill_size_y = fill_size_y / 2
    end

    local percent = math.min(1, math.floor(self.percent * 100) / 100)
    
    Render:FillArea(
        text_size, 
        Vector2(fill_size_x * percent, fill_size_y), 
        self.color)

    if self.dual then
        Render:FillArea(
            text_size + Vector2(0, fill_size_y), 
            Vector2(fill_size_x * self.percent2, fill_size_y), 
            self.color2)
    end

    SurvivalManager.hud:DrawBorder(text_size, self.large_size - percent_size)

    local percent_text = string.format("%.0f%%", math.floor(self.percent * 100))

    if self.dual then
        percent_text = string.format("%.0f%%", math.floor((self.percent + self.percent2) * 100 / 2))
    end

    local text_width = Render:GetTextWidth(percent_text, 18)
    Render:DrawText(Vector2(margin + self.large_size.x - percent_size.x / 2 - text_width / 2, 0), percent_text, Color.White, 18 * conversion)

end

-- Renders the small version of the element
function cSurvivalHUDElement:RenderSmall()

    if self.type == "separator" then
        Render:FillArea(
            -SurvivalManager.hud.border_size, 
            self.small_size + SurvivalManager.hud.border_size, 
            self.color)
        return
    end

    local fill_size_y = self.small_size.y
    local fill_size_x = self.small_size.x

    if self.dual then
        fill_size_y = fill_size_y / 2
    end

    local percent = math.min(1, math.floor(self.percent * 100) / 100)
    
    Render:FillArea(
        Vector2.Zero, 
        Vector2(fill_size_x * percent, fill_size_y), 
        self.color)

    if self.dual then
        local percent_2 = math.floor(self.percent2 * 100) / 100
        Render:FillArea(
            Vector2(0, fill_size_y), 
            Vector2(fill_size_x * self.percent2, fill_size_y), 
            self.color2)
    end


    SurvivalManager.hud:DrawBorder(Vector2.Zero, self.small_size)
end