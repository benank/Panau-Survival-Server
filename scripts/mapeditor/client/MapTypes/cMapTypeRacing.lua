MapTypes.Racing = {
	objects = {
		"RaceCheckpoint" ,
		"RaceRespawnPoint" ,
		"RaceSpawn" ,
		"RaceVehicleInfo" ,
	} ,
	properties = {
		{
			name = "title" ,
			type = "string" ,
			default = "Untitled Course" ,
			description = "This is how your course name will be displayed to users." ,
		} ,
		{
			name = "authors" ,
			type = "table" ,
			subtype = "string" ,
			description = "Don't forget to put your name here if you want people to know who made "..
				"the course." ,
		} ,
		{
			name = "firstCheckpoint" ,
			type = "RaceCheckpoint" ,
			description = "If your course is a circuit, you need to set this." ,
		} ,
		{
			name = "laps" ,
			type = "number" ,
			default = 1 ,
			description = "If your course is a circuit, this is a suggestion of the number of laps; "..
				"it scales a little with the number of players (percent of starting slots filled, "..
				"to be specific)." ,
		} ,
		{
			name = "minStartHour" ,
			type = "number" ,
			default = 8 ,
			description = "These two values form the range of the time of day that the race can "..
				"start at. Using a min of 22 and a max of 5 works for night time. If your race can "..
				"start at night, make sure people can see where they're going." ,
		} ,
		{
			name = "maxStartHour" ,
			type = "number" ,
			default = 16 ,
			description = "These two values form the range of the time of day that the race can "..
				"start at. Using a min of 22 and a max of 5 works for night time. If your race can "..
				"start at night, make sure people can see where they're going." ,
		} ,
		{
			name = "weatherSeverity" ,
			type = "number" ,
			default = -1 ,
			description = "Values are between 0 and 2 (see the JC2-MP wiki on weather). -1 is "..
				"random, but prefers clear weather." ,
		} ,
		{
			name = "parachuteEnabled" ,
			type = "boolean" ,
			default = true ,
			description = "If the parachute is disabled, players won't be able to use it." ,
		} ,
		{
			name = "grappleEnabled" ,
			type = "boolean" ,
			default = true ,
			description = "If the grapple is disabled, players won't be able to use it." ,
		} ,
		{
			name = "forceCollision" ,
			type = "number" ,
			default = 0 ,
			description = "Suggestion to the race manager to force vehicle collision on or off. 0 "..
				"is no suggestion, 1 is force on, 2 is no collision. [This needs a drop-down box]" ,
		} ,
		{
			name = "allowFirstLapRecord" ,
			type = "boolean" ,
			default = true ,
			description = "If your course is a circuit, it's possible that the first lap can be "..
				"faster than all the others. In that case, set this to false, or else some people "..
				"will be mildly angry at you." ,
		} ,
	} ,
	Validate = function(map)
		-- Validate spawns. Make sure all spawns have at least one valid RaceVehicleInfo.
		
		local hasSpawn = false
		local errorString = nil
		map:IterateObjects(function(object)
			if object.type == "RaceSpawn" then
				hasSpawn = true
				
				local vehicleInfos = object:GetProperty("vehicles").value
				
				if #vehicleInfos == 0 then
					errorString = "RaceSpawn needs at least one RaceVehicleInfo"
					return
				end
				
				for index , vehicleInfo in ipairs(vehicleInfos) do
					if vehicleInfo == MapEditor.NoObject then
						errorString = "RaceSpawn vehicle element is empty (index "..tostring(index)..")"
						return
					end
				end
			end
		end)
		
		if errorString then
			return errorString
		end
		
		if hasSpawn == false then
			return "At least one RaceSpawn is required"
		end
		
		-- Validate checkpoints. Make sure it forms a line or a circuit and that there are no stranded
		-- checkpoints.
		
		-- Create a linked list of checkpoints.
		-- Values are like, {previous = table , checkpoint = RaceCheckpoint , next = table}
		local checkpointList = {}
		map:IterateObjects(function(object)
			if object.type == "RaceCheckpoint" then
				table.insert(checkpointList , {checkpoint = object})
			end
		end)
		for index , listItem in ipairs(checkpointList) do
			local nextCheckpoint = listItem.checkpoint:GetProperty("nextCheckpoint").value
			if nextCheckpoint ~= MapEditor.NoObject then
				for index2 , listItem2 in ipairs(checkpointList) do
					if listItem2.checkpoint:GetId() == nextCheckpoint:GetId() then
						listItem.next = listItem2
						listItem2.previous = listItem
					end
				end
			end
		end
		-- Make sure there is at least one checkpoint.
		if #checkpointList == 0 then
			return "At least one checkpoint is required"
		end
		-- Make sure each next checkpoint isn't the checkpoint itself.
		for index , listItem in ipairs(checkpointList) do
			if listItem.next then
				local nextCheckpoint = listItem.next.checkpoint
				if nextCheckpoint:GetId() == listItem.checkpoint:GetId() then
					return "Invalid checkpoint; Next Checkpoint cannot be the checkpoint itself, you git!"
				end
			end
		end
		-- Find the first checkpoint.
		local startingCheckpoint = checkpointList[1]
		local isCircuit = false
		while true do
			startingCheckpoint.beenTo = true
			
			if startingCheckpoint.previous then
				startingCheckpoint = startingCheckpoint.previous
				-- Prevent an infinite loop in case it's a circuit.
				if startingCheckpoint.beenTo then
					isCircuit = true
					break
				end
			else
				break
			end
		end
		-- Translate checkpointList into checkpoints array.
		local checkpoints = {}
		local cp = startingCheckpoint
		repeat
			for index , checkpoint in ipairs(checkpoints) do
				if checkpoint:GetId() == cp.checkpoint:GetId() then
					return "Invalid checkpoint; Are two checkpoints connected to each other?"
				end
			end
			table.insert(checkpoints , cp.checkpoint)
			cp = cp.next
		until cp == nil or cp == startingCheckpoint
		-- Make sure all checkpoints are accounted for.
		if #checkpoints ~= #checkpointList then
			return "Invalid checkpoint; Same Next Checkpoint or stranded checkpoint"
		end
		-- If this is a circuit, make sure we have firstCheckpoint.
		if isCircuit and map:GetProperty("firstCheckpoint").value == MapEditor.NoObject then
			return "Course is a circuit but First Checkpoint is not set in map properties"
		end
		
		return true
	end ,
	Test = function()
		MapTypes.Racing.raceEndSub = Events:Subscribe("RaceEnd" , function()
			Events:Unsubscribe(MapTypes.Racing.raceEndSub)
			
			MapEditor.map:SetEnabled(true)
		end)
	end
}
