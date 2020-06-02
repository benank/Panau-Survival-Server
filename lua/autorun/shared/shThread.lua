class 'Thread'

function Thread:__init(func)

    self.finished = false

    local cr = coroutine.create(func) -- runs the thread

    self.status, self.error = coroutine.resume(cr, self)

    self.finished = true

    if not self.status then
        error(debug.traceback(cr, self.error))
    end

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