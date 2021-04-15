
--	Utility Functions	--

function Immune(player)
	if player:GetValue("GodMode")
	or player:GetValue("MissionImmunity")
	or player:GetValue("AFKPassive")
	then
		return true
	else
		return false
	end
end

function IsValidVehicle(vehicleID, vehicleTable)
	for k, v in ipairs(vehicleTable) do
		if v	==	vehicleID then
			return true
		end
	end
	return false
end

function Round(val, decimal)
  local exp = decimal and 10^decimal or 1
  return math.ceil(val * exp - 0.5) / exp
end

function Commas(num)
  assert (type (num) == "number" or
          type (num) == "string")
  
  local result = ""
  local sign, before, after =
    string.match (tostring (num), "^([%+%-]?)(%d*)(%.?.*)$")
  while string.len (before) > 3 do
    result = "," .. string.sub (before, -3, -1) .. result
    before = string.sub (before, 1, -4)  -- remove last 3 digits
  end
  return sign .. before .. result .. after
end
