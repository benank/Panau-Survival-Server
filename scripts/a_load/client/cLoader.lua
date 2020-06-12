class 'cLoader'

function cLoader:__init()

    self.load_time = Client:GetElapsedSeconds()

    self.resources_needed = 0
    self.resources_loaded = 0

    self.first_load = true
    self.can_add_resources = true

    --self.bg_image_grayscale = Image.Create(AssetLocation.Resource, "bg_image_grayscale")
    --self.bg_image_color = Image.Create(AssetLocation.Resource, "bg_image_color")

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

    --self.bg_grayscale = ImagePanel.Create(self.window)
    --self.bg_grayscale:SetImage(self.bg_image_grayscale)
    --self.bg_grayscale:SetSizeAutoRel(Vector2(1,1))
    
    --self.bg_color = ImagePanel.Create(self.window)
    --self.bg_image_color:SetAlpha(0)
    --self.bg_color:SetImage(self.bg_image_color)
    --self.bg_color:SetSizeAutoRel(Vector2(1,1))

    self.progressBar = ProgressBar.Create(self.window)
    self.progressBar:SetSize(Vector2(Render.Size.x * 0.925, Render.Size.y * 0.015))
    self.progressBar:SetPosition(Vector2(Render.Size.x / 2, Render.Size.y * 0.95) - self.progressBar:GetSize() / 2)
    self.progressBar:SetAutoLabel(false)
    self.progressBar:SetValue(0)
    self.target_value = 0

    self.window:Hide()

    self.resources_for_gameload = 7
    self.resources_for_loadscreen = 3

    self.delta = 0

    self:InitialLoad()

    Events:Subscribe(var("loader/RegisterResource"):get(), self, self.RegisterResource)
    Events:Subscribe(var("loader/CompleteResource"):get(), self, self.CompleteResource)
    Events:Subscribe(var("loader/StartLoad"):get(), self, self.StartLoad) -- Call this to restart load, aka changing dimensions

    Events:Subscribe(var("ModulesLoad"):get(), self, self.ModulesLoad)
    Events:Subscribe(var("GameLoad"):get(), self, self.GameLoad)
    Events:Subscribe(var("LocalPlayerDeath"):get(), self, self.LocalPlayerDeath)

    Events:Subscribe("SecondTick", self, self.SecondTick)

    -- Fire event for when modules reload
    Events:Fire(var("LoaderReady"):get())

end

function cLoader:ModulesLoad()
    Events:Fire(var("LoaderReady"):get())
end

-- Call this event to allow RegisterResource so you can have a load screen for different dimensions
function cLoader:StartLoad()

    self.can_add_resources = true

end

function cLoader:SecondTick()

    if self.active then

        if Game:GetState() == GUIState.Game and not self.loadscreen_complete then
            self.loadscreen_complete = true

            Timer.SetTimeout(1000, function()
                self.resources_loaded = self.resources_loaded + self.resources_for_loadscreen
                self:UpdateResourceCount()
                self:Stop()
            end)
        end

    end

end

function cLoader:InitialLoad()

    self.can_add_resources = true
    self.resources_needed = self.resources_needed + self.resources_for_loadscreen
    
    self:UpdateResourceCount()
    self:Start()

end

function cLoader:GameLoad()

    self.game_loaded = true
    self.resources_needed = self.resources_needed + self.resources_for_gameload
    self:UpdateResourceCount()
    Thread(function()
        local load_time_max = (Client:GetElapsedSeconds() - self.load_time) * 1500 + 1000
        local load_time = 0
        local interval = 100
        local percent = interval / load_time_max

        while load_time < load_time_max do
            load_time = load_time + interval
            self.resources_loaded = self.resources_loaded + self.resources_for_gameload * percent
            self:UpdateResourceCount()
            Timer.Sleep(interval)
        end

        if self.resources_loaded > self.resources_needed then
            self.resources_loaded = self.resources_needed
        end

        self:UpdateResourceCount()
        self:Stop()
    end)

end

function cLoader:LocalPlayerDeath()

    self.resources_needed = 0
    self.resources_loaded = 0
    self.game_loaded = false
    self.loadscreen_complete = false

    Thread(function()
        Timer.Sleep(5000)
        self.load_time = Client:GetElapsedSeconds() - 4
        self.resources_needed = self.resources_needed + self.resources_for_loadscreen
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

        --self.bg_image_color:SetAlpha(self.progressBar:GetValue())
        --self.bg_color:SetImage(self.bg_image_color)
    elseif math.ceil(val * 100) == 100 then
        self:Stop()
    end

    self.delta = self.delta + args.delta * 0.2

    if not IsValid(self.sound) then
        self:PlayMusic()
    else
        self.sound:SetPosition(Camera:GetPosition())
    end

end

--[[
Register some resources to load.

Args:

count: how many resources we are waiting for (no need to specify for images)

]]--

function cLoader:PlayMusic()
    if not IsValid(self.sound) then
        self.sound = ClientSound.Create(AssetLocation.Game, {
            bank_id = 25,
            sound_id = 43,
            position = Camera:GetPosition(),
            angle = Angle()
        })
    end
end

function cLoader:Start()

    if self.resources_needed == self.resources_loaded or self.resources_needed == 0 then return end

    if not self.window:GetVisible() then
        self.window:Show()
    end

    Game:FireEvent("ply.pause")
    Game:FireEvent("ply.invulnerable")

    if not IsValid(self.sound) then
        self:PlayMusic()
    else
        self.sound:SetPosition(Camera:GetPosition())
    end

    if not self.active then
        Network:Send(var("LoadStatus"):get())
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
    Events:Fire(var("LoadingStarted"):get())

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

        if IsValid(self.sound) then
            self.sound:Remove()
            self.sound = nil
        end

        if self.active then
            Network:Send(var("LoadStatus"):get(), {status = var("done"):get()})
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

        if self.subs then
            for k,v in pairs(self.subs) do
                Events:Unsubscribe(v)
            end
        end

        self.can_add_resources = false
        self.first_load = false

        self.window:Hide()
        self.subs = {}

        
        LocalPlayer:SetValue("Loading", false)
        Events:Fire(var("LoadingFinished"):get())

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
