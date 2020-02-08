-- http://ftp.nsysu.edu.tw/FreeBSD/ports/local-distfiles/philip/filename.lua%3Frev=1.2
FileName = 
{
	basename = function(path, dirsep)
		local i = string.len(path)

		while string.sub(path, i, i) == dirsep and i > 0 do
			path = string.sub(path, 1, i - 1)
			i = i - 1
		end
		while i > 0 do
			if string.sub(path, i, i) == dirsep then
				break
			end
			i = i - 1
		end
		if i > 0 then
			path = string.sub(path, i + 1, -1)
		end
		if path == "" then
			path = dirsep
		end

		return path
	end
}