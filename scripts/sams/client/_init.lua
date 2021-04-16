Angle.Delta = function(q1, q2)
	return ((math.acos(math.min(math.abs(q1:Dot(q2)), 1)) * 2))
end

Angle.NormalisedDir = function(a1, a2)
	return (a1 - a2):Normalized()
end

Angle.RotateToward = function(q1, q2, max_ang)
	local num = Angle.Delta(q1, q2)
	if num == 0 then
		return q2
	end

	t = math.min(1, (max_ang / num))

	return Angle.Slerp(q1, q2, t)
end

coroutine.wait = function(ms)
	local t = Timer()
	while t:GetMilliseconds() < ms do
		coroutine.yield()
	end
end

class 'Entity'
class 'Missile'

Events:Subscribe('ModuleLoad', function()
	EntityManager = EntityManager()
end)