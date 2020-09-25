IsTest = false
function _debug(s)
	if not IsTest then return end
	if Server then
		Chat:Broadcast("[debug]: " .. tostring(s), Color.Red)
	elseif Client then
		Chat:Print("[debug]: " .. tostring(s), Color.Red)
	end
	print("[debug]:", tostring(s))
end