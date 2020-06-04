
local signals = {}
local render_event

local signal_expire_time = 120 -- Lasts for 60 seconds

local color = Color(255, 0, 0, 75)
local alpha = 75

function RenderSignals(args)

    local angle = Angle(Camera:GetAngle().yaw,0,0)
    local seconds = Client:GetElapsedSeconds()

    for index, data in pairs(signals) do

        local diff = 1 - math.min(signal_expire_time, seconds - data.time) / signal_expire_time
        color.a = alpha * diff

		local t = Transform3():Translate(data.pos + Vector3(0, -500, 0)):Rotate(angle)
		Render:SetTransform(t)
		
        Render:FillArea(Vector3(-0.5, 0, 0), Vector3(1.5, 1000, 0), color)

        Render:ResetTransform()

        if seconds - data.time > signal_expire_time then
            signals[index] = nil

            if count_table(signals) == 0 then
                render_event = Events:Unsubscribe(render_event)
            end
        end

    end

end

Network:Subscribe("HitDetection/DeathDropSignal", function(args)

    if Camera:GetPosition():Distance(args.position) > 1000 then return end

    table.insert(signals, {
        time = Client:GetElapsedSeconds(),
        pos = args.position
    })

    if not render_event then
        render_event = Events:Subscribe("GameRender", RenderSignals)
    end

end)
