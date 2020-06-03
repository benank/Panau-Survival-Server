class 'Thread'

function Thread:__init(func)

    self.finished = false

    local modified_func = function()
        func()
        self.finished = true
    end
    
    local f = coroutine.wrap(function()

        local co = coroutine.create(modified_func) -- runs the thread

        self.status, self.error = coroutine.resume(co)

        while not self.finished do
            Timer.Sleep(100)
        end

        if not self.status then
            error(debug.traceback(co, self.error))
        end

    end)()

end

function Thread:IsFinished()
    return self.finished
end

function Thread:GetStatus()
    return self.status
end

function Thread:GetError()
    return self.error
end