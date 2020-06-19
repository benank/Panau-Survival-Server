class 'CardinalSpline'

function CardinalSpline:__init(spline)
    self.spline = spline
end

function CardinalSpline:GetIndexAndT(t)
    local num_points = #self.spline
    
    t = math.clamp(t, 0, 1)
    
    local float_index = math.remap(t, 0, 1, 1, num_points - 2)
    local index = math.floor(float_index)
    local new_t = float_index - index
    
    if index == num_points - 2 then
        new_t = 1
        index = num_points - 3
    end
    
    new_t = math.clamp(new_t, 0, 1)
    index = math.clamp(index, 1, num_points - 3)
    
    return index, new_t
end

function CardinalSpline:Sample(pointIndex, t)
    -- Evaluate t
    local t_pow_3 = t * t * t
    local t_pow_2 = t * t
    
    -- Evaluate Hermite basis functions
    local h1 = 2 * t_pow_3 - 3 * t_pow_2 + 1
    local h2 = -2 * t_pow_3 + 3 * t_pow_2
    local h3 = t_pow_3 - 2 * t_pow_2 + t
    local h4 = t_pow_3 - t_pow_2
    
    -- Get positions of each point
    local p1 = self.spline[pointIndex + 0].position
    local p2 = self.spline[pointIndex + 1].position
    
    local p3 = self.spline[pointIndex + 2].position
    local p0 = self.spline[pointIndex - 1].position
    
    -- Calculate the tangents from the given a
    local a1 = self.spline[pointIndex + 0].a
    local tangent1 = a1 * (p2 - p0)
    
    local a2 = self.spline[pointIndex + 1].a
    local tangent2 = a2 * (p3 - p1)
    
    -- Store the interpolated point
    return h1 * p1 + h2 * p2 + h3 * tangent1 + h4 * tangent2
end

function CardinalSpline:SampleT(t)
    local index, t = self:GetIndexAndT(t)
    
    return self:Sample(index + 1, t)
end

function CardinalSpline:SampleEntireSpline(resolution)
    local ret = {}
    
    -- Iterate a 4-point sliding window over the spline
    for pointIndex = 2, #self.spline - 2 do
        -- Generate points for each window
        for t = 0, 1, resolution do
            -- Store the interpolated point
            table.insert(ret, self:Sample(pointIndex, t))
        end
    end
    
    -- Store the last point of the spline (spline[#spline] is used for the tangent calculation)
    table.insert(ret, self.spline[#self.spline - 1].position)
    
    return ret
end
