Console:Subscribe("loadoldcourse" , function(args)
	local courseName = args.text
	if courseName:len() == 0 then
		warn("Please provide a course name, such as: My Excellent Course")
		return
	end
	
	Network:Send("RequestOldCourse" , courseName)
end)

Network:Subscribe("ReceiveOldCourse" , function(args)
	local courseName = args.courseName
	local oldCourse = args.marshalledCourse
	
	print("Loading old course: "..courseName)
	
	if MapEditor.map then
		MapEditor.map:Destroy()
	end
	
	local p1 = oldCourse.checkpoints[1].position
	local initialPosition = Vector3(p1.x , p1.y , p1.z) + Vector3(0 , 30 , 0)
	MapEditor.Map(initialPosition , "Racing")
	
	-- Used when a checkpoint's validVehicles has 0 elements, which, in the old format, meant that
	-- any vehicle other than on-foot would work.
	local modelIdsUsed = {}
	
	MapEditor.map:SetProperty("laps" , oldCourse.numLaps)
	MapEditor.map:SetProperty("title" , oldCourse.name)
	MapEditor.map:SetProperty("authors" , oldCourse.authors)
	MapEditor.map:SetProperty("weatherSeverity" , oldCourse.weatherSeverity)
	
	for index , spawn in ipairs(oldCourse.spawns) do
		local position = Vector3(spawn.position.x , spawn.position.y , spawn.position.z)
		local angle = Angle(spawn.angle.x , spawn.angle.y , spawn.angle.z , spawn.angle.w)
		local spawnObject = Objects.RaceSpawn(position , angle)
		MapEditor.map:AddObject(spawnObject)
		
		local modelIdToTemplates = {}
		for index , modelId in ipairs(spawn.modelIds) do
			if modelIdToTemplates[modelId] == nil then
				modelIdToTemplates[modelId] = {spawn.templates[index]}
			else
				table.insert(modelIdToTemplates[modelId] , spawn.templates[index])
			end
		end
		
		local vehicleInfoObjects = {}
		for index , modelId in ipairs(spawn.modelIds) do
			local identicalVehicleInfo = nil
			MapEditor.map:IterateObjects(function(object)
				if identicalVehicleInfo ~= nil or object.type ~= "RaceVehicleInfo" then
					return
				end
				
				if object:GetProperty("modelId").value ~= modelId then
					return
				end
				
				local templates1 = object:GetProperty("templates").value
				local templates2 = modelIdToTemplates[modelId]
				if #templates1 ~= #templates2 then
					return
				end
				for index , template in ipairs(templates1) do
					if template ~= templates2[index] then
						return
					end
				end
				
				identicalVehicleInfo = object
			end)
			
			if identicalVehicleInfo then
				table.insert(vehicleInfoObjects , identicalVehicleInfo)
			else
				local position = spawnObject:GetPosition() + Vector3(0 , 4 , 0)
				local vehicleInfoObject = Objects.RaceVehicleInfo(position)
				MapEditor.map:AddObject(vehicleInfoObject)
				table.insert(vehicleInfoObjects , vehicleInfoObject)
				vehicleInfoObject:SetProperty("modelId" , modelId)
				vehicleInfoObject:SetProperty("templates" , modelIdToTemplates[modelId])
			end
			
			if table.find(modelIdsUsed , modelId) == nil then
				table.insert(modelIdsUsed , modelId)
			end
		end
		spawnObject:SetProperty("vehicles" , vehicleInfoObjects)
	end
	
	local previousObject = nil
	for index , cp in ipairs(oldCourse.checkpoints) do
		local position = Vector3(cp.position.x , cp.position.y , cp.position.z)
		local object = Objects.RaceCheckpoint(position)
		MapEditor.map:AddObject(object)
		if index == 1 then
			MapEditor.map:SetProperty("firstCheckpoint" , object)
		else
			previousObject:SetProperty("nextCheckpoint" , object)
		end
		
		if #cp.validVehicles == 0 then
			object:SetProperty("validVehicles" , modelIdsUsed)
		else
			object:SetProperty("validVehicles" , cp.validVehicles)
		end
		
		previousObject = object
	end
end)

Network:Subscribe("ReceiveOldCourseError" , function(args)
	warn("Cannot load old course: "..args.courseName..", "..args.errorMessage)
	warn("Make sure the course is in oldcourses/")
end)
