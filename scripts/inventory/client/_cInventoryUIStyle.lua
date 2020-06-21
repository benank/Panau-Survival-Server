class 'cInventoryUIStyle'

function cInventoryUIStyle:__init()

    self.background_alpha = 200
    self.default_inv_size = 600
    self.colors = 
    {
        default = 
        {
            background = Color(0, 0, 0, self.background_alpha),
            border = Color(255, 0, 0, 0),
            text = Color(220, 220, 220, 255),
            text_hover = Color(255, 255, 255, 255)
        },
        dropping = 
        {
            background = Color(100, 0, 0, self.background_alpha),
            border = Color(255, 0, 0, 255),
            text = Color(220, 0, 0, 255),
            text_hover = Color(255, 0, 0, 255)
        },
        hover = 
        {
            background = Color(255, 255, 255, 40),
            border = Color(255, 255, 255, 200),
            text = Color(220, 220, 220, 255),
            text_hover = Color(255, 255, 255, 255)
        }
    }

    self.equipped_icon = 
    {
        color = Color(255, 255, 255, 255),
        color_under = Color(255, 255, 255, 128),
        position = Vector2(10, 10),
        radius = math.min(6, Render.Size.y / 180)
    }

    self.car_paint_icon = 
    {
        margin = math.min(5, Render.Size.y / 216),
        border_color = Color.White
    }

    self.car_paint_colors = {
        ["Red"] = Color(255,0,0),
        ["Green"] = Color(0,255,0),
        ["Blue"] = Color(0,0,255),
        ["Purple"] = Color(128,0,255),
        ["Pink"] = Color(255,0,255),
        ["Nyan"] = Color(0,191,255),
        ["Lime"] = Color(128,255,0),
        ["Orange"] = Color(255,64,0),
        ["Yellow"] = Color(255,255,0),
        ["White"] = Color(255,255,255),
        ["Black"] = Color(0,0,0),
        ["Brown"] = Color(94,66,27),
        ["DarkGreen"] = Color(38,71,14),
    }

    self.category_title_colors = {Normal = Color.White, Full = Color.Red}
    self.border_size = 2

    self.dura_background_color = Color(255, 255, 255, 50)
    self.tooltip_bg_color = Color(0, 0, 0, 200)

    self.item_colors = 
    {
        brightred = Color(200, 10, 10, self.background_alpha), -- C4 selected
        red = Color(154, 0, 2, self.background_alpha), -- cruise missile, nuke, area bombing
        orange = Color(213, 89, 0, self.background_alpha), -- unused for now
        yellow = Color(223, 153, 0, self.background_alpha), -- landclaim, ping, bping, evac, vehicle repair, backtrak, hacker, woet
        lightgreen = Color(75, 195, 54, self.background_alpha), -- food/drink items
        green = Color(22, 149, 0, self.background_alpha), -- healing items
        lightblue = Color(0, 172, 175, self.background_alpha), -- build items
        blue = Color(0, 99, 166, self.background_alpha), -- armor, grapples, para, grenades, radio
        fuschia = Color(158, 25, 57, self.background_alpha), -- unused for now
        pink = Color(144, 61, 143, self.background_alpha), -- backpacks, scuba gear, explosive detector
        purple = Color(52, 29, 145, self.background_alpha), -- boss drop items
        white = Color(230, 230, 230, self.background_alpha), -- unused for now
        locked = Color(230, 10, 10, self.background_alpha), -- locked
    }

    self.item_color_map = 
    {
        ["Combat Backpack"] = self.item_colors.pink,
        ["Explorer Backpack"] = self.item_colors.pink,
        ["Helmet"] = self.item_colors.blue,
        ["Police Helmet"] = self.item_colors.blue,
        ["Military Helmet"] = self.item_colors.blue,
        ["Military Vest"] = self.item_colors.blue,
        ["Kevlar Vest"] = self.item_colors.blue,
        ["Scuba Gear"] = self.item_colors.yellow,
        ["Area Bombing"] = self.item_colors.red,
        ["BackTrack"] = self.item_colors.yellow,
        ["Bandages"] = self.item_colors.green,
        ["Burst Ping"] = self.item_colors.yellow,
        ["Cruise Missile"] = self.item_colors.red,
        ["EVAC"] = self.item_colors.yellow,
        ["Healthpack"] = self.item_colors.green,
        ["Ping"] = self.item_colors.yellow,
        ["Combat Ping"] = self.item_colors.yellow,
        ["Hacker"] = self.item_colors.yellow,
        ["Barrel Stash"] = self.item_colors.lightblue,
        ["Garbage Stash"] = self.item_colors.lightblue,
        ["Locked Stash"] = self.item_colors.lightblue,
        ["Proximity Alarm"] = self.item_colors.lightblue,
        ["Tactical Nuke"] = self.item_colors.red,
        ["Vehicle Repair"] = self.item_colors.yellow,
        ["Woet"] = self.item_colors.yellow,
        ["HE Grenade"] = self.item_colors.blue,
        ["Laser Grenade"] = self.item_colors.blue,
        ["Molotov"] = self.item_colors.blue,
        ["Smoke Grenade"] = self.item_colors.blue,
        ["Toxic Grenade"] = self.item_colors.blue,
        ["AntiGrav Grenade"] = self.item_colors.blue,
        ["Warp Grenade"] = self.item_colors.blue,
        ["Flashbang"] = self.item_colors.blue,
        ["Apple Juice"] = self.item_colors.lightgreen,
        ["Can of Beans"] = self.item_colors.lightgreen,
        ["Can of Ham"] = self.item_colors.lightgreen,
        ["Can of Peaches"] = self.item_colors.lightgreen,
        ["Chips"] = self.item_colors.lightgreen,
        ["Spicy Chips"] = self.item_colors.lightgreen,
        ["Chocolate"] = self.item_colors.lightgreen,
        ["Coffee"] = self.item_colors.lightgreen,
        ["Cookies"] = self.item_colors.lightgreen,
        ["Energy Drink"] = self.item_colors.lightgreen,
        ["Iced Tea"] = self.item_colors.lightgreen,
        ["Macadamia Nuts"] = self.item_colors.lightgreen,
        ["Peanuts"] = self.item_colors.lightgreen,
        ["Pretzel"] = self.item_colors.lightgreen,
        ["Water"] = self.item_colors.lightgreen,
        ["Grapplehook"] = self.item_colors.blue,
        ["RocketGrapple"] = self.item_colors.blue,
        ["Explosives Detector"] = self.item_colors.yellow,
        ["Parachute"] = self.item_colors.blue,
        ["Radio"] = self.item_colors.blue,
        ["SMRT-GRP"] = self.item_colors.blue,
        ["Wingsuit"] = self.item_colors.blue,
        ["CamelBak"] = self.item_colors.lightgreen,
        ["Cloud Strider Boots"] = self.item_colors.purple,
        ["Second Life"] = self.item_colors.purple,
        ["Master Hacker"] = self.item_colors.purple,
        ["Stick Disguise"] = self.item_colors.purple,
    }


