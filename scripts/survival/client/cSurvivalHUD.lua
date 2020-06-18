class 'cSurvivalHUD'

function cSurvivalHUD:__init()

    local conversion = Render.Size.y / 1080

    self.small_element_size = conversion * Vector2(140, 12)
    self.large_element_size = conversion * Vector2(300, 18)

    self.start_pos = Vector2(Render.Size.x - 20 * conversion, 60 * conversion)
    self.small_margin = 10
    self.window_color = Color(0, 0, 0, 150)
    self.window_margin = conversion * Vector2(6, 6)
    self.border_size = conversion * Vector2(2,2)
    self.border_color = Color(200, 200, 200)

    self.LevelIndex = 1
    self.HealthIndex = 2
    self.FoodIndex = 3
    self.WaterIndex = 4
    self.SeparatorIndex = 5
    self.HelmetIndex = 6
    self.VestIndex = 7

    self.hud_elements = 
    {
        cSurvivalHUDElement({
            name = "Level",
            percent = 0.5,
            percent2 = 0.5,
            color = Color(255, 26, 0), -- Combat
            color2 = Color(23, 97, 226), -- Exploration
            dual = true,
            level = true,
            small_size = self.small_element_size,
            large_size = self.large_element_size,
            visible = true
        }),
        cSurvivalHUDElement({
            name = "Health",
            percent = 0.75,
            color = Color(223, 153, 0),
            small_size = self.small_element_size,
            large_size = self.large_element_size,
            visible = true
        }),
        cSurvivalHUDElement({
            name = "Food",
            percent = 1.0,
            color = Color(12, 160, 16),
            small_size = self.small_element_size,
            large_size = self.large_element_size,
            visible = true
        }),
        cSurvivalHUDElement({
            name = "Water",
            percent = 0.25,
            color = Color(23, 97, 226),
            small_size = self.small_element_size,
            large_size = self.large_element_size,
            visible = true
        }),
        cSurvivalHUDElement({
            type = "separator",
            color = self.border_color,
            small_size = Vector2(self.small_element_size.x + self.border_size.x, self.border_size.y),
            large_size = Vector2(self.large_element_size.x, self.border_size.y),
            visible = false
        }),
        cSurvivalHUDElement({
            name = "Helmet",
            percent = 0.5,
            color = Color(123, 125, 13),
            small_size = self.small_element_size,
            large_size = self.large_element_size,
            visible = false
        }),
        cSurvivalHUDElement({
            name = "Vest",
            percent = 0.5,
            color = Color(130, 97, 14),
            small_size = self.small_element_size,
            large_size = self.large_element_size,
            visible = false
        }),
    }

    Network:Subscribe("Survival/Update", self, self.Update)
    Events:Subscribe("NetworkObjectValueChange", self, self.NetworkObjectValueChange)

    -- Refresh on reload
    self:NetworkObjectValueChange({
        object = LocalPlayer, 
        value = LocalPlayer:GetValue("EquippedHelmet"),
        key = "EquippedHelmet"
    })

    self:NetworkObjectValueChange({
        object = LocalPlayer, 
        value = LocalPlayer:GetValue("EquippedVest"),
        key = "EquippedVest"
    })
end

function cSurvivalHUD:NetworkObjectValueChange(args)
    if args.object.__type ~= "LocalPlayer" then return end

    local item = args.value

    if args.key == "EquippedHelmet" then
        self.hud_elements[self.HelmetIndex].visible = item ~= nil
        if item then
            self.hud_elements[self.HelmetIndex].percent = item.durability / item.max_durability
        end
    elseif args.key == "EquippedVest" then
        self.hud_elements[self.VestIndex].visible = item ~= nil
        if item then
            self.hud_elements[self.VestIndex].percent = item.durability / item.max_durability
        end
    end

    self.hud_elements[self.SeparatorIndex].visible = self.hud_elements[self.HelmetIndex].visible or self.hud_elements[self.VestIndex].visible

end

function cSurvivalHUD:Update(data)

    self.hud_elements[self.FoodIndex].percent = data.hunger / 100
    self.hud_elements[self.WaterIndex].percent = data.thirst / 100

end

function cSurvivalHUD:GetNumVisibleElements()
    local count = 0
    for _, element in ipairs(self.hud_elements) do
        if element.visible and element.type ~= "separator" then
            count = count + 1
        end
    end
    return count
end

function cSurvivalHUD:Render(args)

    if Game:GetState() ~= GUIState.Game or LocalPlayer:GetValue("MapOpen") then return end

    local inventory_open = LocalPlayer:GetValue("InventoryOpen")

    self.hud_elements[self.HealthIndex].percent = LocalPlayer:GetHealth()

    local t = Transform2():Translate(self.start_pos)

    local translate = inventory_open and Vector2(-self.large_element_size.x, 0) or Vector2(-self.small_element_size.x, 0)
    t = t:Translate(translate)

    Render:SetTransform(t)

    local window_size = inventory_open and
        Vector2(
            self.large_element_size.x + self.window_margin.x + self.border_size.x, 
            self:GetNumVisibleElements() * (self.large_element_size.y + self.small_margin) + (self.hud_elements[self.SeparatorIndex].visible and (self.hud_elements[self.SeparatorIndex].large_size.y + self.small_margin) or 0)) - self.border_size
        or
        Vector2(
            self.small_element_size.x + self.window_margin.x + self.border_size.x, 
            self:GetNumVisibleElements() * (self.small_element_size.y + self.small_margin) + (self.hud_elements[self.SeparatorIndex].visible and (self.hud_elements[self.SeparatorIndex].small_size.y + self.small_margin) or 0)) - self.border_size

    Render:FillArea(-self.window_margin, window_size + self.window_margin, self.window_color)
    self:DrawBorder(-self.window_margin, window_size, self.border_color)

    for index, element in ipairs(self.hud_elements) do

        if element.visible then
            if inventory_open then
                element:RenderLarge(args)
                Render:SetTransform(t:Translate(Vector2(0, element.large_size.y + self.small_margin)))
            else
                element:RenderSmall(args)
                Render:SetTransform(t:Translate(Vector2(0, element.small_size.y + self.small_margin)))
            end
        end
    end

    collectgarbage()

end

function cSurvivalHUD:DrawBorder(pos1, pos2)
    pos1 = pos1 - self.border_size
    --pos2 = pos2 + self.border_size
    local size = pos2 - pos1

    Render:FillArea(pos1, Vector2(size.x, self.border_size.y), self.border_color) -- Top
    Render:FillArea(pos1 + Vector2(0, size.y), Vector2(size.x, self.border_size.y), self.border_color) -- Bottom
    Render:FillArea(pos1, Vector2(self.border_size.x, size.y), self.border_color) -- Left
    Render:FillArea(pos1 + Vector2(size.x, 0), Vector2(self.border_size.x, size.y + self.border_size.y), self.border_color) -- Right
end