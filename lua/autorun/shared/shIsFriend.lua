-- Retruns true if player has friended steam_id
function IsFriend(player, steam_id)
    if not IsValid(player) then return end
    if not steam_id then return false end
    local player_friends = player:GetValue("Friends")
    if not player_friends or player_friends:len() < 5 then return false end
    return player_friends:find(steam_id) ~= nil
end

-- Returns true if player has been friended by steam_id
function IsAFriend(player, steam_id)
    if not IsValid(player) then return end
    if not steam_id then return false end
    local player_friends = player:GetValue("FriendsAddedMe")
    if not player_friends or player_friends:len() < 5 then return false end
    return player_friends:find(steam_id) ~= nil
end

-- Returns true if both players have added each other
function AreFriends(player, steam_id)
    return IsAFriend(player, steam_id) and IsFriend(player, steam_id)
end