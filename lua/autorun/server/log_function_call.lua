local enabled = true

function log_function_call(name)
    if not enabled then return end
    file = io.open("../../function_calls.txt", "a")
    file:write(name .. "\n")
    file:close()
end