class 'ModelViewer'

__model_viewer = nil
Events:Subscribe('ModuleLoad', function()
	__model_viewer = ModelViewer()
end)