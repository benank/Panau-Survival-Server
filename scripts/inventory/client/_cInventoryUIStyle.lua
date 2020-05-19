class 'cInventoryUIStyle'

function cInventoryUIStyle:__init()

    self.background_alpha = 160
    self.default_inv_size = 1000 -- 800 px wide for the entire inventory
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
        color = Color(110, 124, 164, 255),
        color_under = Color(110, 124, 164, 120),
        position = Vector2(10, 10),
        radius = 6
    }

    self.category_title_colors = {Normal = Color.White, Full = Color.Red}
    self.border_size = 2

    self.item_colors = 
    {
        blue = Color(17, 84, 135, self.background_alpha), -- armor, grapples, para, grenades, radio
        red = Color(120, 10, 10, self.background_alpha), -- cruise missile, nuke, area bombing
        brightred = Color(200, 10, 10, self.background_alpha), -- C4 selected
        pink = Color(140, 63, 140, self.background_alpha), -- backpacks, scuba gear, explosive detector
        yellow = Color(155, 145, 29, self.background_alpha), -- landclaim, ping, bping, evac, vehicle repair, backtrak, stashhacker, woet
        darkgreen = Color(24, 99, 24, self.background_alpha), -- food/drink items
        green = Color(20, 155, 22, self.background_alpha), -- healing items
        lightblue = Color(11, 118, 137, self.background_alpha), -- build items
        purple = Color(84, 55, 229, self.background_alpha), -- boss drop items
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
        ["Stash Hacker"] = self.item_colors.yellow,
        ["Barrel Stash"] = self.item_colors.lightblue,
        ["Garbage Stash"] = self.item_colors.lightblue,
        ["Locked Stash"] = self.item_colors.lightblue,
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
        ["Apple Juice"] = self.item_colors.darkgreen,
        ["Can of Beans"] = self.item_colors.darkgreen,
        ["Can of Ham"] = self.item_colors.darkgreen,
        ["Can of Peaches"] = self.item_colors.darkgreen,
        ["Chips"] = self.item_colors.darkgreen,
        ["Spicy Chips"] = self.item_colors.darkgreen,
        ["Chocolate"] = self.item_colors.darkgreen,
        ["Coffee"] = self.item_colors.darkgreen,
        ["Cookies"] = self.item_colors.darkgreen,
        ["Energy Drink"] = self.item_colors.darkgreen,
        ["Iced Tea"] = self.item_colors.darkgreen,
        ["Macadamia Nuts"] = self.item_colors.darkgreen,
        ["Peanuts"] = self.item_colors.darkgreen,
        ["Pretzel"] = self.item_colors.darkgreen,
        ["Water"] = self.item_colors.darkgreen,
        ["Grapplehook"] = self.item_colors.blue,
        ["RocketGrapple"] = self.item_colors.blue,
        ["Explosives Detector"] = self.item_colors.yellow,
        ["Parachute"] = self.item_colors.blue,
        ["Radio"] = self.item_colors.blue,
        ["SMRT-GRP"] = self.item_colors.blue,
        ["Wingsuit"] = self.item_colors.blue,
        ["CamelBak"] = self.item_colors.darkgreen,
        ["Cloud Strider Boots"] = self.item_colors.purple,
        ["Second Life"] = self.item_colors.purple,
    }


end

function cInventoryUIStyle:GetItemColorByName(name, item)

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

    text:SetTextColor(colors.text)

    if dropping then
        -- Make item red
        itemwindow:FindChildByName("button_bg", true):SetColor(InventoryUIStyle.colors.dropping.background)
        self:SetBorderColor(itemwindow, self.colors.dropping.border)
    else
        -- Make item normal color
        self:SetBorderColor(itemwindow, self.colors.hover.border)
        itemwindow:FindChildByName("button_bg", true):SetColor(self:GetItemColorByName(stack_name, stack and stack.contents[1] or nil))
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