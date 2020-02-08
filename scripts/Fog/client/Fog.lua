class 'Fog'
function Fog:__init()
	layersBlack = 50 --number of layers
	distBlack = 1 --dist of first layer
	layerDistBlack = 1 --increase for closer layers (smoother but faster transition)
	alphaBlack = 30
	
	layersWhite = 40 --number of layers
	distWhite = 0.75 --dist of first layer
	layerDistWhite = 0.5 --increase for closer layers (smoother but faster transition)
	alphaWhite = 10
	
	layersCustom = 100 --number of layers
	distCustom = 1 --dist of first layer
	layerDistCustom = 1 --increase for closer layers (smoother but faster transition)
	colorCustom = Color(212,166,106,10)
	
	whiteFogEnabled = false
	blackFogEnabled = true
	customFogEnabled = false
	if blackFogEnabled or whiteFogEnabled or customFogEnabled then
		Events:Subscribe("GameRender", self, self.Rend)
	end
		--Events:Subscribe("GameRender", self, self.Rend2)
end
function Fog:Rend()
	if whiteFogEnabled then
		for i=1, layersWhite do
			RenderWhiteFog(i)
		end
	end
	if blackFogEnabled then
		for i=1, layersBlack do
			RenderBlackFog(i)
		end
	end
	if customFogEnabled then
		for i=1, layersCustom do
			RenderCustomFog(i)
		end
	end
end
function Fog:Rend2()
		for i=1, layersBlack do
			RenderBlackFog(i)
		end
end
function RenderWhiteFog(i)
	local mult = ((layersWhite - i)/layerDistWhite) + distWhite
	local p1 = Camera:GetPosition() + (Camera:GetAngle() * (Vector3.Forward * mult))
	t = Transform3()
	t:Translate(p1)
	t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
	Render:SetTransform(t)
	local color = Color(255,255,255,alphaWhite)
	Render:FillArea(Vector3(0,0,0), Vector3(1000,1000,1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(-1000,-1000,-1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(1000,-1000,-1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(-1000,1000,1000), color)
	Render:ResetTransform()
end
function RenderBlackFog(i)
	local mult = ((layersBlack - i)/layerDistBlack) + distBlack
	local p1 = Camera:GetPosition() + (Camera:GetAngle() * (Vector3.Forward * mult))
	t = Transform3()
	t:Translate(p1)
	t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
	Render:SetTransform(t)
	local color = Color(0,0,0,alphaBlack)
	Render:FillArea(Vector3(0,0,0), Vector3(1000,1000,1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(-1000,-1000,-1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(1000,-1000,-1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(-1000,1000,1000), color)
	Render:ResetTransform()
end
function RenderCustomFog(i)
	local mult = ((layersCustom - i)/layerDistCustom) + distCustom
	local p1 = Camera:GetPosition() + (Camera:GetAngle() * (Vector3.Forward * mult))
	t = Transform3()
	t:Translate(p1)
	t:Rotate(Camera:GetAngle() * Angle(math.pi,0,math.pi))
	Render:SetTransform(t)
	local color = colorCustom
	Render:FillArea(Vector3(0,0,0), Vector3(1000,1000,1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(-1000,-1000,-1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(1000,-1000,-1000), color)
	Render:FillArea(Vector3(0,0,0), Vector3(-1000,1000,1000), color)
	Render:ResetTransform()
end
--Fog = Fog()