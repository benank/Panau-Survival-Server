local events = {}
local queued_for_removal = {}
local Restart = Timer.Restart
local GetTime = Timer.GetMilliseconds
local resume, yield, running = coroutine.resume, coroutine.yield, coroutine.running

local function Clear(timer)
    queued_for_removal[timer] = true
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

local function SetInstanceInterval(delay, instance, callback)
    local timer = Timer()
    events[timer] = {3, callback, delay, instance}
    return timer
end

local function Sleep(delay)
    local coro = running()
    SetTimeout(delay, function(args)
        if not coro then return end
        local status = coroutine.status(coro)

        if status == "dead" then
            print(debug.traceback("Coroutine died in Timer.Sleep. Cannot resume."))
            return
        end

        local success, error_msg = resume(coro, args)

        if not success then
            error(debug.traceback(string.format("Error in resuming coroutine in Timer.Sleep: %s", error_msg)))
        end

    end)
    return yield()
end

local function Tick(args)
    for timer, event in pairs(events) do
        if not queued_for_removal[timer] then
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
                    if event[4] then
                        local instance = event[4]
                        event[2](instance)
                        Restart(timer)
                    else
                        event[2]({delta = delta})
                        Restart(timer)
                    end
                end
            end
        end
    end

    local removed_something = false
    for timer, _ in pairs(queued_for_removal) do
        removed_something = true
        events[timer] = nil
    end
    if removed_something then
        queued_for_removal = {}
    end
end

Events:Subscribe("PostTick", Tick)

Timer.Clear = Clear
Timer.SetImmediate = SetImmediate
Timer.SetTimeout = SetTimeout
Timer.SetInterval = SetInterval
Timer.SetInstanceInterval = SetInstanceInterval
Timer.Sleep = Sleep
Timer.Tick = Tick