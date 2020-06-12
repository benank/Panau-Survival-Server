-- Written by JaTochNietDan, with slight modifications by Philpax

class 'ListGUI'

function ListGUI:__init()
	self.active = false

	self.LastTick = 0
	self.ReceivedLastUpdate = true

	self.window = Window.Create()
	self.window:SetSizeRel( Vector2( 0.4, 0.8 ) )
	self.window:SetPositionRel( Vector2( 0.5, 0.5 ) - 
								self.window:GetSizeRel()/2 )
	self.window:SetTitle( "Total Players: 0" )
	self.window:SetVisible( self.active )

	self.list = SortedList.Create( self.window )
	self.list:SetDock( GwenPosition.Fill )
	self.list:SetMargin( Vector2( 4, 4 ), Vector2( 4, 0 ) )
	self.list:AddColumn( "#", 40 )
	self.list:AddColumn( "Name" )
	self.list:AddColumn( "Ping", 64 )
	self.list:AddColumn( "Level", 64 )
	self.list:AddColumn( "Friends", 128 )
    self.list:SetButtonsVisible( true )

	self.filter = TextBox.Create( self.window )
	self.filter:SetDock( GwenPosition.Bottom )
	self.filter:SetSize( Vector2( self.window:GetSize().x, 32 ) )	
	self.filter:SetMargin( Vector2( 4, 4 ), Vector2( 4, 4 ) )
	self.filter:Subscribe( "TextChanged", self, self.FilterChanged )

	self.filterGlobal = LabeledCheckBox.Create( self.window )
	self.filterGlobal:SetDock( GwenPosition.Bottom )
	self.filterGlobal:SetSize( Vector2( self.window:GetSize().x, 20 ) )	
	self.filterGlobal:SetMargin( Vector2( 4, 4 ), Vector2( 4, 0 ) )
	self.filterGlobal:GetLabel():SetText( "Search entire name" )
	self.filterGlobal:GetCheckBox():SetChecked( true )
    self.filterGlobal:GetCheckBox():Subscribe( "CheckChanged", self, self.FilterChanged )
    
    self.colors = 
    {
        friends = Color(32, 181, 40, 150),
        i_added = Color(181, 40, 32, 150),
        they_added = Color(242, 122, 16, 150),
        default = Color(255, 255, 255, 30),
        default_odd = Color(0, 0, 0, 0),
        default_selected = Color(255, 255, 255, 50),
    }

    self.friend_delays = {} -- Delays on how often a player can be added/removed
    self.friend_delay_time = 15
    
	self.PlayerCount = 0
	self.Rows = {}

	self.sort_dir = false
	self.last_column = -1

	self.list:Subscribe( "SortPress",
		function(button)
			self.sort_dir = not self.sort_dir
		end)

	self.list:SetSort( 
		function( column, a, b )
			if column ~= -1 then
				self.last_column = column
			elseif column == -1 and self.last_column ~= -1 then
				column = self.last_column
			else
				column = 0
			end

			local a_value = a:GetCellText(column)
			local b_value = b:GetCellText(column)

			if column == 0 or column == 2 then
				local a_num = tonumber(a_value)
				local b_num = tonumber(b_value)

				if a_num ~= nil and b_num ~= nil then
					a_value = a_num
					b_value = b_num
				end
			end

			if self.sort_dir then
				return a_value > b_value
			else
				return a_value < b_value
			end
		end )

	self:AddPlayer(LocalPlayer)

	for player in Client:GetPlayers() do
		self:AddPlayer(player)
	end

	self.window:SetTitle("Total Players: "..tostring(self.PlayerCount))

    Network:Subscribe("UpdatePings", self, self.UpdatePings)
    Network:Subscribe("Friends/Update", self, self.UpdateFriends)

	Events:Subscribe( "KeyUp", self, self.KeyUp )
	Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
	Events:Subscribe( "PostTick", self, self.PostTick )
	Events:Subscribe( "PlayerJoin", self, self.PlayerJoin )
	Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )

	self.window:Subscribe( "WindowClosed", self, self.CloseClicked )
end

function ListGUI:GetActive()
	return self.active
end

function ListGUI:SetActive( state )
	self.active = state
	self.window:SetVisible( self.active )
	Mouse:SetVisible( self.active )
end

function ListGUI:KeyUp( args )
	if args.key == VirtualKey.F6 then
		self:SetActive( not self:GetActive() )
	end
end

function ListGUI:LocalPlayerInput( args )
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end

function ListGUI:UpdatePings( list )
	for ID, data in pairs(list) do
		if self.Rows[ID] ~= nil then
			self.Rows[ID]:SetCellText( 2, tostring(data.ping) )
			self.Rows[ID]:SetCellText( 3, tostring(data.level) )
		end
	end

	self.ReceivedLastUpdate = true
end

function ListGUI:UpdateFriends()
	for steam_id, tablerow in pairs(self.Rows) do
		self:UpdateFriendColor(tablerow, steam_id)
	end
end

function ListGUI:PlayerJoin( args )
	self:AddPlayer(args.player)
	self.window:SetTitle("Total Players: "..tostring(self.PlayerCount))
end

function ListGUI:PlayerQuit( args )
	self:RemovePlayer(args.player)
	self.window:SetTitle("Total Players: "..tostring(self.PlayerCount))
end

function ListGUI:CloseClicked( args )
	self:SetActive( false )
end

