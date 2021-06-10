class 'PlayerRadar'

function PlayerRadar:__init()
    
    self.nearby_players = {}
    self.fade_time = 5 -- seconds to fade
    self.alpha = 255
    
    Network:Subscribe("items/UpdateRadarPlayers", self, self.UpdatePlayerRadars)
end

function PlayerRadar:UpdatePlayerRadars(nearby_players)
    
    self.nearby_players = nearby_players
    self.alpha = 255
    
    if not self.render then
        self.render = Events:Subscribe("PostRender", self, self.Render)
    end
end

function PlayerRadar:Render(args)
    
    local circle_size = 5
    local circle_size_half = Vector2(circle_size, circle_size) / 2
    
    for _, position in pairs(self.nearby_players) do
        local minimap_pos, on_screen = Render:WorldToMinimap(position)
        
        if on_screen and Game:GetState() == GUIState.Game then
            Render:FillCircle(minimap_pos - circle_size_half, circle_size, Color(255, 0, 0, self.alpha))
        end
    end
    
    self.alpha = math.max(0, self.alpha - (255 / self.fade_time) * args.delta)
    
    if self.alpha == 0 then
        self.render = Events:Unsubscribe(self.render)
    end
end

PlayerRadar()