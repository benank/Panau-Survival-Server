class 'cNitro'

function cNitro:__init()

    self.equipped = false
    self.sync_timer = Timer()
    self.dura_change = 0

    self.boosting = false

    self.base_boose_amount = 0.1
    self.boost_amount = self.base_boose_amount

    self.perks = 
    {
        [27] = 
        {
            [2] = 0.2
        },
        [81] = 
        {
            [2] = 0.2
        },
        [121] = 
        {
            [2] = 0.2
        }
    }

    self.vehicles_with_nitro = {}
    
    Events:Subscribe("PostTick", self, self.PostTick)
    Network:Subscribe(var("items/ToggleEquippedNitro"):get(), self, self.ToggleEquipped)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated)

end

function cNitro:PlayerPerksUpdated()

    local perks = LocalPlayer:GetValue("Perks")
    local boost = self.base_boose_amount

    for perk_id, data in pairs(self.perks) do
        local choice = perks.unlocked_perks[perk_id]
        if choice and self.perks[perk_id][choice] then
            boost = boost + self.base_boose_amount * self.perks[perk_id][choice]
        end
    end

    self.boost_amount = boost

end

function cNitro:ModuleUnload()
    for id, data in pairs(self.vehicles_with_nitro) do
        for _, effect in pairs(data.effects) do
            effect:Remove()
        end
    end
end

function cNitro:ToggleEquipped(args)
    self.equipped = args.equipped
    self.uid = self.equipped and args.uid or 0

    self.boosting = false
    self.boosting_synced = false

    if self.equipped and not self.lpi then
        self.lpi = Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
    elseif not self.equipped and self.lpi then
        self.lpi = Events:Unsubscribe(self.lpi)
    end

    if not self.equipped and LocalPlayer:InVehicle() then
        
        Network:Send("items/DeactivateNitro", {
            id = LocalPlayer:GetVehicle():GetId()
        })

    end

end

function cNitro:LocalPlayerInput(args)

    if not self.equipped then return end

    if not LocalPlayer:InVehicle() then return end

    local v = LocalPlayer:GetVehicle()
    if v:GetDriver() ~= LocalPlayer then return end

    local boost_key = v:GetClass() == VehicleClass.Air and Action.SoundHornSiren or Action.Dash

    if args.input ~= boost_key then return end

    if v:GetValue("DisabledByEMP") then return end

    local forward = v:GetAngle() * Vector3.Forward
    local speed = -(-v:GetAngle() * v:GetLinearVelocity()).z
    v:SetLinearVelocity(v:GetLinearVelocity() + forward * self.boost_amount)

    self.boosting = true

    if self.boost_timer then 
        Timer.Clear(self.boost_timer)
        self.boost_timer = nil
    end

    self.boost_timer = Timer.SetTimeout(100, function()
        self.boosting = false
        self.boost_timer = nil
    end)

end

function cNitro:PostTick(args)

    if self.sync_timer:GetSeconds() > 2 and self.dura_change > 0 then
        Network:Send(var("items/NitroDecreaseDura"):get(), {uid = self.uid, change = math.ceil(self.dura_change)})
        
        self.sync_timer:Restart()
        self.dura_change = 0
    end

    if self.boosting and not self.boosting_synced then

        Network:Send("items/ActivateNitro")

        self.boosting_synced = true
    elseif not self.boosting and self.boosting_synced and LocalPlayer:InVehicle() then

        Network:Send("items/DeactivateNitro", {
            id = LocalPlayer:GetVehicle():GetId()
        })

        self.boosting_synced = false
    end

    for v in Client:GetVehicles() do

        local id = v:GetId()

        if self.vehicles_with_nitro[id] and not v:GetValue("NitroActive") then
            
            for _, effect in pairs(self.vehicles_with_nitro[id].effects) do
                effect:Remove()
            end

            self.vehicles_with_nitro[id] = nil
        elseif not self.vehicles_with_nitro[id] and v:GetValue("NitroActive") then
            local effects = {}

            local num_effects = nitro_offsets[v:GetModelId()] and count_table(nitro_offsets[v:GetModelId()]) or 1
            for i = 1, num_effects do
                effects[i] = ClientEffect.Create(AssetLocation.Game, {
                    position = v:GetPosition(),
                    angle = v:GetAngle(),
                    effect_id = 172
                })
            end

            self.vehicles_with_nitro[id] = 
            {
                effects = effects,
                vehicle = v
            }
        end

    end

    for id, data in pairs(self.vehicles_with_nitro) do

        if IsValid(data.vehicle) and data.vehicle:GetValue("NitroActive") then

            local offsets = self:GetVehicleOffsets(data.vehicle:GetModelId())
            for _, effect in pairs(data.effects) do

                effect:SetPosition(data.vehicle:GetPosition() + data.vehicle:GetAngle() * offsets[_])
                effect:SetAngle(data.vehicle:GetAngle())

            end

        else
            for _, effect in pairs(self.vehicles_with_nitro[id].effects) do
                effect:Remove()
            end
            self.vehicles_with_nitro[id] = nil
        end

    end

    if self.boosting then
        self.dura_change = self.dura_change + args.delta
    end

end

function cNitro:GetVehicleOffsets(model_id)
    return nitro_offsets[model_id] or {Vector3(0, 0.5, 3)}
end

nitro_offsets = 
{
    [59] = {Vector3(0, 2, 5)},
    [30] = {Vector3(0, 1.5, 4.5)},
    [34] = {Vector3(2, 3, 20), Vector3(-2, 3, 20)},
    [37] = {Vector3(0, 2, 3)},
    [57] = {Vector3(0, 2, 3)},
    [39] = {Vector3(6, 2, 10), Vector3(-6, 2, 10)},
    [62] = {Vector3(0, 2, 3)},
    [67] = {Vector3(0, 2, 3)},
    [85] = {Vector3(8, 4, 6), Vector3(-8, 4, 6), Vector3(18.5, 3.5, 6), Vector3(-18.5, 3.5, 6)}
}

cNitro = cNitro()
