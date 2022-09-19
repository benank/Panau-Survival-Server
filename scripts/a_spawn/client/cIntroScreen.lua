class 'cIntroScreen'

function cIntroScreen:__init()
    self.move_timer = Timer()
    self.subs = {}
    self.delta = 0
    self.start_pos = Vector3(-12416, 918, -1987)
    self.end_pos = Vector3(10167, 1200, -8134)
    self.angle = Angle(-1.260971, -0.260157, 0)
    self.move_time = 60 * 60
    self.finished_loading = false
    self.players_online = self:GetPlayerCount()
    self:RegisterEvents()
    Chat:SetEnabled(false)
    
    if LocalPlayer:GetValue("InIntroScreen") then
        Mouse:SetVisible(true)
    end
    
    self:CreateUI()
end

function cIntroScreen:GetPlayerCount()
    local count = 1
    for p in Client:GetPlayers() do
        count = count + 1 
    end
    return count
end
function cIntroScreen:CalcView()
    Camera:SetAngle(self.angle)
    Camera:SetPosition(math.lerp(self.start_pos, self.end_pos, self.move_timer:GetSeconds() / self.move_time))
    return false
end

function cIntroScreen:Render(args)
    Render:SetFont(AssetLocation.Disk, "Archivo.ttf")
    
    if self.finished_loading then
        Game:FireEvent("gui.hud.hide")
    end
    
    self.delta = self.delta + args.delta
end

function cIntroScreen:LoadingFinished()
    Mouse:SetVisible(true)
    Mouse:SetPosition(Render.Size / 2)
    self.finished_loading = true
    self.players_online = self:GetPlayerCount()
    self.players_text:SetText(string.format("Players Online: %s", tostring(self.players_online)))
end

function cIntroScreen:RegisterEvents()
    self.subs = {
        Events:Subscribe("CalcView", self, self.CalcView),
        Events:Subscribe("Render", self, self.Render),
        Events:Subscribe("LoadingFinished", self, self.LoadingFinished)
    }
end

function cIntroScreen:UnregisterEvents()
    for _, event in pairs(self.subs) do
        Events:Unsubscribe(event) 
    end
    
    self.subs = {}
end

function cIntroScreen:ButtonClicked(name)
    
    if name == "Play" then
        Network:Send("intro/Play")
    elseif name == "Tutorial" then
        Network:Send("intro/Tutorial")
    end
    
    Events:Fire("loader/StartLoad")
    
    local sub
    sub = Events:Subscribe("build/AreAnyLandclaimsLoading", function(args)
        if not args.loading then
            print("Finish landclaims")
            Events:Fire("loader/CompleteResource", {
                count = 1,
                name = "Landclaims"
            })
            sub = Events:Unsubscribe(sub)
        end
    end)
    
    Thread(function()
        while sub do
            Timer.Sleep(2000)
            print("are any loading")
            Events:Fire("build/AreAnyLandclaimsLoadingQuery")
        end
    end)
    
    Events:Fire("loader/RegisterResource", {
        count = 1,
        name = "Landclaims"
    })
    
    self:UnregisterEvents()
    self.top_rectangle:Remove()
    self.bottom_rectangle:Remove()
    Mouse:SetVisible(false)
    Chat:SetEnabled(true)
    Game:FireEvent("gui.hud.show")
    
end

