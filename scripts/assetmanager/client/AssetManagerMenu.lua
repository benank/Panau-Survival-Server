class 'AssetManagerMenu'

function AssetManagerMenu:__init()
    self.active = false

    self.open_key = VirtualKey.F7

    self.button_timer = Timer()

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

    Events:Subscribe( "Render", self, self.Render )
    Events:Subscribe( "KeyUp", self, self.KeyUp )
    Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )

    Events:Subscribe("Vehicles/OwnedVehiclesUpdate", self, self.OwnedVehiclesUpdate)
    Events:Subscribe("Vehicles/ResetVehiclesMenu", self, self.ResetVehiclesMenu)

    Events:Subscribe("SecondTick", self, self.SecondTick)
end

function AssetManagerMenu:SecondTick()
    self:UpdateVehicleSecondTick()
end

function AssetManagerMenu:UpdateVehicleSecondTick()
    for id, vehicle_data in pairs(self.categories["Vehicles"].vehicles) do
        local pos = vehicle_data.data.position
        if IsValid(vehicle_data.data.vehicle) then
            pos = vehicle_data.data.vehicle:GetPosition()
        end

        vehicle_data.item:SetCellText( 2, self:GetFormattedDistanceString(LocalPlayer:GetPosition():Distance(pos)) )
        
        local health = IsValid(vehicle_data.data.vehicle) and vehicle_data.data.vehicle:GetHealth() or vehicle_data.data.health
        vehicle_data.item:SetCellText( 1, string.format("%.0f%%", health * 100) )
    end

end

function AssetManagerMenu:ResetVehiclesMenu()
    self.categories["Vehicles"].list:Remove()
    self:CreateVehiclesMenu()
end

function AssetManagerMenu:OwnedVehiclesUpdate(vehicles)

    -- Remove non-existent vehicles
    for id, data in pairs(self.categories["Vehicles"].vehicles) do
        if not vehicles[id] then
            data.item:Remove()
            self.categories["Vehicles"].vehicles[id] = nil
        end
    end

    local valid_vehicles = {}

    for id, vehicle_data in pairs(vehicles) do
        if self.categories["Vehicles"].vehicles[id] then
            self:UpdateVehicle(vehicle_data)
        else
            self:AddVehicle(vehicle_data)
        end
    end

    self.categories["Vehicles"].button:SetText(string.format("Vehicles (%d/%d)", 
        count_table(self.categories["Vehicles"].vehicles), LocalPlayer:GetValue("MaxVehicles")))
end

function AssetManagerMenu:UpdateVehicle(data)
    self.categories["Vehicles"].vehicles[data.vehicle_id].data = data
    local item = self.categories["Vehicles"].vehicles[data.vehicle_id].item

    if data.spawned then
        item:FindChildByName("button_Spawn", true):Hide()
    else
        item:FindChildByName("button_Spawn", true):Show()
    end

end

function AssetManagerMenu:GetFormattedDistanceString(dist)
    if dist > 1000 then
        return string.format("%.2f km", dist / 1000)
    else
        return string.format("%.0f m", dist)
    end
end

function AssetManagerMenu:AddVehicle(data)
    
    local list = self.categories["Vehicles"].list
    
	local item = list:AddItem( tostring(data.vehicle_id) )
	item:SetCellText( 0, Vehicle.GetNameByModelId(tonumber(data.model_id)) )
	item:SetCellText( 1, string.format("%.0f%%", data.health * 100) )
	item:SetCellText( 2, self:GetFormattedDistanceString(LocalPlayer:GetPosition():Distance(data.position)) )

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
        [5] = "Transfer",
        [6] = "Delete"
    }
    
    for index, name in pairs(button_names) do
        local btn = Button.Create(item, "button_" .. name)
        btn:SetText(name)
        btn:SetTextSize(16)
        btn:SetAlignment(GwenPosition.Center)
        btn:SetSize(Vector2(80,24))
        btn:SetDataString("vehicle_id", tostring(data.vehicle_id))
        btn:SetDataString("type", name)
        item:SetCellContents(index, btn)
        btn:Subscribe("Press", self, self.PressVehicleButton)

        if name == "Spawn" and data.spawned then
            btn:Hide()
        end
    end

    self.categories["Vehicles"].vehicles[tonumber(data.vehicle_id)] = {item = item, data = data}

end

function AssetManagerMenu:PressVehicleButton(btn)

    if self.button_timer:GetSeconds() < 0.5 then return end
    self.button_timer:Restart()
    
    local type = btn:GetDataString("type")
    local vehicle_data = self.categories["Vehicles"].vehicles[tonumber(btn:GetDataString("vehicle_id"))]

    if not vehicle_data then return end

    if type == "Spawn" then

        Events:Fire("Vehicles/SpawnVehicle", {
            vehicle_id = vehicle_data.data.vehicle_id
        })

    elseif type == "Waypoint" then

        Waypoint:SetPosition(IsValid(vehicle_data.data.vehicle) and vehicle_data.data.vehicle:GetPosition() or vehicle_data.data.position)

    elseif type == "Transfer" then

        self.transferring_vehicle_id = vehicle_data.data.vehicle_id
        VehiclePlayerTransferMenu:SetActive(true)

    elseif type == "Delete" then

        Events:Fire("Vehicles/DeleteVehicle", {
            vehicle_id = vehicle_data.data.vehicle_id
        })

    end
end

function AssetManagerMenu:CreateVehiclesMenu()
    
	local list = SortedList.Create( self.categories["Vehicles"].window )
	list:SetDock( GwenPosition.Fill )
	list:AddColumn( "Vehicle Name" )
	list:AddColumn( "Health", 80 )
	list:AddColumn( "Distance", 80 )
	list:AddColumn( "Spawn", 80 )
	list:AddColumn( "Waypoint", 80 )
	list:AddColumn( "Transfer", 80 )
	list:AddColumn( "Delete", 80 )
    list:SetButtonsVisible( true )
    list:SetPadding(Vector2(0,0), Vector2(0,0))

    self.categories["Vehicles"].list = list
    self.categories["Vehicles"].vehicles = {}

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
        VehiclePlayerTransferMenu:SetActive(false)
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