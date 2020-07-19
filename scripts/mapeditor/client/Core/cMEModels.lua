MapEditor.models = {}

MapEditor.dashedLineStuff = {
	numLines = 10 ,
	spacingRatio = 0.333 ,
	color = Color.Orange ,
	timer = Timer() ,
	vertices = {} ,
}
MapEditor.models.dashedLine = Model.Create((MapEditor.dashedLineStuff.numLines + 1) * 2)
MapEditor.models.dashedLine:SetTopology(Topology.LineList)

Events:Subscribe("ModuleLoad" , function()
	local sources = {
		"Cursor" ,
		"Move gizmo" ,
		"Rotate gizmo" ,
	}
	for index , source in ipairs(sources) do
		local args = {
			path = "Models/"..source
		}
		OBJLoader.Request(args , function(model) MapEditor.models[source] = model end)
	end
end)

Events:Subscribe("Render" , function()
	local timerSeconds = MapEditor.dashedLineStuff.timer:GetSeconds()
	if timerSeconds >= 1 then
		MapEditor.dashedLineStuff.timer:Restart()
		timerSeconds = 0
	end
	
	local vertices = MapEditor.dashedLineStuff.vertices
	local increment = 1 / MapEditor.dashedLineStuff.numLines
	local currentPos = -increment + timerSeconds * increment
	local lineLength = increment * (1 - MapEditor.dashedLineStuff.spacingRatio)
	local a , b
	for n = 0 , MapEditor.dashedLineStuff.numLines do
		a = math.clamp(currentPos , 0 , 1)
		b = math.clamp(currentPos + lineLength , 0 , 1)
		vertices[n * 2 + 1] = Vertex(Vector3(0 , 0 , -a) , MapEditor.dashedLineStuff.color)
		vertices[n * 2 + 2] = Vertex(Vector3(0 , 0 , -b) , MapEditor.dashedLineStuff.color)
		currentPos = currentPos + increment
	end
	
	MapEditor.models.dashedLine:Update(vertices)
end)
