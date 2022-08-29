if Server then
	PATHSERVER_LOADED = true
	
	local uv = require('luv')
	local json = require('json')

	local now = uv.now
	local unpack = table.unpack
	local encode, decode = json.encode, json.decode
	local assert, error, ipairs = assert, error, ipairs
	local Vector3, SetUnicode = Vector3, SetUnicode

	class 'PathServer'

	function PathServer:__init()
		getter_setter(self, "ready")
		getter_setter(self, "aggregation_timer")
		getter_setter(self, "aggregation_delay") -- how long to wait until we send the request once we get at least 1 request in the queue
		self.ready = false
		self.waiting = false
		self.aggregation_timer = Timer()

		self.pool = 0
		self.queue = Deque()
		self.callbacks = {}
	end

	function PathServer:connect(host, port)
		local udp = uv.new_udp()
		local idle = uv.new_idle()
		local queue = self.queue
		local callbacks = self.callbacks
		
		udp:recv_start(function(err, data, sender)
			if sender and data then
				self:handleResponse(data)
			end
		end)

		idle:start(function() -- called every JCMP server tick
			if self.ready and self.queue:getCount() > 0 and self.aggregation_timer:GetMilliseconds() > self.aggregation_delay then
				local data
				local requests_data = {}
				while self.queue:getCount() > 0 do
					data = self.queue:popLeft()
					data.time = nil
					table.insert(requests_data, data)
				end
				self:sendRequest(requests_data)
			end
		end)

		self.udp = udp
		self.host = host
		self.port = port

		self:sendRequest({method = 'handshake'})

	end

	function PathServer:GetFootPath(start, stop, callback, callback_instance)
		self:prepareRequest('getPath', {
			start = {start.x, start.y, start.z},
			stop = {stop.x, stop.y, stop.z},
		}, callback, callback_instance)
	end

	function PathServer:GetRoamPath(start, callback, callback_instance)
		self:prepareRequest('getRoamPath', {
			start = {start.x, start.y, start.z},
		}, callback, callback_instance)
	end

	function PathServer:getNearestNode(position, callback)
		self:prepareRequest('getNearestNode', {
			position = {position.x, position.y, position.z}
		}, callback)
	end
	
	function PathServer:GetRandomNodePositionInNearbyCell(position, callback)
		self:prepareRequest('GetRandomNodePositionInNearbyCell', {
			position = {position.x, position.y, position.z}
		}, callback)
	end
	
	function PathServer:GetSkyPath(start, stop, callback)
		self:prepareRequest('GetSkyPath', {
			start = {start.x, start.y, start.z},
			stop = {stop.x, stop.y, stop.z},
		}, callback)
	end

	function PathServer:prepareRequest(method, data, callback, callback_instance)

		local id = self.pool
		self.callbacks[id] = {func = callback, instance = callback_instance}
		self.pool = id + 1

		data.id = id
		data.method = method
		data.time = now()
		self.queue:pushRight(data)

		if self.queue:getCount() == 1 then
			self.aggregation_timer:Restart()
		end

	end

	function PathServer:sendRequest(data)
		--print("Sending to path server:")
		--output_table(data)
		self.ready = false
		self.udp:send(encode(data), self.host, self.port)
	end

	function PathServer:handleResponse(data)
		self.ready = true
		data = decode(data)

		--print("Data returned by pathserver:")
		--output_table(data)

		for _, request_data in ipairs(data) do
			self:handleRequestResponse(request_data)
		end
	end

	function PathServer:handleRequestResponse(data)

		local id = data.id
		if not id then return end
		data.id = nil

		if data.method == 'getPath' then
			local path = data.path
			if path then
				for i, v in ipairs(path) do
					path[i] = Vector3(unpack(v))
				end
			end
		elseif data.method == 'getRoamPath' then
			local path = data.path
			if path then
				for i, v in ipairs(path) do
					path[i] = Vector3(unpack(v))
				end
			end
		elseif data.method == 'getNearestNode' then
			local position = data.position
			data.position = Vector3(unpack(position))
		elseif data.method == 'GetRandomNodePositionInNearbyCell' then
			local position = data.position
			if position then
				data.position = Vector3(unpack(position))
			end
		end
		data.method = nil

		local callback = self.callbacks[id]
		if not callback or not callback.func then return end
		self.callbacks[id] = nil

		callback.func(callback.instance, data)
	end
end
