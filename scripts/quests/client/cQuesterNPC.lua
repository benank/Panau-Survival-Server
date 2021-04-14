class 'cQuesterNPC'

QuesterConfig = 
{
    position = Vector3(-10334.650391, 203.063522, -2996.068604),
    angle = Angle(-0.774175, 0.000000, 0.000000),
    model_id = 2
}

function cQuesterNPC:__init()
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
end

function cQuesterNPC:ModuleUnload()
    self.client_actor:Remove()
    self.light:Remove()
end

cQuesterNPC = cQuesterNPC()