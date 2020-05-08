function FormatError(e, source)
    local str = string.format("[%s] Error occurred in the module %s\n%s", tostring(source), tostring(e.module), tostring(e.error))
	for k, v in pairs(e.args) do
        str = str .. "\n" .. tostring(k) .. " " .. tostring(v)
    end
    return str
end