class 'MyTestClass'

function MyTestClass:__init()
	self.sub = Events:Subscribe("PostTick", self, self.PostTick)
end

function MyTestClass:PostTick()
	print("POST TICKING")
end

Events:Subscribe("LocalPlayerChat", function(args)
	
	if args.text == "/class" then
		MyTestClass()
		
		return false
	end
	
end)

lines = 0
function line_counter()
	lines = lines + 1
	print("lines: ", lines)
end

--debug.sethook(line_counter, "l")

