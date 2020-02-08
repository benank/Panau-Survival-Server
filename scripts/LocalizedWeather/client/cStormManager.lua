class 'cStormManager'

function cStormManager:__init()

	self.storms = {}

	Events:Subscribe("WorldNetworkObjectDestroy", self, self.WNODestroy)
	Events:Subscribe("WorldNetworkObjectCreate", self, self.WNOCreate)
	Events:Subscribe("GameRenderOpaque", self, self.GameRender)
	Events:Subscribe("ModuleUnload", self, self.Unload)
	
end

function cStormManager:Unload()

	for id, obj in pairs(self.storms) do
	
		self.storms[id]:Unload()
		
	end
	
end

function cStormManager:GameRender(args)

	for id, obj in pairs(self.storms) do
	
		self.storms[id]:GameRender(args)
			
	end
	
end

function cStormManager:WNODestroy(args)

	if (self.storms[args.object:GetId()]) then self.storms[args.object:GetId()]:Dissipate() end
	self.storms[args.object:GetId()] = nil

end

function cStormManager:WNOCreate(args)

	if args.object:GetValue("isStorm") and not self.storms[args.object:GetId()] then
	
		local storm = cStorm(args.object)
		self.storms[args.object:GetId()] = storm
		
	end
	
end

cStormManager = cStormManager()