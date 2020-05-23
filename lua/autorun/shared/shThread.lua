class 'Thread'

function Thread:__init(func)
    self.finished = false

    local modified_func = function()
        func()
        self.finished = true
    end
    
    local f = coroutine.wrap(function()

        self.status, self.error = pcall(coroutine.wrap(modified_func)) -- runs the thread

        while not self.finished and not self.error do
            Timer.Sleep(100)
        end

        assert(self.status, string.format("Thread error: %s", self.error))

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