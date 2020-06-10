class 'sFriends'

function sFriends:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS friends (steam_id VARCHAR(20), friend_steamid VARCHAR(20))")

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Network:Subscribe("Friends/Add", self, self.AddFriend)
    Network:Subscribe("Friends/Remove", self, self.RemoveFriend)
end

function sFriends:ClientModuleLoad(args)
    -- Load all friends and send to player

    local steam_id = tostring(args.player:GetSteamId())

    -- Get all players that this player added
    local result = SQL:Query("SELECT * FROM friends WHERE steam_id = (?)")
    result:Bind(1, steam_id)
    result = result:Execute()

    local friends_str = ""
    
    if count_table(result) > 0 then

        for _, friend_data in pairs(result) do
            friends_str = friends_str .. friend_data.friend_steamid .. ","
        end

    end

    args.player:SetNetworkValue("Friends", friends_str)

    -- Now get all players who added this player
    local result = SQL:Query("SELECT * FROM friends WHERE friend_steamid = (?)")
    result:Bind(1, steam_id)
    result = result:Execute()

    local added_me_str = ""
    
    if count_table(result) > 0 then

        for _, friend_data in pairs(result) do
            added_me_str = added_me_str .. friend_data.steam_id .. ","
        end

    end

    args.player:SetNetworkValue("FriendsAddedMe", added_me_str)

    Network:Send(args.player, "Friends/Update")
    
end

function sFriends:AddFriend(args, player)
    -- Player is attempting to add someone as their friend
    local player_steam_id = tostring(player:GetSteamId())
    local adding_player = nil
    local adding_steam_id = args.id

    for p in Server:GetPlayers() do
        if tostring(p:GetSteamId()) == adding_steam_id then
            adding_player = p
            break
        end
    end

    if not adding_steam_id then return end
    if adding_steam_id == player_steam_id then return end
    if not IsValid(adding_player) then return end
    if IsFriend(player, adding_steam_id) then return end -- Already friends

    if not player:GetValue("Friends") or not adding_player:GetValue("FriendsAddedMe") then
        Chat:Send(player, "Failed to add friend.", Color.Red)
        return
    end

    local cmd = SQL:Command("INSERT INTO FRIENDS (steam_id, friend_steamid) VALUES (?, ?)")
    cmd:Bind(1, player_steam_id)
    cmd:Bind(2, adding_steam_id)
    cmd:Execute()

    local my_friends = player:GetValue("Friends")
    my_friends = my_friends .. adding_steam_id .. ","
    player:SetNetworkValue("Friends", my_friends)

    local added_friends = adding_player:GetValue("FriendsAddedMe")
    added_friends = added_friends .. player_steam_id .. ","
    adding_player:SetNetworkValue("FriendsAddedMe", added_friends)

    Network:Send(player, "Friends/Update")
    Network:Send(adding_player, "Friends/Update")

    if AreFriends(player, adding_steam_id) then
        Chat:Send(player, "You are now friends with " .. adding_player:GetName() .. ".", Color(0, 200, 0))
        Chat:Send(adding_player, "You are now friends with " .. player:GetName() .. ".", Color(0, 200, 0))
    else
        Chat:Send(player, "Sent " .. adding_player:GetName() .. " a friend request.", Color.Green)
        Chat:Send(adding_player, player:GetName() .. " sent you a friend request.", Color.Green)
    end

    local msg = string.format("%s [%s] added %s [%s] as a friend", 
        player:GetName(), player:GetSteamId(), adding_player:GetName(), adding_player:GetSteamId())

    Events:Fire("Discord", {
        channel = "Friends",
        content = msg
    })

end

function sFriends:RemoveFriend(args, player)
    -- Player is attempting to remove someone as their friend
    local player_steam_id = tostring(player:GetSteamId())
    local removing_player = nil
    local removing_steam_id = args.id

    for p in Server:GetPlayers() do
        if tostring(p:GetSteamId()) == args.id then
            removing_player = p
            break
        end
    end

    if not removing_steam_id then return end
    if removing_steam_id == player_steam_id then return end
    if not IsValid(removing_player) then return end
    if not IsFriend(player, removing_steam_id) then return end -- Not friends

    local friends_before = AreFriends(player, removing_steam_id)

    local cmd = SQL:Command("DELETE FROM FRIENDS WHERE steam_id = ? AND friend_steamid = ?")
    cmd:Bind(1, player_steam_id)
    cmd:Bind(2, removing_steam_id)
    cmd:Execute()

    local my_friends = player:GetValue("Friends")
    my_friends = my_friends:gsub(removing_steam_id, "")
    player:SetNetworkValue("Friends", my_friends)

    local removing_friends = removing_player:GetValue("FriendsAddedMe")
    removing_friends = removing_friends:gsub(player_steam_id, "")
    removing_player:SetNetworkValue("FriendsAddedMe", removing_friends)

    Network:Send(player, "Friends/Update")
    Network:Send(removing_player, "Friends/Update")

    if friends_before then
        Chat:Send(player, "You are no longer friends with " .. removing_player:GetName() .. ".", Color(200, 0, 0))
        Chat:Send(removing_player, "You are no longer friends with " .. player:GetName() .. ".", Color(200, 0, 0))
    end

    local msg = string.format("%s [%s] removed %s [%s] as a friend", 
        player:GetName(), player:GetSteamId(), removing_player:GetName(), removing_player:GetSteamId())

    Events:Fire("Discord", {
        channel = "Friends",
        content = msg
    })

end

sFriends = sFriends()