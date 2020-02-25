class 'cLoader'

function cLoader:__init()

    self.resources_needed = 0
    self.resources_loaded = 0

    self.first_load = true
    self.can_add_resources = true

    self.bg_image_grayscale = Image.Create(AssetLocation.Resource, "bg_image_grayscale")
    self.bg_image_color = Image.Create(AssetLocation.Resource, "bg_image_color")

    self.window = BaseWindow.Create()
    self.window:SetSize(Render.Size)

    self.rectangle = Rectangle.Create(self.window)
    self.rectangle:SetColor(Color.Black)
    self.rectangle:SetSize(Render.Size)

    self.load_text = Label.Create(self.rectangle)
    self.load_text:SetAlignment(GwenPosition.Center)
    self.load_text:SetText("Loading")
    self.load_text:SetTextColor(Color.White)
    self.load_text:SetTextSize(Render.Size.x * 0.05)
    self.load_text:SetSizeRel(Vector2(1,1))
    self.load_text_dots = 0;
    self.max_load_text_dots = 3

    self.bg_grayscale = ImagePanel.Create(self.window)
    self.bg_grayscale:SetImage(self.bg_image_grayscale)
    self.bg_grayscale:SetSizeAutoRel(Vector2(1,1))
    
    self.bg_color = ImagePanel.Create(self.window)
    self.bg_image_color:SetAlpha(0)
    self.bg_color:SetImage(self.bg_image_color)
    self.bg_color:SetSizeAutoRel(Vector2(1,1))

    self.progressBar = ProgressBar.Create(self.window)
    self.progressBar:SetSize(Vector2(Render.Size.x * 0.925, Render.Size.y * 0.015))
    self.progressBar:SetPosition(Vector2(Render.Size.x / 2, Render.Size.y * 0.95) - self.progressBar:GetSize() / 2)
    self.progressBar:SetAutoLabel(false)
    self.progressBar:SetValue(0)
    self.target_value = 0

    self.window:Hide()

    self.resources_for_gameload = 7

    self.delta = 0

    Events:Subscribe("loader/RegisterResource", self, self.RegisterResource)
    Events:Subscribe("loader/CompleteResource", self, self.CompleteResource)
    Events:Subscribe("loader/StartLoad", self, self.StartLoad) -- Call this to restart load, aka changing dimensions

    Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
    Events:Subscribe("GameLoad", self, self.GameLoad)
    Events:Subscribe("LocalPlayerDeath", self, self.LocalPlayerDeath)
    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)

    -- Fire event for when modules reload
    Timer.SetTimeout(1000, function()
        Events:Fire("LoaderReady")
    end)

end

-- Call this event to allow RegisterResource so you can have a load screen for different dimensions
function cLoader:StartLoad()

    self.can_add_resources = true

end

function cLoader:ModulesLoad()

    Events:Fire("LoaderReady")

end

function cLoader:ModuleLoad()

    self.resources_needed = 
        Game:GetState() == GUIState.Loading and self.resources_needed + self.resources_for_gameload 
        or self.resources_needed

    self.can_add_resources = Game:GetState() == GUIState.Loading

    self:UpdateResourceCount()
    self:Start()

end

function cLoader:GameLoad()

    Timer.SetTimeout(3000, function()
        self.resources_loaded = self.resources_loaded + self.resources_for_gameload
        self:UpdateResourceCount()
        self:Stop()
    end)

end

function cLoader:LocalPlayerDeath()

    self.resources_needed = 0
    self.resources_loaded = 0

    Timer.SetTimeout(5000, function()
        self.resources_needed = self.resources_needed + self.resources_for_gameload
        self:UpdateResourceCount()
        self:Start()
    end)

end

function cLoader:UpdateResourceCount()

    self.target_value = self.resources_loaded / self.resources_needed
    self.window:BringToFront()

    if not self.lerp_render then
        self.lerp_render = Events:Subscribe("Render", self, self.Render)
    end

end

