class 'cLootmap'

function cLootmap:__init()

    self.open_key = VirtualKey.F2

    self.image = Image.Create(AssetLocation.Resource, "lootmap")
    self.image:SetSize(Vector2(1000, 1000))

    self.image_panel = ImagePanel.Create()
    self.image_panel:SetImage(self.image)
    self:ResizeImage()
    self.image_panel:Hide()

    Events:Subscribe("KeyUp", self, self.KeyUp)
    Events:Subscribe("ResolutionChange", self, self.ResolutionChange)
end

function cLootmap:ResolutionChange()
    self.ResizeImage()
end

function cLootmap:KeyUp(args)
    if args.key == self.open_key then
        if self.image_panel:GetVisible() then
            self.image_panel:Hide()
        else
            self.image_panel:Show()
        end
    end
end

function cLootmap:ResizeImage()
    self.image_panel:SetSize(Vector2(Render.Size.y * 0.9, Render.Size.y * 0.9))
    self.image_panel:SetPosition(Render.Size / 2 - self.image_panel:GetSize() / 2)
end

cLootmap = cLootmap()