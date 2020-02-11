IsTest = true
debug_enabled = IsTest and true
function debug(s)
	if not debug_enabled then return end
	if Server then
		Chat:Broadcast("[debug]: " .. tostring(s), Color.Red)
	elseif Client then
		Chat:Print("[debug]: " .. tostring(s), Color.Red)
	end
	print("[debug]:", tostring(s))
end