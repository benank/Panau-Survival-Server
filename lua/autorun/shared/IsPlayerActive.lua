function IsPlayerActive(player)
    return IsValid(player) and 
        not player:GetValue("Loading") and
        not player:GetValue("InIntroScreen")
end