if Server then
	local run = require('luv').run
	local poll = function() return run('nowait') end
	Events:Subscribe('PreTick', poll)
	Events:Subscribe('PostTick', poll)
end
