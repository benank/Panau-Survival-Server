class 'cAirdropManager'

function cAirdropManager:__init()

    self.airdrop = {}

    if IsTest then
        self.locations = {}
        Events:Subscribe("LocalPlayerChat", self, self.LocalPlayerChat)
    end

    Network:Subscribe("airdrops/SendSyncData", self, self.GetSyncData)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

end

function cAirdropManager:ModuleUnload()
    Events:Fire("airdrops/RemoveAirdropFromMap")
end

function cAirdropManager:GetSyncData(args)
    self.airdrop = args
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
            Events:Fire("airdrops/AddPreciseLocationToMap", {
                name = string.format("AIRDROP (LEVEL %d)", self.airdrop.type),
                position = self.airdrop.position
            })

            self:CreateAirdrop()
        end
    end
end

-- Create airdrop from the sky
function cAirdropManager:CreateAirdrop()
    
end

function cAirdropManager:Render(args)
    if self.airdrop.active then
        self:RenderAirdropInfo()
    end
end

function cAirdropManager:GetTimeUntilDrop()
    return self.airdrop.preview_time - (self.airdrop.timer:GetMinutes() + self.airdrop.time_elapsed)
end

-- Renders information about the airdrop on the side of the screen
function cAirdropManager:RenderAirdropInfo()

    local airdrop_time = math.ceil(self:GetTimeUntilDrop())

    local text

    if airdrop_time > 0 then
        -- Package has not dropped yet
        text = string.format("LEVEL %d AIRDROP INCOMING (%d MINUTES UNTIL DROP - SEE MAP)", self.airdrop.type, airdrop_time)
    else
        -- Package has dropped
        text = string.format("LEVEL %d AIRDROP (%d MINUTES SINCE DROP - SEE MAP)", self.airdrop.type, -airdrop_time)
    end

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
            print(string.format("{x = %.3f, y = %.3f, z = %.3f},", pos.x, pos.y, pos.z))
        end
        print("---------------------")
        Chat:Print("Printed all locations", Color.LawnGreen)
    end
end

cAirdropManager = cAirdropManager()