local events = {}
local Restart = Timer.Restart
local GetTime = Timer.GetMilliseconds
local resume, yield, running = coroutine.resume, coroutine.yield, coroutine.running

local function Clear(timer)
    events[timer] = nil
end

local function SetImmediate(callback)
    local timer = Timer()
    events[timer] = {1, callback}
    return timer
end

local function SetTimeout(delay, callback)
    local timer = Timer()
    events[timer] = {2, callback, delay}
    return timer
end

local function SetInterval(delay, callback)
    local timer = Timer()
    events[timer] = {3, callback, delay}
    return timer
end

local function Sleep(delay)
    local coro = running()
    SetTimeout(delay, function(args)
        resume(coro, args)
    end)
    return yield()
end

local function Tick(args)
    for timer, event in pairs(events) do
        local delta = GetTime(timer)
		local type = event[1]
        if type == 1 then
            event[2]({delta = delta})
            Clear(timer)
        elseif type == 2 then
            if delta >= event[3] then
                event[2]({delta = delta})
                Clear(timer)
            end
        elseif type == 3 then
            if delta >= event[3] then
                event[2]({delta = delta})
                Restart(timer)
            end
        end
    end
end

Events:Subscribe("PostTick", Tick)

Timer.Clear = Clear
Timer.SetImmediate = SetImmediate
Timer.SetTimeout = SetTimeout
Timer.SetInterval = SetInterval
Timer.Sleep = Sleep
Timer.Tick = Tick