local logo = Image.Create(AssetLocation.Resource, "Logo_IMG")
logo:SetAlpha(0.25)

local margin = 20

local size = Vector2(Render.Size.y, Render.Size.y) * 0.05
local basepos = Vector2(margin, Render.Size.y - margin - size.y)

local imagePanel = ImagePanel.Create()
imagePanel:SetPosition(basepos)
imagePanel:SetSize(size)
imagePanel:SetImage(logo)
imagePanel:SendToBack()