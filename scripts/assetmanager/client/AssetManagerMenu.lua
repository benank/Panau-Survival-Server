class 'AssetManagerMenu'

function AssetManagerMenu:__init()
    self.active = false

    self.open_key = VirtualKey.F7

    self.window = Window.Create()
    self.window:SetSizeRel( Vector2( 0.5, 0.5 ) )
    self.window:SetPositionRel( Vector2( 0.5, 0.5 ) - self.window:GetSizeRel()/2 )
    self.window:SetVisible( self.active )
    self.window:SetTitle( "Asset Manager" )
    self.window:Subscribe( "WindowClosed", self, self.Close )

    self.tab_control = TabControl.Create( self.window )
    self.tab_control:SetDock( GwenPosition.Fill )

    self.categories = {}

    self.category_names = 
    {
        [1] = "Vehicles",
        [2] = "Stashes",
        [3] = "Claims"
    }

    self:LoadCategories()
    self:CreateVehiclesMenu()

    for i = 1, 20 do
        self:AddVehicle({
            id = 3,
            name = "Really Fast Car " .. tostring(i),
            health = 0.3473812
        })
    end

    Events:Subscribe( "Render", self, self.Render )
    Events:Subscribe( "KeyUp", self, self.KeyUp )
    Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
end

function AssetManagerMenu:AddVehicle(data)

    local list = self.categories["Vehicles"].list
    
	local item = list:AddItem( tostring(data.id) )
	item:SetCellText( 0, data.name )
	item:SetCellText( 1, string.format("%.0f%%", data.health * 100) )
	item:SetCellText( 2, "..." )

    for i = 0, 5 do
        item:GetCellContents(i):SetTextSize(20)
        item:GetCellContents(i):SetPadding(Vector2(4,4), Vector2(4,4))

        if i ~= 0 then
            item:GetCellContents(i):SetAlignment(GwenPosition.Center)
        end

    end

    local button_names = 
    {
        [3] = "Spawn",
        [4] = "Waypoint",
        [5] = "Delete"
    }
    
    for index, name in pairs(button_names) do
        local btn = Button.Create(item, "button_" .. name)
        btn:SetText(name)
        btn:SetTextSize(16)
        btn:SetAlignment(GwenPosition.Center)
        btn:SetSize(Vector2(80,24))
        btn:SetDataString("vehicle_id", tostring(data.id))
        item:SetCellContents(index, btn)
        btn:Subscribe("Press", self, self.PressVehicleButton)
    end

end

function AssetManagerMenu:PressVehicleButton(btn)

end

function AssetManagerMenu:CreateVehiclesMenu()
    
	local list = SortedList.Create( self.categories["Vehicles"].window )
	list:SetDock( GwenPosition.Fill )
	list:AddColumn( "Vehicle Name" )
	list:AddColumn( "Health", 80 )
	list:AddColumn( "Distance", 80 )
	list:AddColumn( "Spawn", 80 )
	list:AddColumn( "Waypoint", 80 )
	list:AddColumn( "Delete", 80 )
    list:SetButtonsVisible( true )
    list:SetPadding(Vector2(0,0), Vector2(0,0))

    self.categories["Vehicles"].list = list

	list:SetSort( 
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

end

function AssetManagerMenu:CreateCategory( category_name )
    local t = {}
    t.window = BaseWindow.Create( self.window )
    t.window:SetDock( GwenPosition.Fill )
    t.button = self.tab_control:AddPage( category_name, t.window )

    t.tab_control = TabControl.Create( t.window )
    t.tab_control:SetDock( GwenPosition.Fill )

    t.categories = {}

    self.categories[category_name] = t

    return t
end

function AssetManagerMenu:LoadCategories()
    for category_id, category_name in ipairs(self.category_names) do
        local category_table = self:CreateCategory(category_name)
    end
end

function AssetManagerMenu:GetActive()
    return self.active
end

function AssetManagerMenu:SetActive( active )
    if self.active ~= active then
        self.active = active
        Mouse:SetVisible( self.active )
    end
end

function AssetManagerMenu:Render()
    local is_visible = self.active and (Game:GetState() == GUIState.Game)

    if self.window:GetVisible() ~= is_visible then
        self.window:SetVisible( is_visible )
    end

    if self.active then
        Mouse:SetVisible( true )
    end
end

function AssetManagerMenu:KeyUp( args )
    if args.key == self.open_key then
        self:SetActive( not self:GetActive() )
    end
end

function AssetManagerMenu:LocalPlayerInput( args )
    if self.active and Game:GetState() == GUIState.Game then
        return false
    end
end

function AssetManagerMenu:Close( args )
    self:SetActive( false )
end


AssetManagerMenu = AssetManagerMenu()