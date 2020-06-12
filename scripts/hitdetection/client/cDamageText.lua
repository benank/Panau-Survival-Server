class 'cDamageText'

function cDamageText:__init()

    self.texts = {}

    self.max_shown_time = 1 -- 1 second max shown time for each text
    self.damage_text_speed = 75
    self.text_size = 16
    self.o_size = 2 -- Outline size

end

--[[
    Adds a new floating damage text to the screen.

    args (in table):
        position: vector3 of the point where the damage hit
        amount: number of how much damage was done
        color (optional): base color to use (like for headshots)
        size (optional): bigger size (like for headshots)

]]
function cDamageText:Add(args)

    table.insert(self.texts, {
        position = args.position,
        amount = (args.amount < 1 and args.amount > 0) and string.format("%.2f", args.amount) or string.format("%.0f", args.amount),
        time = Client:GetElapsedSeconds(),
        dir = Vector2(math.random() - 0.5, math.random() - 0.5):Normalized(),
        color = args.color or Color.White,
        size = args.size or self.text_size 
    })

    if not self.render then
        self.render = Events:Subscribe("Render", self, self.Render)
    end

end

function cDamageText:Render(args)

    local time = Client:GetElapsedSeconds()

    for index, data in pairs(self.texts) do

        local time_diff = time - data.time

        if time_diff >= self.max_shown_time then
            self.texts[index] = nil
        else

            local pos, on_screen = Render:WorldToScreen(data.position)
            pos = pos + data.dir * time_diff / self.max_shown_time * self.damage_text_speed

            if on_screen then

                local color = Color(data.color.r, data.color.g, data.color.b, 0)
                color.a = 255 - 255 * time_diff / self.max_shown_time

                self:RenderOutlinedText(pos, data.amount, color, data.size)

            end

        end

    end

end

function cDamageText:RenderOutlinedText(pos, text, color, size)

    local black = Color(0, 0, 0, color.a)
    local text_size = Render:GetTextSize(text, size)
    local centered_pos = pos - text_size / 2

    Render:DrawText(centered_pos + Vector2(-self.o_size, 0), text, black, size)
    Render:DrawText(centered_pos + Vector2(self.o_size, 0), text, black, size)
    Render:DrawText(centered_pos + Vector2(0, self.o_size), text, black, size)
    Render:DrawText(centered_pos + Vector2(0, -self.o_size), text, black, size)
    Render:DrawText(centered_pos + Vector2(-self.o_size, -self.o_size), text, black, size)
    Render:DrawText(centered_pos + Vector2(self.o_size, -self.o_size), text, black, size)
    Render:DrawText(centered_pos + Vector2(-self.o_size, -self.o_size), text, black, size)
    Render:DrawText(centered_pos + Vector2(self.o_size, self.o_size), text, black, size)

    Render:DrawText(centered_pos, text, color, size)

end

cDamageText = cDamageText()