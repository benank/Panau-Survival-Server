local DrawRoad = Helpers.DrawRoad

local function DrawConnectedEdges(vertexIndex, color)
    local connectedRoads = Roads:GetConnectedEdges(vertexIndex)
    
    for _, connectedEdge in pairs(connectedRoads) do
        if connectedEdge.id ~= vertexIndex then
            local connectedRoad = Roads:GetRoadById(connectedEdge.id)
            
            if connectedRoad then
                DrawRoad(connectedRoad, color)
            end
        end
    end
end

local function DrawNearestRoad()
    -- Get the nearest Edge to the Camera position
    local current_edge = Roads:GetEdgeByPosition(Camera:GetPosition(), 500)
    
    if current_edge then
        local road = Roads:GetRoadById(current_edge.id)
        
        -- If the associated Road object is streamed in, render the connected Edges
        if road then
            DrawConnectedEdges(current_edge.vertices[1].id, Color.Red)
            DrawConnectedEdges(current_edge.vertices[2].id, Color.Blue)
        end
    end
end

local function FindRoadPath()
    Roads:FindRoadPath(
        Vector3(-6873.57, 241.75, -9364.9),
        Vector3(-12280.43, 226.22, -5061.12),
        function(args)
            if not args.success then
                Chat:Print("Failed to find road path", Color.Red)
                return 
            end
            
            Events:Subscribe(
                "Render",
                function()
                    for i, v in ipairs(args.edges) do
                        local color = Color.FromHSV((i - 1) / #args.edges * 360, 0.7, 1.0)
                        
                        local road = Roads:GetRoadById(v.id)
                        -- If the Road game object is streamed in, render the spline in high detail,
                        -- otherwise, we'll settle for basic point-to-point lines.
                        if road then
                            DrawRoad(road, color)
                        else
                            Render:DrawLine(v.vertices[1].position, v.vertices[2].position, color)
                        end
                    end
                end
            )
        end
    )
end

local function OnModuleLoad()
    Events:Subscribe('Render', DrawNearestRoad)
    
    FindRoadPath()
end

Events:Subscribe('ModuleLoad', OnModuleLoad)
