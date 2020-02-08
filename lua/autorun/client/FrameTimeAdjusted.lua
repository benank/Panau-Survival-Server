local frame_time = .025
local total_frame_time = 0
local avg_frame_time = .016
local frames = 0
local average_timer = Timer()

function UpdateFrameTime()
	frames = frames + 1
	local new_frame_time = Client:GetFrameTime()
	total_frame_time = total_frame_time + new_frame_time
	
	if average_timer:GetMilliseconds() > 250 then
		avg_frame_time = total_frame_time / frames
		average_timer:Restart()
	end
	
	if new_frame_time > avg_frame_time * 1.2 or avg_frame_time * .8 then
		frame_time = avg_frame_time
	else
		frame_time = new_frame_time
	end
end
Events:Subscribe("Render", UpdateFrameTime)

function FrameTimeAdjusted(number)
	if number ~= 0 then
		return number / (1 / frame_time / 60)
	else
		return 0
	end
end