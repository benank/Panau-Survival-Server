Helpers = {
    DrawRoad = function(road, color)
        if #road.spline > 0 then
            local spline = CardinalSpline(road.spline)
            
            local smooth_spline = spline:SampleEntireSpline(0.1)
            local last_pos = nil
            
            for _, v in ipairs(smooth_spline) do
                if last_pos then
                    Render:DrawLine(last_pos, v, color)
                end
                
                last_pos = v
            end
        end
    end
}