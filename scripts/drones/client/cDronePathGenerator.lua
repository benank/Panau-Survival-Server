class 'cDronePathGenerator'

function cDronePathGenerator:__init()

    self.height = 30 -- Drone height above the path

end

function cDronePathGenerator:GetRandomRoadOffset(road)
    return Vector3(
            road.radius - math.random() * road.radius * 2, 
            self.height + math.random() * 100,
            road.radius - math.random() * road.radius * 2)
end

function cDronePathGenerator:GeneratePathNearPoint(origin, radius, callback)

    _debug("GENERATING PATH...")

    local start_pos = origin--self:GetRandomPointWithinRadius(origin, radius)
    local end_pos = self:GetRandomPointWithinRadius(origin, radius)

    Roads:FindRoadPath(
        start_pos,
        end_pos,
        function(args)

            if not args.success or count_table(args.edges) == 0 then
                _debug("Failed to find road path, retrying")
                Thread(function()
                    Timer.Sleep(1000)
                    self:GeneratePathNearPoint(origin, radius, callback)
                end)
                return
            end

            _debug("GOT RESPONSE, GOING THROUGH EDGES")

            local path = {}

            Thread(function()
                for i,v in ipairs(args.edges) do
                    
                    local road = Roads:GetRoadById(v.id)

                    if road then

                        local road_offset = self:GetRandomRoadOffset(road)

                        for _, spline_data in ipairs(road.spline) do
                            table.insert(path, spline_data.position + road_offset)
                        end

                    else

                        table.insert(path, v.vertices[1].position + self.height)
                        table.insert(path, v.vertices[2].position + self.height)

                    end

                end

                _debug("PATH FINISHED GENERATING")

                --output_table(path)

                -- Found road edges, return them
                callback(path)

            end)

        end
    )

end

function cDronePathGenerator:GetRandomPointWithinRadius(origin, radius)
    return origin + Vector3(0.5 - math.random(), 0, 0.5 - math.random()) * radius * math.random()
end

cDronePathGenerator = cDronePathGenerator()