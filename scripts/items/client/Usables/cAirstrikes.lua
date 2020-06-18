class 'cAirstrikes'

function cAirstrikes:__init()

    self.airstrike_types = 
    {
        ["Cruise Missile"] = cCruiseMissile,
        ["Area Bombing"] = cAreaBombing,
        ["Tactical Nuke"] = cTacticalNuke
    }

    Network:Subscribe("items/StartAirstrikePlacement", self, self.StartAirstrikePlacement)
    Network:Subscribe("items/CreateAirstrike", self, self.CreateAirstrike)

end

function cAirstrikes:RenderCountdown(position, time_left)

    if time_left == 0 then return end

    local pos, on_screen = Render:WorldToScreen(position)

    if not on_screen then return end

    local text = string.format("%.0f sec", time_left + 1)
    local text_offset = Vector2(30, 0)
    local textsize = 24
    local text_size = Render:GetTextSize(text, textsize)
    local height = Vector2(0, text_size.y)

    Render:DrawText(pos + text_offset - height / 2 + Vector2(2,2), text, Color.Black, 24)
    Render:DrawText(pos + text_offset - height / 2, text, Color.Red, 24)

    local triangle_size = 16
    local margin = 10

    -- Top left
    Render:FillTriangle(
        pos + Vector2(-margin, -margin),
        pos + Vector2(-margin - triangle_size, -margin),
        pos + Vector2(-margin, -margin - triangle_size),
        Color.Red
    )

    -- Top Right
    Render:FillTriangle(
        pos + Vector2(margin, -margin),
        pos + Vector2(margin + triangle_size, -margin),
        pos + Vector2(margin, -margin - triangle_size),
        Color.Red
    )

    -- Bottom Right
    Render:FillTriangle(
        pos + Vector2(margin, margin),
        pos + Vector2(margin + triangle_size, margin),
        pos + Vector2(margin, margin + triangle_size),
        Color.Red
    )

    -- Bottom Left
    Render:FillTriangle(
        pos + Vector2(-margin, margin),
        pos + Vector2(-margin - triangle_size, margin),
        pos + Vector2(-margin, margin + triangle_size),
        Color.Red
    )

end

function cAirstrikes:CreateAirstrike(args)

    if args.position:Distance(Camera:GetPosition()) > 5000 then return end

    if not self.airstrike_types[args.name] then return end

    -- Create airstrike
    self.airstrike_types[args.name](args)

end

function cAirstrikes:StartAirstrikePlacement(args)

    local perks = LocalPlayer:GetValue("Perks")
    local radius_modifier = 1
    local possible_perks = AirstrikePerks[args.name]

    if args.name ~= "Area Bombing" then
        for perk_id, perk_mod_data in pairs(possible_perks) do
            local choice = perks.unlocked_perks[perk_id]
            if perk_mod_data[choice] then
                radius_modifier = math.max(radius_modifier, perk_mod_data[choice])
            end
        end
    end

    local radius = ItemsConfig.airstrikes[args.name].radius * radius_modifier

    Events:Fire(var("build/StartAirstrikePlacement"):get(), {
        radius = radius
    })

    self.place_subs = 
    {
        Events:Subscribe("build/PlaceAirstrike", self, self.PlaceAirstrike),
        Events:Subscribe("build/CancelAirstrikePlacement", self, self.CancelAirstrikePlacement)
    }
    
    self.placing = true
end

function cAirstrikes:PlaceAirstrike(args)

    if not self.placing then return end

    Network:Send(var("items/PlaceAirstrike"):get(), {
        position = args.position
    })

    self:StopPlacement()
end

function cAirstrikes:CancelAirstrikePlacement()
    Network:Send(var("items/CancelAirstrikePlacement"):get())
    self:StopPlacement()
end

function cAirstrikes:StopPlacement()
    for k, v in pairs(self.place_subs) do
        Events:Unsubscribe(v)
    end

    self.place_subs = {}
    self.placing = false
end

cAirstrikes = cAirstrikes()