function cLoader:Render(args)

    local val = self.progressBar:GetValue()
    if val ~= self.target_value then
        local add = math.ceil(((self.target_value - val) * args.delta * 1.75) * 1000) / 1000
        self.progressBar:SetValue(val + add)

        self.bg_image_color:SetAlpha(self.progressBar:GetValue())
        self.bg_color:SetImage(self.bg_image_color)
    elseif math.ceil(val * 100) == 100 then
        self:Stop()
    end

    self.delta = self.delta + args.delta * 0.2

    --[[local mod = 0.05
    local size_rel = math.sin(self.delta * math.pi * 2) * mod + 1 + mod
    local vec_rel = Vector2(size_rel, size_rel)

    self.bg_color:SetSizeAutoRel(vec_rel)
    self.bg_color:SetPosition(Render.Size / 2 - self.bg_color:GetSize() / 2)

    self.bg_grayscale:SetSizeAutoRel(vec_rel)
    self.bg_grayscale:SetPosition(Render.Size / 2 - self.bg_grayscale:GetSize() / 2)]]

end

--[[
Register some resources to load.

Args:

count: how many resources we are waiting for (no need to specify for images)

]]--

function cLoader:Start()

    if self.resources_needed == self.resources_loaded or self.resources_needed == 0 then return end

    if not self.window:GetVisible() then
        self.window:Show()
    end

    Game:FireEvent("ply.pause")
    Game:FireEvent("ply.invulnerable")

    if not self.active then
        Network:Send("LoadStatus")
    end

    self.active = true

    if not self.subs then
        self.subs = 
        {
            Events:Subscribe("CalcView", self, self.CalcView),
            Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput),
            Events:Subscribe("Render", self, self.Render2),
        }
    end

    if not self.dot_interval then
        self.dot_interval = Timer.SetInterval(500, function()
            self.load_text:SetText(self:GetLoadText())  
        end)
    end
    
    LocalPlayer:SetValue("Loading", true)
    Events:Fire("LoadingStarted")

end

function cLoader:Render2(args)

    Render:FillArea(Vector2(0,0), Render.Size, Color.Black)

    if Game:GetState() == GUIState.Menu then
        self.window:Hide()
    else
        self.window:Show()
    end

end

function cLoader:GetLoadText()

    local text = "Loading"

    for i = 1, self.load_text_dots do text = text .. "." end

    self.load_text_dots = self.load_text_dots >= self.max_load_text_dots and 0 or self.load_text_dots + 1

    return text

end

function cLoader:CalcView()
    self.window:BringToFront()
    return false
end

function cLoader:LocalPlayerInput()
    return false
end

function cLoader:Stop()

    if self.resources_needed ~= self.resources_loaded then return end
    if self.target_value - self.progressBar:GetValue() > 0.1 then return end

    Timer.SetTimeout(750, function()
        
        if self.resources_needed ~= self.resources_loaded then return end
        if self.target_value - self.progressBar:GetValue() > 0.1 then return end

        self.window:Hide()

        if self.active then
            Network:Send("LoadStatus", {status = "done"})
        end
    
        self.active = false

        self.resources_needed = 0
        self.resources_loaded = 0

        if self.image_interval then
            Timer.Clear(self.image_interval)
            self.image_interval = nil
        end

        if self.dot_interval then
            Timer.Clear(self.dot_interval)
            self.dot_interval = nil
        end

        if self.lerp_render then
            Events:Unsubscribe(self.lerp_render)
            self.lerp_render = nil
        end

        self.window:Hide()
        Game:FireEvent("ply.unpause")
        Game:FireEvent("ply.vulnerable")

        for k,v in pairs(self.subs) do
            Events:Unsubscribe(v)
        end

        self.can_add_resources = false
        self.first_load = false

        self.window:Hide()
        self.subs = {}

        
        LocalPlayer:SetValue("Loading", false)
        Events:Fire("LoadingStarted")

    end)

end

function cLoader:RegisterResource(args)

    if not self.can_add_resources then return end

    self.resources_needed = self.resources_needed + args.count
    self:UpdateResourceCount()
    self:Start()

end

-- Only argument here is count
function cLoader:CompleteResource(args)

    if not self.can_add_resources then return end
    
    self.resources_loaded = self.resources_loaded + args.count
    self:UpdateResourceCount()
    self:Stop()

end

cLoader = cLoader()