function cIntroScreen:CreateUI()
    
    local render_size = Render.Size
    local bar_size = 0.1
    
    self.top_rectangle = Rectangle.Create()
    self.top_rectangle:SetColor(Color.Black)
    self.top_rectangle:SetSize(Vector2(render_size.x, render_size.y * bar_size))

    self.bottom_rectangle = Rectangle.Create()
    self.bottom_rectangle:SetPosition(Vector2(0, render_size.y * (1 - bar_size)))
    self.bottom_rectangle:SetColor(Color.Black)
    self.bottom_rectangle:SetSize(Vector2(render_size.x, render_size.y * bar_size))
    
    self.title_text = Label.Create(self.top_rectangle)
    self.title_text:SetAlignment(GwenPosition.CenterV)
    self.title_text:SetPosition(Vector2(25, 0))
    self.title_text:SetText("Welcome to Panau Survival!")
    self.title_text:SetTextColor(Color.White)
    self.title_text:SetTextSize(Render.Size.x * 0.025)
    self.title_text:SetSizeRel(Vector2(1,1))
    self.title_text:SetFont(AssetLocation.Disk, "Archivo.ttf")
    
    self.players_text = Label.Create(self.top_rectangle)
    self.players_text:SetAlignment(GwenPosition.CenterV)
    self.players_text:SetPositionRel(Vector2(0.75, 0))
    self.players_text:SetText(string.format("Players Online: %s", tostring(self.players_online)))
    self.players_text:SetTextColor(Color.Gray)
    self.players_text:SetTextSize(Render.Size.x * 0.015)
    self.players_text:SetSizeRel(Vector2(1,1))
    self.players_text:SetFont(AssetLocation.Disk, "Archivo.ttf")
    
    self:CreateButton("Play", Vector2(0.25, 0.5), "Play")
    self:CreateButton("Tutorial", Vector2(0.75, 0.5), "Tutorial")
    
end

function cIntroScreen:CreateButton(text_content, position_rel, name)
    
    local size_rel = Vector2(0.15, 0.65)
    local window = BaseWindow.Create(self.bottom_rectangle)
    window:SetSizeRel(size_rel)
    window:SetPositionRel(position_rel - size_rel / 2)
    window:SetDataString("name", name)
    
    local button = Button.Create(window)
    button:SetSizeRel(Vector2(1, 1))
    button:SetBackgroundVisible(false)
   
    local text_color = Color(255, 255, 255, 220)
    local text = Label.Create(window, "text")
    text:SetSizeAutoRel(Vector2(1, 1))
    text:SetText(text_content) 
    text:SetTextSize(Render.Size.x * 0.025)
    text:SetTextColor(text_color)
    text:SetAlignment(GwenPosition.Center)
    text:SetFont(AssetLocation.Disk, "Archivo.ttf") 
    
    local border_size = 2
    local border_container = Rectangle.Create(window, "border_container")
    border_container:SetSizeAutoRel(Vector2(1, 1))
    border_container:SetColor(Color(255, 255, 255, 25))
    -- border_container:Hide()

    local border_color = Color(255, 255, 255, 150)
    local border_top = Rectangle.Create(border_container, "border_top")
    border_top:SetSizeAutoRel(Vector2(1, 0))
    border_top:SetHeight(border_size)
    border_top:SetPosition(Vector2(0, 0))
    border_top:SetColor(border_color)

    local border_right = Rectangle.Create(border_container, "border_right")
    border_right:SetSizeAutoRel(Vector2(0, 1))
    border_right:SetWidth(border_size)
    border_right:SetPosition(Vector2(border_container:GetWidth() - border_size, 0))
    border_right:SetColor(border_color)

    local border_bottom = Rectangle.Create(border_container, "border_bottom")
    border_bottom:SetSizeAutoRel(Vector2(1, 0))
    border_bottom:SetHeight(border_size)
    border_bottom:SetPosition(Vector2(0, border_container:GetHeight() - border_size))
    border_bottom:SetColor(border_color)

    local border_left = Rectangle.Create(border_container, "border_left")
    border_left:SetSizeAutoRel(Vector2(0, 1))
    border_left:SetWidth(border_size)
    border_left:SetPosition(Vector2(0, 0))
    border_left:SetColor(border_color)
    
    local function SetBorderColor(color)
        border_left:SetColor(color)
        border_bottom:SetColor(color)
        border_right:SetColor(color)
        border_top:SetColor(color)
    end
    
    button:Subscribe("Press", function(btn)
        self:ButtonClicked(window:GetDataString("name"))
    end)
    
    button:Subscribe("HoverEnter", function()
        text:SetTextColor(Color.White)
        SetBorderColor(Color.White)
        border_container:SetColor(Color(255, 255, 255, 50))
    end)
    
    button:Subscribe("HoverLeave", function()
        text:SetTextColor(text_color)
        SetBorderColor(border_color)
        border_container:SetColor(Color(255, 255, 255, 25))
    end)
    
    button:BringToFront()
end

cIntroScreen = cIntroScreen()