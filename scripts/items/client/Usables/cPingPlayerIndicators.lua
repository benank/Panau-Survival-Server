class 'cPingPlayerIndicators'

function cPingPlayerIndicators:__init()

    self.name_show_time = 15 -- Names are shown for x seconds after a ping
    self.text_size = 26

    self.current_showing_names = {} -- Currently showing players

end

-- Adds a new player to be shown. Must contain: position, name, id
function cPingPlayerIndicators:AddPlayer(data)

    if data.id == LocalPlayer:GetId() then return end -- No pings on localplayer

    self.current_showing_names[data.id] = {position = data.position, name = data.name, time = Client:GetElapsedSeconds()}

    if not self.render then
        self.render = Events:Subscribe("Render", self, self.Render)
    end

end

function cPingPlayerIndicators:Render(args)

    local current_time = Client:GetElapsedSeconds()
    local local_pos = LocalPlayer:GetPosition()

    for id, data in pairs(self.current_showing_names) do

        self:RenderPlayer(data, local_pos, current_time)

        -- Time is up, remove name from rendering
        if current_time - data.time > self.name_show_time then
            self.current_showing_names[id] = nil
        end 

    end

end

function cPingPlayerIndicators:RenderPlayer(data, local_pos, time)

    local pos_2d, on_screen = Render:WorldToScreen(data.position)

    if not on_screen then return end

    local t = Transform2()
    t:Translate(pos_2d)
    Render:SetTransform(t)

    local alpha = math.max(0, 255 - 255 * (time - data.time) / self.name_show_time)
    local color = Color(201, 196, 191, alpha)

    local name = data.name
    local text_size = Render:GetTextSize(name, self.text_size)

    self:DrawShadowedText(Vector2(-text_size.x / 2, -text_size.y * 1.25), name, color, self.text_size)

    local dist = data.position:Distance(local_pos)
    local text = string.format("%.0fm", dist)
    if dist > 1000 then
        text = string.format("%.1fkm", dist / 1000)
    end

    text_size = Render:GetTextSize(text, self.text_size / 2)

    self:DrawShadowedText(Vector2(-text_size.x / 2, 0), text, color, self.text_size / 2)

    Render:ResetTransform()

end

function cPingPlayerIndicators:DrawShadowedText(pos, text, color, number)
    Render:DrawText(pos + Vector2(2,2), text, Color(0,0,0,color.a), number)
    Render:DrawText(pos, text, color, number)
end

cPingPlayerIndicators = cPingPlayerIndicators()