class 'cLandclaimObjectHealthDisplay'

-- Class for managing and displaying object health on landclaims
function cLandclaimObjectHealthDisplay:__init()
    
    self.range = 8 -- Range at which the health appears
    self.display_time = 5 -- Object health displays for 5 seconds after damaging it

    Events:Subscribe("Render", self, self.Render)
end

function cLandclaimObjectHealthDisplay:Render(args)

    -- Object was recently damaged so show the health
    if self.timer and self.timer:GetSeconds() < self.display_time and self.landclaim_object then
        self:RenderDisplay(self.landclaim_object)
        return
    end

    if LocalPlayer:GetValue("Loading") then return end
    if cObjectPlacer.placing then return end
    if LocalPlayer:GetValue("InventoryOpen") then return end
    if LocalPlayer:InVehicle() then return end

    -- Get current object that we are looking at
    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, self.range)
    local landclaim_object = self:GetLandclaimObjectFromRaycastEntity(ray.entity)
    if not landclaim_object then return end

    -- Now that we have a valid object, check its owner
    if landclaim_object.landclaim.owner_id ~= tostring(LocalPlayer:GetSteamId()) then return end
    if not landclaim_object.landclaim.visible then return end

    self:RenderDisplay(landclaim_object)

end

function cLandclaimObjectHealthDisplay:RenderDisplay(landclaim_object)

    local health = landclaim_object.health
    local max_health = landclaim_object.max_health
    local num_bars = math.ceil(health / C4Damage)
    local remainder = health % C4Damage

    local size = Vector2(Render.Size.x * 0.15, 40)
    local margin = Render.Size.x * 0.0025
    local position = Vector2(Render.Size.x / 2, Render.Size.y / 2) - Vector2(0, 200) - size / 2

    local bar_spacing = Render.Size.x * 0.0025
    local bar_size = Vector2(
        ((size.x - margin * 2 - bar_spacing * (num_bars - 1)) / num_bars),
        size.y - margin * 2)
    local bar_size_x = Vector2(bar_size.x, 0)

    Render:FillArea(position, size, Color(0, 0, 0, 120))

    for i = 1, num_bars do

        -- All bars
        local width_percent = (i == num_bars and remainder > 0) and remainder / C4Damage or 1
        local bar_size_calc = Vector2(bar_size.x * width_percent, bar_size.y)

        Render:FillArea(position + (i - 1) * (bar_size_x + Vector2(bar_spacing, 0)) + Vector2(margin, margin), bar_size, Color(255, 255, 255, 100))
        Render:FillArea(position + (i - 1) * (bar_size_x + Vector2(bar_spacing, 0)) + Vector2(margin, margin), bar_size_calc, Color(255, 255, 255, 200))

    end

end

function cLandclaimObjectHealthDisplay:GetLandclaimObjectFromRaycastEntity(entity)
    if not IsValid(entity) then return end
    if entity.__type ~= "ClientStaticObject" then return end

    return entity:GetValue("LandclaimObject")
end

function cLandclaimObjectHealthDisplay:Display(object)
    self.landclaim_object = object
    self.display_timer = Timer()
end

cLandclaimObjectHealthDisplay = cLandclaimObjectHealthDisplay()