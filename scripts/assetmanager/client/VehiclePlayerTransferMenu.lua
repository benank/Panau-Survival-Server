-- Written by JaTochNietDan, with slight modifications by Philpax

class 'VehiclePlayerTransferMenu'

function VehiclePlayerTransferMenu:__init()
	self.active = false

	self.LastTick = 0
	self.ReceivedLastUpdate = true

	self.window = Window.Create()
	self.window:SetSizeRel( Vector2( 0.3, 0.7 ) )
	self.window:SetPositionRel( Vector2( 0.5, 0.5 ) - 
								self.window:GetSizeRel()/2 )
	self.window:SetTitle( "Select a Player" )
	self.window:SetVisible( self.active )

	self.list = SortedList.Create( self.window )
	self.list:SetDock( GwenPosition.Fill )
	self.list:SetMargin( Vector2( 4, 4 ), Vector2( 4, 0 ) )
	self.list:AddColumn( "#", 40 )
	self.list:AddColumn( "Name" )
	self.list:AddColumn( "Transfer", 128 )
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

	for player in Client:GetPlayers() do
		self:AddPlayer(player)
	end

	Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
	Events:Subscribe( "PlayerJoin", self, self.PlayerJoin )
    Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )
    
	Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )

	self.window:Subscribe( "WindowClosed", self, self.CloseClicked )
end

function VehiclePlayerTransferMenu:GetActive()
	return self.active
end

function VehiclePlayerTransferMenu:SetActive( state )
	self.active = state
	self.window:SetVisible( self.active )
    Mouse:SetVisible( self.active )
end

function VehiclePlayerTransferMenu:LocalPlayerInput( args )
	if self:GetActive() and Game:GetState() == GUIState.Game then
		return false
	end
end

function VehiclePlayerTransferMenu:PlayerJoin( args )
	self:AddPlayer(args.player)
end

function VehiclePlayerTransferMenu:PlayerQuit( args )
	self:RemovePlayer(args.player)
end

function VehiclePlayerTransferMenu:CloseClicked( args )
	self:SetActive( false )
end

function VehiclePlayerTransferMenu:AddPlayer( player )

    if player == LocalPlayer then return end

	local item = self.list:AddItem( tostring(player:GetId()) )
	item:SetCellText( 1, player:GetName() )

    for i = 0, 1 do
        item:GetCellContents(i):SetTextSize(20)
        item:GetCellContents(i):SetPadding(Vector2(4,4), Vector2(4,4))

        if i ~= 1 then
            item:GetCellContents(i):SetAlignment(GwenPosition.Center)
        end

    end

    local btn = Button.Create(item, "button")
    btn:SetText("Transfer")
    btn:SetTextSize(16)
    btn:SetAlignment(GwenPosition.Center)
    btn:SetSize(Vector2(128,24))
    btn:SetPadding(Vector2(20,20), Vector2(20,20))
    btn:SetDataString("steam_id", tostring(player:GetSteamId()))
    item:SetCellContents(2, btn)
    btn:Subscribe("Press", self, self.PressTransferButton)

	self.Rows[tostring(player:GetSteamId())] = item

	local text = self.filter:GetText():lower()
	local visible = (string.find( item:GetCellText(1):lower(), text ) == 1)

	item:SetVisible( visible )

end

function VehiclePlayerTransferMenu:PressTransferButton(button)

    local steam_id = button:GetDataString("steam_id")
    Events:Fire("Vehicles/TransferVehicle", {id = steam_id, vehicle_id = AssetManagerMenu.transferring_vehicle_id})
    self:SetActive(false)

end

function VehiclePlayerTransferMenu:RemovePlayer( player )
	self.PlayerCount = self.PlayerCount - 1

	if self.Rows[tostring(player:GetSteamId())] == nil then return end

	self.list:RemoveItem( self.Rows[tostring(player:GetSteamId())] )
	self.Rows[tostring(player:GetSteamId())] = nil
end

function VehiclePlayerTransferMenu:FilterChanged()
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

VehiclePlayerTransferMenu = VehiclePlayerTransferMenu()