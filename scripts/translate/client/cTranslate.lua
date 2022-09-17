class 'cTranslate'

function cTranslate:__init()
    
    self:CreateWindow()
    Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
    Network:Subscribe("OpenTranslateWindow", self, self.OpenTranslateWindow)

end

function cTranslate:OpenTranslateWindow()
    self:ShowWindow() 
end

function cTranslate:ShowWindow()
    self:HideWindow()
    self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    self.window:Show()
    Mouse:SetVisible(true)
end

function cTranslate:LocalPlayerInput()
    return false
end

function cTranslate:HideWindow()
    if self.lpi then
        self.lpi = Events:Unsubscribe(self.lpi)
    end
    Mouse:SetVisible(false)
    self.window:Hide()
end

function cTranslate:LocalPlayerChat(args)
    if args.text == "/language" then
        self:ShowWindow()
    end
end

function cTranslate:CreateWindow()
    
    self.window = Window.Create()
    self.window:SetTitle("Chat Language")
    self.window:SetClosable(false) 
    self.window:DisableResizing()
    self.window:SetClampMovement(true)
    self.window:Hide()
    self.window:SetSize(Vector2(400, 500))
    self.window:SetPosition(Vector2(Render.Size.x / 2, Render.Size.y / 2) - self.window:GetSize() / 2)
    
    local list = SortedList.Create(self.window)
    list:SetDock(GwenPosition.Fill)
    list:AddColumn("Language")
    list:SetButtonsVisible(true)
    list:SetPadding(Vector2(0, 0), Vector2(0, 0))

    list:SetSort(
        function(column, a, b)
            if column ~= -1 then
                self.last_column = column
            elseif column == -1 and self.last_column ~= -1 then
                column = self.last_column
            else
                column = 0
            end

            local a_value = a:GetDataString("name")
            local b_value = b:GetDataString("name")

            if self.sort_dir then
                return a_value > b_value
            else
                return a_value < b_value
            end
        end
    )

    for locale, name in pairs(Languages) do

        local item = list:AddItem(tostring(locale))
        item:SetCellText(0, name)

        local btn = Button.Create(item)
        btn:SetText(name)
        btn:SetTextSize(18)
        btn:SetSize(Vector2(380, 40))
        btn:SetDataString("locale", tostring(locale))
        btn:SetDataString("name", tostring(name))
        btn:SetFont(AssetLocation.Disk, "Archivo.ttf")
        item:SetDataString("locale", tostring(locale))
        item:SetDataString("name", tostring(name))
        item:SetCellContents(0, btn)
        btn:Subscribe("Press", self, self.PressButton)
    end 
    
    list:Sort()
end

function cTranslate:PressButton(btn)
    local locale = btn:GetDataString("locale")
    self:HideWindow()
    Network:Send("SetLanguage", {locale = locale})
end

cTranslate = cTranslate()