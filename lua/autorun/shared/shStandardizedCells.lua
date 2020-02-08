function GetCell(x, y, size)
	if size then
		return math.floor((x + 16384) / size), math.floor((y + 16384) / size)
	else
		return math.floor((x + 16384) / size), math.floor((y + 16384) / 256) -- 256 is default cell size
	end
end