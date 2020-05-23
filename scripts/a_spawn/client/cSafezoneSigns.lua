class 'cSafezoneSigns'

function cSafezoneSigns:__init()

    self.signs = {}
    self:LoadImages()

    self.stats =  -- Dynamic server stats for billboard
    {
        ["PlayersOnline"] = {
            text = "Players Online: %s",
            value = 0,
            position = Vector3(-10252.943359, 261.488586, -2957.324219),
            angle = Angle(0.523597 + math.pi, math.pi, 0),
            color = Color.White,
            fontsize = 50,
            scale = 0.03
        }
    }

    self.lights = {}
    self:CreateLights()

    Events:Subscribe("SecondTick", self, self.SecondTick)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)

    Network:Subscribe("ServerStats/UpdatePlayersOnline", self, self.UpdatePlayersOnline)

end

function cSafezoneSigns:LoadImages()

    Thread(function()
    
        Timer.Sleep(3000)
        self.signs["Lootboxes"] = 
        {
            image = Image.Create(AssetLocation.Resource, "Safezone_Lootboxes"),
            size = Vector2(1200, 500),
            scale = 9,
            position = Vector3(-10264.067383, 207.745816, -2979.312988),
            angle = Angle(0.523599 + math.pi, 0, 0)
        }

        Timer.Sleep(1000)
        self.signs["ServerBasics"] = 
        {
            image = Image.Create(AssetLocation.Resource, "Safezone_ServerBasics"),
            size = Vector2(1200, 500),
            scale = 9,
            position = Vector3(-10284.602539, 207.755768, -2967.457031),
            angle = Angle(0.523599 + math.pi, 0, 0)
        }

        Timer.Sleep(1000)
        self.signs["Keybinds"] = 
        {
            image = Image.Create(AssetLocation.Resource, "Safezone_Keybinds"),
            size = Vector2(1200, 500),
            scale = 9,
            position = Vector3(-10242.552734, 207.746216, -2991.734619),
            angle = Angle(0.523599 + math.pi, 0, 0)
        }

        Timer.Sleep(1000)
        self.signs["Rules"] = 
        {
            image = Image.Create(AssetLocation.Resource, "Safezone_Rules"),
            size = Vector2(1200, 500),
            scale = 9,
            position = Vector3(-10259.183594, 209.923981, -3052.387451),
            angle = Angle(2.277459 + math.pi, 0, 0)
        }

        Timer.Sleep(1000)
        self.signs["Team"] = 
        {
            image = Image.Create(AssetLocation.Resource, "Safezone_Team"),
            size = Vector2(1200, 500),
            scale = 7,
            position = Vector3(-10303.698242, 207.763489, -2956.489014),
            angle = Angle(0.523599 + math.pi, 0, 0)
        }

        Timer.Sleep(1000)
        self.signs["Welcome"] = 
        {
            image = Image.Create(AssetLocation.Resource, "Safezone_Welcome"),
            size = Vector2(1000, 2000),
            scale = 50,
            position = Vector3(-10262.698242, 254.607315, -2951.677490),
            angle = Angle(0.523599 + math.pi, 0, 0)
        }

        Timer.Sleep(1000)
        self.signs["GetConnected"] = 
        {
            image = Image.Create(AssetLocation.Resource, "Safezone_GetConnected"),
            size = Vector2(2128, 276),
            scale = 2.5,
            position = Vector3(-10341.725586, 205.002228, -3062.086182),
            angle = Angle(-2.094716 + math.pi, 0, 0)
        }

        Timer.Sleep(1000)
        self:CreateModels()

        self.models_created = true
    
    end)

end

function cSafezoneSigns:UpdatePlayersOnline(args)
    self.stats["PlayersOnline"].value = args.online
end

function cSafezoneSigns:ModuleUnload()
    for _, light in pairs(self.lights) do
        if IsValid(light) then light:Remove() end
    end
end

function cSafezoneSigns:CreateLights()
    self.lights = 
    {
        ClientLight.Create({
            position = Vector3(-10258.063477, 204.949310, -2983.842529),
            color = Color.White,
            multiplier = 10,
            radius = 3
        }),
        ClientLight.Create({
            position = Vector3(-10262.489258, 205.024124, -2981.366943),
            color = Color.White,
            multiplier = 10,
            radius = 3
        }),
        ClientLight.Create({
            position = Vector3(-10267.399414, 205.209122, -2978.529785),
            color = Color.White,
            multiplier = 10,
            radius = 3
        }),
        ClientLight.Create({
            position = Vector3(-10271.967773, 204.995300, -2975.908936),
            color = Color.White,
            multiplier = 10,
            radius = 3
        }),
    }
end


function cSafezoneSigns:CreateSprite(image, scale)
    local imageSize = image:GetSize()
    local size = Vector2(imageSize.x / imageSize.y, 1) / 2 * scale
    local uv1, uv2 = image:GetUV()
 
    local sprite = Model.Create({
       Vertex(Vector2(-size.x, size.y), Vector2(uv1.x, uv1.y)),
       Vertex(Vector2(-size.x,-size.y), Vector2(uv1.x, uv2.y)),
       Vertex(Vector2( size.x,-size.y), Vector2(uv2.x, uv2.y)),
       Vertex(Vector2( size.x,-size.y), Vector2(uv2.x, uv2.y)),
       Vertex(Vector2( size.x, size.y), Vector2(uv2.x, uv1.y)),
       Vertex(Vector2(-size.x, size.y), Vector2(uv1.x, uv1.y))
    })
 
    sprite:SetTexture(image)
    sprite:SetTopology(Topology.TriangleList)
 
    return sprite
end

Events:Subscribe("LocalPlayerChat", function(args)
    if args.text == "/a" then
        local ray = Physics:Raycast(Camera:GetPosition(), Camera:GetAngle() * Vector3.Forward, 0, 100)
        print(ray.position - Camera:GetAngle() * Vector3.Forward * 0.12)
        print(Angle.FromVectors(Vector3.Forward, ray.normal))
    end
    if args.text == "/pos" then
        print(LocalPlayer:GetPosition())
    end
end)

function cSafezoneSigns:CreateModels()

    for name, sign_data in pairs(self.signs) do

        sign_data.image:SetSize(sign_data.size)
        local model = self:CreateSprite(sign_data.image, sign_data.scale)
        self.signs[name].model = model
        Timer.Sleep(100)

    end
end

function cSafezoneSigns:SecondTick()

    if Safezone.near_safezone and not self.render then
        self.render = Events:Subscribe("GameRenderOpaque", self, self.GameRender)
    elseif not Safezone.near_safezone and self.render then
        Events:Unsubscribe(self.render)
        self.render = nil
    end

end

function cSafezoneSigns:GameRender(args)

    if not self.models_created then return end

    for name, sign_data in pairs(self.signs) do
        local t = Transform3():Translate(sign_data.position):Rotate(sign_data.angle)
        Render:SetTransform(t)
        sign_data.model:Draw()
        Render:ResetTransform()
    end

    for name, sign_data in pairs(self.stats) do
        local t = Transform3():Translate(sign_data.position):Rotate(sign_data.angle)
        Render:SetTransform(t)
        Render:DrawText(Vector3.Zero, string.format(sign_data.text, sign_data.value), sign_data.color, sign_data.fontsize, sign_data.scale)
        Render:ResetTransform()
    end

    collectgarbage()

end

cSafezoneSigns = cSafezoneSigns()