end

function cInventoryUIStyle:RenderItemWindow(itemWindow, stack, parent_window)

    if itemWindow and parent_window:GetVisible() then
        
        local base_pos = parent_window:GetPosition()

        -- Render equipped indicator
        local position = itemWindow:GetPosition() + base_pos + self.equipped_icon.position

        if stack.contents[1].equipped then
            -- Top item in stack is equipped
            Render:FillCircle(position, self.equipped_icon.radius, self.equipped_icon.color)
        elseif stack:GetOneEquipped() then
            -- An item in the stack is equipped
            Render:FillCircle(position, self.equipped_icon.radius, self.equipped_icon.color_under)
        end

        -- Render car paint
        if stack:GetProperty("name") == "Car Paint" then
            local item = stack.contents[1]
            local color_data = self.car_paint_icon
            local size = Vector2(itemWindow:GetHeight() - color_data.margin * 2, itemWindow:GetHeight() - color_data.margin * 2)

            local start_pos = itemWindow:GetPosition() + base_pos + Vector2(itemWindow:GetWidth() - color_data.margin - size.x, color_data.margin)
            
            local color = self.car_paint_colors[item.custom_data.color]

            if not start_pos or not size or not color then return end

            Render:FillArea(start_pos, size, color)
            Render:DrawLine(start_pos, start_pos + Vector2(size.x, 0), color_data.border_color)
            Render:DrawLine(start_pos, start_pos + Vector2(0, size.y), color_data.border_color)
            Render:DrawLine(start_pos + size, start_pos + size - Vector2(size.x, 0), color_data.border_color)
            Render:DrawLine(start_pos + size, start_pos + size - Vector2(0, size.y), color_data.border_color)

        end
    end

end

function cInventoryUIStyle:GetItemColorByName(name, item, locked)

    if locked then
        return self.item_colors.locked
    end

    if name == "C4" and item.custom_data.id then
        return self.item_colors.brightred
    end
    
    if self.item_color_map[name] then
        return self.item_color_map[name]
    else
        return self.colors.default.background
    end
end

-- Updates an item's color based on whether or not is it being dropped or has a specific item color
function cInventoryUIStyle:UpdateItemColor(itemwindow)

    -- Updates the color of an item window based on its color, hovered, and dropping properties
    local button = itemwindow:FindChildByName("button", true)
    local dropping = button:GetDataBool("dropping")
    local cat = button:GetDataString("stack_category")
    local index = button:GetDataNumber("stack_index")

    local stack = nil

    if not itemwindow:GetDataBool("loot") then
        stack = Inventory.contents[cat][index]
    elseif itemwindow:GetDataBool("loot") and LootManager.current_box and LootManager.current_box.contents[index] then
        stack = LootManager.current_box.contents[index]
    end

    local colors = button:GetDataBool("dropping") and self.colors.dropping or InventoryUIStyle.colors.default

    local text = itemwindow:FindChildByName("text", true)

    local stack_name = stack and stack:GetProperty("name") or "empty"

    local locked = itemwindow:GetDataBool("locked")

    text:SetTextColor(colors.text)

    if dropping then
        -- Make item red
        itemwindow:FindChildByName("button_bg", true):SetColor(InventoryUIStyle.colors.dropping.background)
        self:SetBorderColor(itemwindow, self.colors.dropping.border)
    else
        -- Make item normal color
        self:SetBorderColor(itemwindow, self.colors.hover.border)
        itemwindow:FindChildByName("button_bg", true):SetColor(self:GetItemColorByName(stack_name, stack and stack.contents[1] or nil, locked))
    end

    local hovered = button:GetDataBool("hovered")

    if hovered then

        itemwindow:FindChildByName("button_bg_2", true):Show()
        itemwindow:FindChildByName("border_container", true):Show()

    else

        itemwindow:FindChildByName("button_bg_2", true):Hide()

        if not dropping then
            self:SetBorderColor(itemwindow, self.colors.default.border)
            itemwindow:FindChildByName("border_container", true):Hide()
        end

    end
end

function cInventoryUIStyle:SetBorderColor(itemwindow, color)
    itemwindow:FindChildByName("border_top", true):SetColor(color)
    itemwindow:FindChildByName("border_right", true):SetColor(color)
    itemwindow:FindChildByName("border_bottom", true):SetColor(color)
    itemwindow:FindChildByName("border_left", true):SetColor(color)
end

InventoryUIStyle = cInventoryUIStyle()
