class 'cAirdropManager'

function cAirdropManager:__init()

    self.airdrop = {}

    if IsTest then
        self.locations = {}
        Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
    end

    Network:Subscribe("airdrops/SendSyncData", self, self.GetSyncData)
    Network:Subscribe("airdrops/RemoveAirdrop", self, self.RemoveAirdrop)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cAirdropManager:RemoveAirdrop()

    Events:Fire("airdrops/RemoveAirdropFromMap")

    if self.airdrop.object then
        self.airdrop.object:Remove()
    end

    self.airdrop = {}
end

function cAirdropManager:ModuleUnload()
    Events:Fire("airdrops/RemoveAirdropFromMap")

    if self.airdrop.object then
        self.airdrop.object:Remove()
    end
end

function cAirdropManager:GetSyncData(args)
    for k,v in pairs(args) do
        self.airdrop[k] = v
    end
    self.airdrop.timer = Timer()

    if self.airdrop.active then
        if not self.render then
            self.render = Events:Subscribe("Render", self, self.Render)
        end

        if self:GetTimeUntilDrop() > 0 then
            Events:Fire("airdrops/AddGeneralLocationToMap", {
                name = string.format("INCOMING AIRDROP (LEVEL %d)", self.airdrop.type),
                position = self.airdrop.general_location,
                radius = self.airdrop.preview_size
            })
        else

            if not self.airdrop.precise_announce then
                Events:Fire("airdrops/AddGeneralLocationToMap", {
                    name = string.format("UNOPENED AIRDROP (LEVEL %d)", self.airdrop.type),
                    position = self.airdrop.general_location,
                    radius = self.airdrop.preview_size
                })

                Events:Fire("Flare", {
                    position = self.airdrop.position,
                    time = 60 * 10
                })

            end

        end

        if self.airdrop.precise_announce then
            
            Events:Fire("airdrops/AddPreciseLocationToMap", {
                name = string.format("AIRDROP (LEVEL %d)", self.airdrop.type),
                position = self.airdrop.position
            })

        end

        if self.airdrop.doors_destroyed and self.airdrop.object then
            self.airdrop.object:RemoveKey("door")
        end
    
    end
end

-- Create airdrop from the sky
function cAirdropManager:CreateAirdrop()
    if self.airdrop.object then return end
    if LocalPlayer:GetHealth() <= 0 then return end
    if LocalPlayer:GetValue("Loading") then return end

    self.airdrop.object = cAirdropObject({
        position = self.airdrop.position + Vector3(0, 500, 0),
        angle = self.airdrop.angle,
        target_position = self.airdrop.position
    })

    if self.airdrop.doors_destroyed then
        self.airdrop.object:RemoveKey("door")
    end
end

function cAirdropManager:AirdropHitGround()
    self.airdrop.object:RemoveKey("parachute")
end

function cAirdropManager:Render(args)
    if self.airdrop.active and self.airdrop.position then
        self:RenderAirdropInfo()

        if self:GetTimeUntilDrop() < 0 then
            local dist = Camera:GetPosition():Distance(self.airdrop.position)
            if not self.airdrop.object and dist < 2000 then
                self:CreateAirdrop()
            elseif self.airdrop.object and dist > 2000 then
                self.airdrop.object = self.airdrop.object:Remove()
                self.airdrop.on_ground = false
            end
        end

        if self.airdrop.object and not self.airdrop.on_ground then
            local progress = math.min(1, -self:GetTimeUntilDrop() / 0.75)
            self.airdrop.on_ground = progress == 1
            self.airdrop.object:SetPosition(
                math.lerp(self.airdrop.position + Vector3(0, 500, 0), self.airdrop.position, math.min(1, -self:GetTimeUntilDrop() / 0.75)))

            if self.airdrop.on_ground then
                self:AirdropHitGround()
            end
        end
        
    end
end

function cAirdropManager:GetTimeUntilDrop()
    return self.airdrop.preview_time - (self.airdrop.timer:GetMinutes() + self.airdrop.time_elapsed)
end

-- Renders information about the airdrop on the side of the screen
function cAirdropManager:RenderAirdropInfo()

    Render:SetFont(AssetLocation.Disk, "Archivo.ttf")
    local airdrop_time = math.ceil(self:GetTimeUntilDrop())
    
    if airdrop_time < -15 then return end

    local text

    if airdrop_time > 0 then
        -- Package has not dropped yet
        text = string.format("LEVEL %d AIRDROP INCOMING (%d MINUTES UNTIL DROP - SEE MAP)", self.airdrop.type, airdrop_time)
    else
        -- Package has dropped
        text = string.format("LEVEL %d AIRDROP (%d MINUTES SINCE DROP - SEE MAP)", self.airdrop.type, -airdrop_time)
    end

    if self.airdrop.precise_announce then return end

    local render_size = Render.Size
    local size = Render.Size.y * 0.03
    local text_size = Render:GetTextSize(text, size)
    local shadow_size = 2
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2) + Vector2(shadow_size, shadow_size),
        text,
        Color.Black,
        size)
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2) + Vector2(0, shadow_size),
        text,
        Color.Black,
        size)
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2) + Vector2(0, -shadow_size),
        text,
        Color.Black,
        size)
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2) + Vector2(shadow_size, 0),
        text,
        Color.Black,
        size)
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2) + Vector2(-shadow_size, 0),
        text,
        Color.Black,
        size)
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2) + Vector2(-shadow_size, shadow_size),
        text,
        Color.Black,
        size)
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2) + Vector2(shadow_size, -shadow_size),
        text,
        Color.Black,
        size)
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2) + Vector2(-shadow_size, -shadow_size),
        text,
        Color.Black,
        size)
    Render:DrawText(
        Vector2(render_size.x / 2 - text_size.x / 2, render_size.y * 0.15 - text_size.y / 2),
        text,
        Color.Orange,
        size)

end

function cAirdropManager:LocalPlayerChat(args)
    if args.text == "/loc" then
        table.insert(self.locations, LocalPlayer:GetPosition())
        Chat:Print("Saved location", Color.LawnGreen)
    elseif args.text == "/printloc" then
        print("---------------------")
        for _, pos in pairs(self.locations) do
            print(string.format("Vector3(%.3f, %.3f, %.3f),", pos.x, pos.y, pos.z))
        end
        print("---------------------")
        Chat:Print("Printed all locations", Color.LawnGreen)
    elseif args.text == "/ac" then
        self.airdrop.object = cAirdropObject({
            position = LocalPlayer:GetPosition(), 
            angle = LocalPlayer:GetAngle()})
    end
end

cAirdropManager = cAirdropManager()