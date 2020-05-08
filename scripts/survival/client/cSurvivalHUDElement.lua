class 'cSurvivalHUDElement'

function cSurvivalHUDElement:__init(args)
    self.name = args.name
    self.percent = args.percent
    self.color = args.color
    self.type = args.type
    self.visible = args.visible

    self.large_size = args.large_size
    self.small_size = args.small_size
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

    Render:DrawText(Vector2.Zero, string.format("%s:", self.name), Color.White, 18)

    local text_size = Vector2(80, 0)
    local percent_size = Vector2(50, 0)
    local margin = 4

    Render:FillArea(
        text_size, 
        Vector2((self.large_size.x - text_size.x - percent_size.x) * self.percent, self.large_size.y), 
        self.color)

    SurvivalManager.hud:DrawBorder(text_size, self.large_size - percent_size)

    local percent_text = string.format("%.0f%%", self.percent * 100)
    local text_width = Render:GetTextWidth(percent_text, 18)
    Render:DrawText(Vector2(margin + self.large_size.x - percent_size.x / 2 - text_width / 2, 0), percent_text, Color.White, 18)

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

    Render:FillArea(
        Vector2.Zero, 
        Vector2(self.small_size.x * self.percent, self.small_size.y), 
        self.color)

    SurvivalManager.hud:DrawBorder(Vector2.Zero, self.small_size)
end