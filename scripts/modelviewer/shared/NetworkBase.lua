class "NetworkBase"

function NetworkBase:__init()
	self.events = {}
	self.NetworkSubscribe = NetworkBase.NetworkSubscribe
end

function NetworkBase:NetworkSubscribe( name )
	if not self[name] then
		error( "Could not find method " .. name .. " when subscribing to network event" )

		return
	end

	local event = Network:Subscribe( name, self, self[name] )
	table.insert( self.events, event )

	return event	
end

function NetworkBase:Shutdown()
	for k, v in pairs(self.events) do
		Network:Unsubscribe(v)
	end
end