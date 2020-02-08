function randy(_min, _max, _seed)
	math.randomseed(_seed)
	return math.random(_min, _max)
end

function rando(seed)
	math.randomseed(seed)
	return math.random()
end