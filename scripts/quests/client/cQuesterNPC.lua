class 'cQuesterNPC'

function cQuesterNPC:__init()
    self.near_quester = false
    
    self.client_actor = ClientActor.Create(AssetLocation.Game, {
        model_id = QuesterConfig.model_id,
        position = QuesterConfig.position,
        angle = QuesterConfig.angle
    })
    
    self.light = ClientLight.Create({
        position = QuesterConfig.position + Vector3.Up * 3,
        color = Color.White,
        radius = 5,
        multiplier = 8
    })
    
    LocalPlayer:SetValue("QuesterActorId", self.client_actor:GetId())
    
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("EnterSafezone", self, self.EnterSafezone)
    Events:Subscribe("ExitSafezone", self, self.ExitSafezone)
end

function cQuesterNPC:RenderOpenIndicator()
    if QuestMenu:GetActive() then return end
    
    local text = "Press E to interact"
    local font_size = 24
    local text_size = Render:GetTextSize(text, font_size)
    local pos = Render.Size / 2
    
    local padding = 10
    local box_top_left = pos - text_size / 2 - Vector2(padding, padding)
    local box_size = text_size + Vector2(padding, padding) * 2
    
    Render:FillArea(box_top_left, box_size, Color(0, 0, 0, 150))
    
    Render:DrawText(pos - text_size / 2, text, Color.White, font_size)
    Render:DrawLine(box_top_left, box_top_left + Vector2(box_size.x, 0), Color.White)
    Render:DrawLine(box_top_left, box_top_left + Vector2(0, box_size.y), Color.White)
    Render:DrawLine(box_top_left + Vector2(box_size.x, 0), box_top_left + Vector2(box_size.x, 0) + Vector2(0, box_size.y), Color.White)
    Render:DrawLine(box_top_left + Vector2(0, box_size.y), box_top_left + Vector2(0, box_size.y) + Vector2(box_size.x, 0), Color.White)
end

function cQuesterNPC:Render(args)
    local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 8)
    
    if ray.entity and ray.entity.__type == "ClientActor" and ray.entity:GetId() == self.client_actor:GetId() then
        self:RenderOpenIndicator()
        self.near_quester = true
    else
        self.near_quester = false
    end
end

function cQuesterNPC:EnterSafezone()
    if not self.render then
        self.render = Events:Subscribe("Render", self, self.Render)
    end 
end

function cQuesterNPC:ExitSafezone()
    if self.render then
        self.render = Events:Unsubscribe(self.render)
    end
end

function cQuesterNPC:ModuleUnload()
    self.client_actor:Remove()
    self.light:Remove()
end

cQuesterNPC = cQuesterNPC()