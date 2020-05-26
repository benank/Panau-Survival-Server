class 'Thread'

function Thread:__init(func)
    self.finished = false

    local modified_func = function()
        func()
        self.finished = true
    end
    
    local f = coroutine.create(function()

        local cr = coroutine.create(modified_func) -- runs the thread

        self.status, self.error = coroutine.resume(cr)

        while not self.finished and not self.error do
            Timer.Sleep(100)
        end

        assert(self.status, string.format("Thread error: %s", self.error))

    end)

    coroutine.resume(f)


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