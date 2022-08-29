Console:Subscribe("testpath", function(args)
    if args.command == "testpath" then
        local path = PathSerialization:GetFullyLoadedPathFromFile("sp1_path")

        local path_navigation = PathNavigation()
        path_navigation:SetPath(path)
        path_navigation:SetSpeedMultiplier(2.0)
        path_navigation:StartPath()

        local path_position_check_thread = Thread(function()
            for i = 1, 50 do
                Timer.Sleep(100)
                local path_position = path_navigation:GetPosition()
                Console:Print(tostring(path_position), Color.Red)
            end
        end)
    end
end)