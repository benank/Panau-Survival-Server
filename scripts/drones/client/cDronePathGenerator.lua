class 'cDronePathGenerator'

function cDronePathGenerator:__init()

    self.height = 2 -- Drone height above the path
    self.height_range = 10
    self.MAX_RETRIES = 5

end

function cDronePathGenerator:GetRandomRoadOffset(road)
    local radius = road.radius / 2
    return Vector3(
        radius - math.random() * radius * 2, 
        self.height + math.random() * self.height_range,
        radius - math.random() * radius * 2)
end

function cDronePathGenerator:GeneratePathNearPoint(origin, tether_position, radius, callback, retries)

    --_debug("GENERATING PATH...")

    local retries = retries or 0
    local start_pos = origin
    local end_pos = self:GetRandomPointWithinRadius(tether_position, radius)

    Roads:FindRoadPath(
        start_pos,
        end_pos,
        function(args)

            if not args.success or count_table(args.edges) == 0 then
                --_debug(string.format("Failed to find road path, retrying (%d)", retries))
                Thread(function()
                    Timer.Sleep(1000)
                    retries = retries + 1
                    if retries >= self.MAX_RETRIES then -- Failed to find path within max tries
                        callback()
                        return
                    end
                    self:GeneratePathNearPoint(origin, tether_position, radius, callback, retries)
                end)
                return
            end

            --_debug("GOT RESPONSE, GOING THROUGH EDGES")

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

                --_debug("PATH FINISHED GENERATING " .. tostring(retries))

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