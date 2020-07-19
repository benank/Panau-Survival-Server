Network:Subscribe("RequestOldCourse" , function(courseName , player)
	courseName = courseName:gsub(".course" , "")
	
	local path = "oldcourses/"..courseName..".course"
	local file , openError = io.open(path , "r")
	
	if openError then
		local args = {
			courseName = courseName ,
			errorMessage = openError ,
		}
		Network:Send(player , "ReceiveOldCourseError" , args)
		return
	end
	
	local jsonString = file:read("*a")
	
	file:close()
	
	local marshalledCourse = JSON:decode(jsonString)
	
	local args = {
		courseName = courseName ,
		marshalledCourse = marshalledCourse ,
	}
	Network:Send(player , "ReceiveOldCourse" , args)
end)
