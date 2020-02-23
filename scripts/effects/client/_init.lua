class 'effectBrowser'
class 'OrbitCamera'

__effectBrowser = nil
Events:Subscribe('ModuleLoad', function()
	__effectBrowser = effectBrowser()
end)