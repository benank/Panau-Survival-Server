-- encrypted variable
local n = xor_cipher("var_mismatch")
class 'var'

function var:__init(a)
    self.a = 
    {
        a,
        xor_cipher(a)
    }
    self.type = type(a)
    if self.a[1] == self.a[2] then
        Network:Send(xor_cipher(n), {a = self.a[1], b = 1})
        return
    end
end

function var:get()
    local u_a = xor_cipher(self.a[2])
    if u_a ~= self.a[1] and tonumber(u_a) ~= self.a[1] then
        Network:Send(xor_cipher(n), {a = u_a, _a = self.a[1]})
        return
    end
    return u_a
end

function var:set(a)
    self.a[2] = xor_cipher(a)
    self.a[1] = a
end