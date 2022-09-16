class 'cTeleporterExtension'

-- Door extension for cLandclaimObjects that allows for opening/closing
function cTeleporterExtension:__init(object)
    self.object = object
    self.timer = Timer()
    self.evenodd = 0
    self.cdelta = math.random() * 360
end

function cTeleporterExtension:StreamIn()
    self:Create(true)
    self:UpdateToExternalModules()
end

function cTeleporterExtension:StreamOut()
    self:Create(false)
    self:UpdateToExternalModules()
end

function cTeleporterExtension:UpdateToExternalModules()
end

function cTeleporterExtension:Render(args)
    local t = Transform3():Translate(self.object.position):Rotate(self.object.angle * Angle(math.pi, 0, 0))
    Render:SetTransform(t)
    
    local size = 1.2
    self.cdelta = self.cdelta + args.delta
    local color = Color.FromHSV(self.cdelta * 360 * 0.2, 0.7, 0.85)
    color.a = 100
    Render:FillArea(Vector3(-size / 2, 0.1, size / 2), Vector3(size, 3, 0), color)
    
    Render:ResetTransform()
    
    if IsValid(self.light) then
        color.a = 255
        self.light:SetColor(color) 
    end
end

function cTeleporterExtension:Create(streamed_in)
    self:Remove()

    if not self.render and streamed_in then
        self.render = Events:Subscribe("GameRender", self, self.Render)
    elseif self.render and not streamed_in then
        self.render = Events:Unsubscribe(self.render)
    end
    
    -- 135 is small thing, 137 is large thing
    if streamed_in and not self.trigger then
         self.trigger = ShapeTrigger.Create({
            position = self.object.position,
            angle = self.object.angle,
            components = {
                {
                    type = TriggerType.Sphere,
                    size = Vector3(0.5, 0.5, 0.5),
                    position = Vector3(0, 1, 0)
                }
            },
            trigger_player = true,
            trigger_player_in_vehicle = false,
            trigger_vehicle = false,
            trigger_npc = false,
            vehicle_type = VehicleTriggerType.All
        })
        self.trigger_events = {
            Events:Subscribe("ShapeTriggerEnter", self, self.ShapeTriggerEnter),
            Events:Subscribe("ShapeTriggerExit", self, self.ShapeTriggerExit)
        }
        self.light = ClientLight.Create({
            position = self.object.position + Vector3.Up * 2,
            color = Color.White,
            multiplier = 10,
            radius = 10
        })
    elseif not streamed_in and self.trigger then
        self.trigger = self.trigger:Remove()
        
        for _, event in pairs(self.trigger_events) do
            Events:Unsubscribe(event) 
        end
        
        if IsValid(self.light) then
            self.light = self.light:Remove()
        end
        
        self.trigger_events = {}
    end
end

function cTeleporterExtension:ShapeTriggerEnter(args)
    if not self.trigger or args.trigger:GetId() ~= self.trigger:GetId() then return end
    if LocalPlayer:GetValue("InTeleporter") or LocalPlayer:GetValue("Loading") then return end
    Network:Send("build/EnterTeleporter", {
        tp_id = self.object.custom_data.tp_id
    })
end

function cTeleporterExtension:ShapeTriggerExit(args)
    if not self.trigger or args.trigger:GetId() ~= self.trigger:GetId() then return end
    -- Do nothing
    Network:Send("build/ExitTeleporter", {
        tp_id = self.object.custom_data.tp_id
    })
end

function cTeleporterExtension:Remove()
    if self.render then
        self.render = Events:Unsubscribe(self.render)
    end
    if IsValid(self.trigger) then
        self.trigger:Remove()
    end
    if IsValid(self.light) then
        self.light:Remove()
    end
end

function cTeleporterExtension:StateUpdated()
end

function cTeleporterExtension:Activate()
end

class 'TeleporterExtensionMenu'

function TeleporterExtensionMenu:__init()
    
    self.open = false
    
    self.link_id_menu = Window.Create()
    self.link_id_menu:SetTitle("Set Teleporter Link ID")
    self.link_id_menu:SetSize(Vector2(400, 140))
    self.link_id_menu:SetPosition(Render.Size / 2 - self.link_id_menu:GetSize() / 2)
    self.link_id_menu:SetClampMovement(false)
    self.link_id_menu:Subscribe("WindowClosed", self, self.CloseMenu)

    self.link_id_input = TextBox.Create(self.link_id_menu)
    self.link_id_input:SetTextSize(28)
    self.link_id_input:SetMargin(Vector2(4, 4), Vector2(4, 4))
    self.link_id_input:SetDock(GwenPosition.Fill)
    self.link_id_input:SetAlignment(GwenPosition.Center)
    self.link_id_input:SetFont(AssetLocation.Disk, "Archivo.ttf")
	self.link_id_input:Subscribe("TextChanged", self, self.InputChanged)

    local input_btn = Button.Create(self.link_id_menu)
    input_btn:SetText("Save")
    input_btn:SetTextSize(20)
    input_btn:SetSize(Vector2(self.link_id_menu:GetSize().x, 40))
    input_btn:SetMargin(Vector2(0, 10), Vector2(0, 0))
    input_btn:SetDock(GwenPosition.Bottom)
    input_btn:Subscribe("Press", self, self.PressSaveButton)
    input_btn:SetFont(AssetLocation.Disk, "Archivo.ttf")

    self.link_id_menu:Hide()

