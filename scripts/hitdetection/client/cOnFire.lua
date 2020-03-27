class 'cOnFire'

function cOnFire:__init()

    self.on_fire_players = {}

    Events:Subscribe("Render", self, self.Render)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cOnFire:ModuleUnload()
    for id, data in pairs(self.on_fire_players) do
        data.effect:Remove()
    end
end

function cOnFire:CheckPlayer(player)

    local steam_id = tostring(player:GetSteamId())

    if player:GetValue("OnFire") and not self.on_fire_players[steam_id] then
        self.on_fire_players[steam_id] = 
        {
            player = player,
            effect = ClientEffect.Create(AssetLocation.Game, {
                effect_id = 240,
                position = Vector3(),
                angle = Angle()
            })
        }
    elseif not player:GetValue("OnFire") and self.on_fire_players[steam_id] then
        self.on_fire_players[steam_id].effect:Remove()
        self.on_fire_players[steam_id] = nil
    end


end

function cOnFire:Render(args)

    for p in Client:GetStreamedPlayers() do
        self:CheckPlayer(p)
    end

    self:CheckPlayer(LocalPlayer)

    for id, data in pairs(self.on_fire_players) do
        if IsValid(data.player) then
            data.effect:SetPosition(data.player:GetBonePosition("ragdoll_Spine"))
            data.effect:SetAngle(data.player:GetBoneAngle("ragdoll_Spine"))
        else
            self.on_fire_players[id].effect:Remove()
            self.on_fire_players[id] = nil
        end
    end

end

cOnFire = cOnFire()