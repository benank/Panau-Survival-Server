class "DirectoryUtils"

function DirectoryUtils:__init()
    self.temp_name_counter = 0
end

-- only filenames containing the 'contains' argument string will be returned. can be nil for no filtering
-- might only work with class instance functions as callback
function DirectoryUtils:GetFilesInDirectory(directory, contains, caller, callback)
    Thread(function()
        local filter_string = contains
        if not filter_string then filter_string = "" end
        self.temp_name_counter = self.temp_name_counter + 1
        local temp_filename = tostring(self.temp_name_counter) .. ".txt"
        os.execute("ls " .. directory .. " > " .. temp_filename)

        Timer.Sleep(1000)

        local files = {}
        for line in io.lines("../../" .. temp_filename) do
            if line != nil and line:find(filter_string) then
                table.insert(files, line)
            end
        end

        os.remove(temp_filename)
        callback(caller, files)
    end)
end

DirectoryUtils = DirectoryUtils()