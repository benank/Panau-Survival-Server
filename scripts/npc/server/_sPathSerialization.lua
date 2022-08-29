class "PathSerialization"

function PathSerialization:__init()
    self.directory_name = "paths"
end

function PathSerialization:GetPathDataFromFile(name, return_raw_contents)
    local filename = self.directory_name .. "/" .. name .. ".json"

    local file = io.open(filename, "r")
    
	if file ~= nil then -- file might not exist
        local contents = file:read("*all")
        file:close()

        if return_raw_contents then
            return contents
        else
            local path_json_table = json.decode(contents)
            return path_json_table
            --output_table(base_json_table)
        end
	else
        print("Path " .. name .. " does not exist!")
        return nil
	end
end

function PathSerialization:GetFullyLoadedPathFromFile(name)
    local path_data = self:GetPathDataFromFile(name)
    if not path_data then
        print("Path " .. name .. " does not exist!")
        return nil
    end

    local path = Path()
    path:InitializeFromJsonData(path_data)

    return path
end

function PathSerialization:SavePath(path)
    local filename = self.directory_name .. "/" .. path:GetName() .. ".json"
    local path_data = path:GetJsonCompatibleData()

    local encoded_data = json.encode(path_data)

    local file = io.open(filename, "w")
    if file then
        file:write(encoded_data)
        file:close()
        print("Saved " .. path:GetName())
    else
        print("Opening file failed when saving path")
    end
end

PathSerialization = PathSerialization()