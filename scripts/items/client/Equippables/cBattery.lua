class 'cBattery'

function cBattery:__init()

    -- Display for batteries when they are being used
    self.active = 0

    self.num_batteries = var(0)
    self.battery_dura = 0

    self.size = Vector2(160, 40)
    self.pos = Vector2(0, Render.Size.y) - Vector2(0, self.size.y) - Vector2(-20, 20)
    self.inner_color = Color(230, 230, 230, 100)
    self.bg_color = Color(0, 0, 0, 100)
    self.no_batteries_color = Color(200, 0, 0, 100)
    self.font_size = 24

    self.border_size = Vector2(2,2)
    self.border_color = Color(255, 255, 255, 200)

    Events:Subscribe("SecondTick", self, self.SecondTick)

end

function cBattery:GetNumBatteries()
    return tonumber(self.num_batteries:get())
end

function cBattery:SecondTick()

    self.num_batteries = var(Inventory.GetNumOfItem({item_name = "Battery"}))
    self.battery_dura = 0
    
    local inv = Inventory.contents
    if not inv then return end

    local item = Items_indexed["Battery"]
    if not item then
        print("Failed to cBattery:SecondTick because item was invalid")
        return
    end

    if not item.category or not inv[item.category] then return end

    for index, stack in pairs(inv[item.category]) do
        if stack:GetProperty("name") == item.name then
            self.battery_dura = math.min(1, stack.contents[1].durability / stack.contents[1].max_durability)
            break
        end
    end

end

function cBattery:ToggleEnabled(enabled)

    self.active = enabled and self.active + 1 or self.active - 1

    if self.active > 0 and not self.render then
        self.render = Events:Subscribe("Render", self, self.Render)
    elseif self.active == 0 and self.render then
        Events:Unsubscribe(self.render)
        self.render = nil
    end

end

function cBattery:Render(args)

    if LocalPlayer:GetValue("InventoryOpen") and Render.Size.x < 1300 then return end

    local num_batteries = self:GetNumBatteries()
    local battery_text = string.format("Battery (%d)", num_batteries)
    local text_size = Render:GetTextSize(battery_text, self.font_size)

    self:DrawShadowedText(
        self.pos + Vector2(self.size.x / 2 - text_size.x / 2, -text_size.y - 8), battery_text, Color.White, self.font_size)

    local bg_color = num_batteries > 0 and self.bg_color or self.no_batteries_color

    Render:FillArea(self.pos, self.size, bg_color)
    Render:FillArea(self.pos, Vector2(self.size.x * self.battery_dura, self.size.y), self.inner_color)
    self:DrawBorder(self.pos, self.pos + self.size)

end

function cBattery:DrawShadowedText(pos, text, color, number)
    Render:DrawText(pos + Vector2(2,2), text, Color.Black, number)
    Render:DrawText(pos, text, color, number)
end

function cBattery:DrawBorder(pos1, pos2)
    pos1 = pos1 - self.border_size
    --pos2 = pos2 + self.border_size
    local size = pos2 - pos1

    Render:FillArea(pos1, Vector2(size.x, self.border_size.y), self.border_color) -- Top
    Render:FillArea(pos1 + Vector2(0, size.y), Vector2(size.x, self.border_size.y), self.border_color) -- Bottom
    Render:FillArea(pos1, Vector2(self.border_size.x, size.y), self.border_color) -- Left
    Render:FillArea(pos1 + Vector2(size.x, 0), Vector2(self.border_size.x, size.y + self.border_size.y), self.border_color) -- Right
end

cBattery = cBattery()