class 'ModelViewer'
class 'OrbitCamera'

__model_viewer = nil
Events:Subscribe('ModuleLoad', function()
	__model_viewer = ModelViewer()
end)