end

local MAX_TEXT_LENGTH = 5

function TeleporterExtensionMenu:Show(tp_id, object)
    self.link_id_input:SetText(tp_id or "")
    self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    Mouse:SetVisible(true)
    self.object = object
    self.open = true
    self.link_id_menu:Show()
end

function TeleporterExtensionMenu:GetText()
    return self.link_id_input:GetText()
end

function TeleporterExtensionMenu:InputChanged(textbox)
    local text = textbox:GetText()
    text = text:sub(1, MAX_TEXT_LENGTH):upper()
    
    textbox:SetText(text)
end

function TeleporterExtensionMenu:PressSaveButton()
    Network:Send("build/EditTeleporterLinkId", {
        tp_link_id = self:GetText(),
        landclaim_id = self.object.landclaim.id, 
        landclaim_owner_id = self.object.landclaim.owner_id,
        id = self.object.id
    })
    self:CloseMenu()
end

function TeleporterExtensionMenu:LocalPlayerInput(args)
    return false
end

function TeleporterExtensionMenu:CloseMenu()
    self.link_id_menu:Hide()
    Events:Unsubscribe(self.lpi)
    self.lpi = nil
    Mouse:SetVisible(false)
    self.open = false
end

TeleporterExtensionMenu = TeleporterExtensionMenu()

local max_fov = 3
local default_fov = Camera:GetFOV()
local dtime = 0
local time = 3
local wait_time = 4
local sub, sub2 = nil

function RenderTeleport(args)
    dtime = dtime + args.delta
    
    if dtime < (time + wait_time) then
        local color = Color(255, 255, 255, math.min(255, dtime / time * 255))
        Render:FillArea(Vector2.Zero, Render.Size, color)
        Camera:SetFOV(math.min(max_fov, default_fov + dtime / time * (max_fov - default_fov)))
    elseif dtime < (time * 2) + wait_time then
        local color = Color(255, 255, 255, 255 - (dtime - time - wait_time) / time * 255)
        Render:FillArea(Vector2.Zero, Render.Size, color)
        Camera:SetFOV(math.max(default_fov, max_fov - (dtime - time - wait_time) / time * (max_fov - default_fov)))
    else
        sub = Events:Unsubscribe(sub)
        sub2 = Events:Unsubscribe(sub2)
        Camera:SetFOV(default_fov)
    end
end

function BlockActions()
    return false 
end

function StartTeleporting()
    current_fov = default_fov
    dtime = 0
    sub = Events:Subscribe("PostRender", RenderTeleport)
    sub2 = Events:Subscribe("LocalPlayerInput", BlockActions)
end

Network:Subscribe("build/TeleporterActivate", function(args)
    ClientEffect.Play(AssetLocation.Game, {position = args.pos1, angle = Angle(0,0,0), effect_id = 135})
    ClientEffect.Play(AssetLocation.Game, {position = args.pos1, angle = Angle(0,0,0), effect_id = 137})
    
    if args.id == LocalPlayer:GetId() then
        
        LocalPlayer:SetValue("LocalTeleporting", true)
        -- Game:FireEvent(var("ply.pause"):get())
        Game:FireEvent("ply.parachute.disable")
        StartTeleporting()
    
        Thread(function()
            local i = 0
            while LandclaimManager and LandclaimManager:AreAnyLandclaimsLoading() or i < 10 do
                Timer.Sleep(1000)
                i = i + 1
            end
            Game:FireEvent("ply.parachute.enable")
            LocalPlayer:SetValue("LocalTeleporting", false)
            Network:Send("build/FinishTeleporting")
            ClientEffect.Play(AssetLocation.Game, {position = args.pos2, angle = Angle(0,0,0), effect_id = 135})
        end)
    end
    
end)

Network:Subscribe("build/TeleporterActivate2", function(args)
    ClientEffect.Play(AssetLocation.Game, {position = args.pos, angle = Angle(0,0,0), effect_id = 137})
end)