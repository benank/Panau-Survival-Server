class 'sTokens'

function sTokens:__init()

    self.TOKEN_LENGTH = 8

    Timer.SetInterval(1000, function()

        for p in Server:GetPlayers() do

            local token = self:GetNewToken()
            p:SetValue("HD_Token_Old", p:GetValue("HD_Token"))
            p:SetValue("HD_Token", token)

            Network:Send(p, "HitDetection/UpdateToken", {token = token})

        end

    end)

end

function sTokens:PlayerTokenMatches(player, token)
    return player:GetValue("HD_Token") == token or player:GetValue("HD_Token_Old") == token
end

function sTokens:GetNewToken()
    local token = ""
    for i = 1, self.TOKEN_LENGTH do
        token = token .. string.char(math.random(65, 90))
    end
    return token
end

sTokens = sTokens()