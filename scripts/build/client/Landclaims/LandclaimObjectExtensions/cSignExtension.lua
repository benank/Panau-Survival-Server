class 'cSignExtension'

-- Door extension for cLandclaimObjects that allows for opening/closing
function cSignExtension:__init(object)
    self.object = object
    self.timer = Timer()
    self.evenodd = 0
end

-- Adjust door angle upon streaming in
function cSignExtension:StreamIn()
    self:Create(true)
    self:UpdateToExternalModules()
end

function cSignExtension:StreamOut()
    self:Create(false)
    self:UpdateToExternalModules()
end

function cSignExtension:UpdateToExternalModules()
    local event = self.object.has_collision and "build/SpawnObject" or "build/DespawnObject"
    Events:Fire(event, {
        landclaim_id = self.object.landclaim.id,
        landclaim_owner_id = self.object.landclaim.owner_id,
        id = self.object.id,
        cso_id = self.pole_object:GetId()
    })
end

function cSignExtension:Render(args)
    if self.object.custom_data.text and self.object.custom_data.color then
        
        if SignExtensionMenu.open and SignExtensionMenu.id == self.object.id then
            self.object.custom_data.text = SignExtensionMenu:GetText()
            self.object.custom_data.color = SignExtensionMenu:GetColor()
        end
        
        local t = Transform3():Translate(self.object.position):Rotate(self.object.angle)
        t = t:Translate(Vector3(0.3, 0.85, 0.015)):Rotate(Angle(0, math.pi, -math.pi / 2))
        Render:SetTransform(t)
        Render:DrawText(Vector3.Zero, self.object.custom_data.text, self.object.custom_data.color, 100, 0.003)
        Render:ResetTransform()
    end
    
end

function cSignExtension:Create(streamed_in)
    self:Remove()
    self.angle = self.object.angle * BuildObjects["Sign"].pole.angle
    self.pole_object = ClientStaticObject.Create({
        position = self.object.position + self.angle * BuildObjects["Sign"].pole.offset,
        angle = self.object.angle * BuildObjects["Sign"].pole.angle,
        model = BuildObjects["Sign"].pole.model,
        collision = streamed_in and BuildObjects["Sign"].pole.collision or ""
    })

    if not self.render and streamed_in then
        self.render = Events:Subscribe("GameRender", self, self.Render)
    elseif self.render and not streamed_in then
        self.render = Events:Unsubscribe(self.render)
    end

    self.pole_object:SetValue("LandclaimObject", self.object)
end

function cSignExtension:Remove()
    if self.pole_object then
        self.pole_object = self.pole_object:Remove()
    end

    if self.render then
        self.render = Events:Unsubscribe(self.render)
    end
end

function cSignExtension:StateUpdated()
end

function cSignExtension:Activate()
end

class 'SignExtensionMenu'

function SignExtensionMenu:__init()
    
    self.open = false
    self.id = 0
    
    self.color_picker = HSVColorPicker.Create()
    self.color_picker:SetSize(Vector2(400,300))
    self.color_picker:SetPosition(Render.Size / 2 - self.color_picker:GetSize() / 2)
    self.color_picker:Hide()
    
    self.submit_button = Button.Create(self.color_picker)
    self.submit_button:SetText("Save")
    self.submit_button:SetTextSize(26)
    self.submit_button:SetHeight(40)
    self.submit_button:SetMargin(Vector2(0, 10), Vector2(0, 0))
    self.submit_button:SetDock(GwenPosition.Bottom)
    self.submit_button:Subscribe("Press", self, self.PressColorSubmitButton)
    
    self.input_field2 = TextBox.Create(self.color_picker)
    self.input_field2:SetText("Sample Text")
    self.input_field2:SetTextSize(14)
    self.input_field2:SetHeight(20)
    self.input_field2:SetMargin(Vector2(0, 10), Vector2(0, 0))
    self.input_field2:SetDock(GwenPosition.Bottom)
    self.input_field2:SetAlignment(GwenPosition.Left + GwenPosition.CenterV)
	self.input_field2:Subscribe("TextChanged", self, self.InputChanged)

    self.input_field1 = TextBox.Create(self.color_picker)
    self.input_field1:SetText("Sample Text")
    self.input_field1:SetTextSize(14)
    self.input_field1:SetHeight(20)
    self.input_field1:SetMargin(Vector2(0, 10), Vector2(0, 0))
    self.input_field1:SetDock(GwenPosition.Bottom)
    self.input_field1:SetAlignment(GwenPosition.Left + GwenPosition.CenterV)
	self.input_field1:Subscribe("TextChanged", self, self.InputChanged)

end

local MAX_TEXT_LENGTH = 11

function SignExtensionMenu:InputChanged(textbox)
    local text = textbox:GetText()
    text = text:sub(1, MAX_TEXT_LENGTH)
    
    textbox:SetText(text)
end

function SignExtensionMenu:Show(text, color, id, object)
    local split = text:split("\n")
    self.input_field1:SetText(split[1])
    self.input_field2:SetText(split[2] or "")
    self.color_picker:SetColor(color)
    self.color_picker:Show()
    self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    Mouse:SetVisible(true)
    self.id = id
    self.object = object
    self.open = true
end

function SignExtensionMenu:GetText()
    return self.input_field1:GetText():sub(1, MAX_TEXT_LENGTH) .. "\n" .. self.input_field2:GetText():sub(1, MAX_TEXT_LENGTH)
end

function SignExtensionMenu:GetColor()
    return  self.color_picker:GetColor()
end

function SignExtensionMenu:PressColorSubmitButton()
    Network:Send("build/EditSign", {
        color = self:GetColor(),
        text = self:GetText(),
        landclaim_id = self.object.landclaim.id, 
        landclaim_owner_id = self.object.landclaim.owner_id,
        id = self.object.id
    })
    self:CloseMenu()
end

function SignExtensionMenu:LocalPlayerInput(args)
    return false
end

function SignExtensionMenu:CloseMenu()
    self.color_picker:Hide()
    Events:Unsubscribe(self.lpi)
    self.lpi = nil
    Mouse:SetVisible(false)
    self.open = false
end

SignExtensionMenu = SignExtensionMenu()