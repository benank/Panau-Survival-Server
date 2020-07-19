Objects = {}
Actions = {}
MapTypes = {}
Icons = {}
ModelViewerTabs = {}

-- Having properties that are Object be nil is bad for tables.
MapEditor.NoObject = {}
setmetatable(MapEditor.NoObject , {__tostring = function() return "No Object" end})

MapEditor.IsObjectType = function(type)
	return type == "Object" or Objects[type] ~= nil
end

Events:Subscribe("ModuleLoad" , function()
	Controls.Add("Select" ,                      "Mouse1")
	Controls.Add("Deselect" ,                    "Mouse2")
	Controls.Add("Add to selection" ,            "Shift")
	Controls.Add("Done" ,                        "Mouse1")
	Controls.Add("Cancel" ,                      "Mouse2")
	
	Controls.Add("Snap to surface" ,             "Shift")
	
	Controls.Add("Orbit camera: Rotate/pan" ,    "Mouse3")
	Controls.Add("Orbit camera: Pan modifier" ,  "Shift")
	
	Controls.Add("Noclip camera: Forward" ,      "MoveForward")
	Controls.Add("Noclip camera: Back" ,         "MoveBackward")
	Controls.Add("Noclip camera: Left" ,         "MoveLeft")
	Controls.Add("Noclip camera: Right" ,        "MoveRight")
	
	Controls.Add("Look up" ,                     "Mouse up")
	Controls.Add("Look down" ,                   "Mouse down")
	Controls.Add("Look left" ,                   "Mouse left")
	Controls.Add("Look right" ,                  "Mouse right")
	
	Controls.Add("Mouse wheel up" ,              "Mouse wheel up")
	Controls.Add("Mouse wheel down" ,            "Mouse wheel down")
	
	MapEditor.iconModel = Model.Create{
		Vertex(Vector3(-1 , 0 , 1) , Vector2(0 , 0)) ,
		Vertex(Vector3(1 , 0 , 1) , Vector2(1 , 0)) ,
		Vertex(Vector3(-1 , 0 , -1) , Vector2(0 , 1)) ,
		Vertex(Vector3(1 , 0 , -1) , Vector2(1 , 1)) ,
	}
	MapEditor.iconModel:SetTopology(Topology.TriangleStrip)
	
	MapEditor.MapMenu()
	MapEditor.PreferencesMenu()
	MapEditor.ModelViewer()
	MapEditor.MaplessState()
end)

Events:Subscribe("ModuleUnload" , function()
	MapEditor.modelViewer:Destroy()
	if MapEditor.map then
		MapEditor.map:Destroy()
	end
end)
