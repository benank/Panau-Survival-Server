class 'cSurvivalHUD'

function cSurvivalHUD:__init()

    self.small_element_size = Vector2(140, 12)
    self.large_element_size = Vector2(300, 18)

    self.start_pos = Vector2(Render.Size.x - 14, 50)
    self.small_margin = 10
    self.window_color = Color(0, 0, 0, 150)
    self.window_margin = Vector2(6, 6)
    self.border_size = Vector2(2,2)
    self.border_color = Color(200, 200, 200)

    self.hud_elements = 
    {
        cSurvivalHUDElement({
            name = "Health",
            percent = 0.75,
            color = Color(155, 157, 11),
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
            color = Color(46, 13, 161),
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
        self.hud_elements[5].visible = item ~= nil
        if item then
            self.hud_elements[5].percent = item.durability / item.max_durability
        end
    elseif args.key == "EquippedVest" then
        self.hud_elements[6].visible = item ~= nil
        if item then
            self.hud_elements[6].percent = item.durability / item.max_durability
        end
    end

    self.hud_elements[4].visible = self.hud_elements[5].visible or self.hud_elements[6].visible

end

function cSurvivalHUD:Update(data)

    self.hud_elements[2].percent = data.hunger / 100
    self.hud_elements[3].percent = data.thirst / 100

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

    if Game:GetState() ~= GUIState.Game then return end

    local inventory_open = LocalPlayer:GetValue("InventoryOpen")

    self.hud_elements[1].percent = LocalPlayer:GetHealth()

    local t = Transform2():Translate(self.start_pos)

    local translate = inventory_open and Vector2(-self.large_element_size.x, 0) or Vector2(-self.small_element_size.x, 0)
    t = t:Translate(translate)

    Render:SetTransform(t)

    local window_size = inventory_open and
        Vector2(
            self.large_element_size.x + self.window_margin.x + self.border_size.x, 
            self:GetNumVisibleElements() * (self.large_element_size.y + self.small_margin) + (self.hud_elements[4].visible and (self.hud_elements[4].large_size.y + self.small_margin) or 0)) - self.border_size
        or
        Vector2(
            self.small_element_size.x + self.window_margin.x + self.border_size.x, 
            self:GetNumVisibleElements() * (self.small_element_size.y + self.small_margin) + (self.hud_elements[4].visible and (self.hud_elements[4].small_size.y + self.small_margin) or 0)) - self.border_size

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