function ListGUI:AddPlayer( player )
	self.PlayerCount = self.PlayerCount + 1

	local item = self.list:AddItem( tostring(player:GetId()) )
	item:SetCellText( 1, player:GetName() )
	item:SetCellText( 2, "..." )
	item:SetCellText( 3, "..." )

    for i = 0, 4 do
        item:GetCellContents(i):SetTextSize(20)
        item:GetCellContents(i):SetPadding(Vector2(4,4), Vector2(4,4))

        if i ~= 1 then
            item:GetCellContents(i):SetAlignment(GwenPosition.Center)
        end

        if i == 4 and player ~= LocalPlayer then
            local btn = Button.Create(item, "button")
            btn:SetText("Add")
            btn:SetTextSize(16)
            btn:SetAlignment(GwenPosition.Center)
            btn:SetSize(Vector2(128,24))
            btn:SetPadding(Vector2(20,20), Vector2(20,20))
            btn:SetDataString("steam_id", tostring(player:GetSteamId()))
            item:SetCellContents(i, btn)
            btn:Subscribe("Press", self, self.PressFriendButton)
        end

    end

	self.Rows[tostring(player:GetSteamId())] = item

	local text = self.filter:GetText():lower()
	local visible = (string.find( item:GetCellText(1):lower(), text ) == 1)

	item:SetVisible( visible )
    self:UpdateFriendColor(item, tostring(player:GetSteamId()))

end

function ListGUI:PressFriendButton(button)

    local steam_id = button:GetDataString("steam_id")
    local delay = self.friend_delays[steam_id]

    if not delay or delay:GetSeconds() >= self.friend_delay_time then
        if button:GetText() == "Remove" then
            -- Removing a friend
            Network:Send("Friends/Remove", {id = steam_id})
        elseif button:GetText() == "Add" then
            -- Adding a friend
            Network:Send("Friends/Add", {id = steam_id})
        end
    end

    self.friend_delays[steam_id] = Timer()

end

function ListGUI:UpdateFriendColor(tablerow, steam_id)

    if AreFriends(LocalPlayer, steam_id) then
        -- Both are friends
		tablerow:SetBackgroundEvenColor(self.colors.friends)
        tablerow:SetBackgroundHoverColor(self.colors.friends)
        tablerow:SetBackgroundOddColor(self.colors.friends)
        tablerow:FindChildByName("button", true):SetText("Remove")
    elseif IsFriend(LocalPlayer, steam_id) and not IsAFriend(LocalPlayer, steam_id) then
        -- LocalPlayer friended but they did not friend back
		--tablerow:SetBackgroundEvenColor(self.colors.i_added)
        --tablerow:SetBackgroundHoverColor(self.colors.i_added)
        --tablerow:SetBackgroundOddColor(self.colors.i_added)
		tablerow:SetBackgroundEvenColor(self.colors.default)
        tablerow:SetBackgroundHoverColor(self.colors.default_selected)
        tablerow:SetBackgroundOddColor(self.colors.default_odd)
        tablerow:FindChildByName("button", true):SetText("Remove")
    elseif not IsFriend(LocalPlayer, steam_id) and IsAFriend(LocalPlayer, steam_id) then
        -- Player friended but LocalPlayer did not friend back
		--tablerow:SetBackgroundEvenColor(self.colors.they_added)
        --tablerow:SetBackgroundHoverColor(self.colors.they_added)
        --tablerow:SetBackgroundOddColor(self.colors.they_added)
		tablerow:SetBackgroundEvenColor(self.colors.default)
        tablerow:SetBackgroundHoverColor(self.colors.default_selected)
        tablerow:SetBackgroundOddColor(self.colors.default_odd)
        tablerow:FindChildByName("button", true):SetText("Add")
    else
        -- No relation to this player
		tablerow:SetBackgroundEvenColor(self.colors.default)
        tablerow:SetBackgroundHoverColor(self.colors.default_selected)
        tablerow:SetBackgroundOddColor(self.colors.default_odd)

        if steam_id ~= tostring(LocalPlayer:GetSteamId()) then
            tablerow:FindChildByName("button", true):SetText("Add")
        end
    end
    
end

function ListGUI:RemovePlayer( player )
	self.PlayerCount = self.PlayerCount - 1

	if self.Rows[tostring(player:GetSteamId())] == nil then return end

	self.list:RemoveItem( self.Rows[tostring(player:GetSteamId())] )
	self.Rows[tostring(player:GetSteamId())] = nil
end

function ListGUI:FilterChanged()
	local text = self.filter:GetText():lower()

	local globalSearch = self.filterGlobal:GetCheckBox():GetChecked()

	if text:len() > 0 then
		for k, v in pairs(self.Rows) do
			--[[
			Use a plain text search, instead of a pattern search, to determine
			whether the string is within this row.
			If pattern searching is used, pattern characters such as '[' and ']'
			in names cause this function to error.
			]]

			local index = v:GetCellText(1):lower():find( text, 1, true )
			if globalSearch then
				v:SetVisible( index ~= nil )
			else
				v:SetVisible( index == 1 )
			end
		end
	else
		for k, v in pairs(self.Rows) do
			v:SetVisible( true )
		end
	end
end

function ListGUI:PostTick()
	if self:GetActive() then
		if Client:GetElapsedSeconds() - self.LastTick >= 5 then
			Network:Send("SendPingList", LocalPlayer)

			self.LastTick = Client:GetElapsedSeconds()
			self.ReceivedLastUpdate = false
		end
	end
end

list = ListGUI()