class "BaseSerialization"

function BaseSerialization:__init()
    self.directory_name = "bases"
end

function BaseSerialization:GetBaseDataFromFile(name)
    local filename = self.directory_name .. "/" .. name .. ".json"
    local file = io.open(filename, "r")
    
	if file ~= nil then -- file might not exist
        local contents = file:read("*all")
        file:close()

        local base_json_table = json.decode(contents)
        return base_json_table
	else
        print("Base " .. name .. " does not exist!")
        return nil
	end
end

function BaseSerialization:GetFullyLoadedBaseFromFile(name)
    local base_data = self:GetBaseDataFromFile(name)
    if not base_data then
        print("Base " .. name .. " does not exist!")
        return nil
    end

    local base = Base()
    base:InitializeFromJsonData(base_data)

    return base
end

function BaseSerialization:SaveBase(base)
    local filename = self.directory_name .. "/" .. base:GetName() .. ".json"
    local base_data = base:GetJsonCompatibleData()

    local encoded_data = json.encode(base_data)

    local file = io.open(filename, "w")
    if file then
        file:write(encoded_data)
        file:close()
        print("Saved " .. base:GetName())
    else
        print("Opening file failed when Saving Base")
    end
end

BaseSerialization = BaseSerialization()