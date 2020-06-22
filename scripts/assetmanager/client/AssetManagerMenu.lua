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

    self.delete_confirm_menu = Window.Create()
    self.delete_confirm_menu:SetTitle("Are you sure you want to delete?")
    self.delete_confirm_menu:SetSize(Vector2(400, 140))
    self.delete_confirm_menu:SetPosition(Render.Size / 2 - self.delete_confirm_menu:GetSize() / 2)
    self.delete_confirm_menu:SetClampMovement(false)
    
    local delete_text = Label.Create(self.delete_confirm_menu)
    delete_text:SetText("Are you sure you want to delete?\nThis action cannot be undone.")
    delete_text:SetTextSize(20)
    delete_text:SetSize( Vector2(self.delete_confirm_menu:GetSize().x, 40) )
    delete_text:SetMargin(Vector2(0, 10), Vector2(0, 0))
    delete_text:SetAlignment(GwenPosition.Center)
    delete_text:SetDock( GwenPosition.Top )

    local delete_btn = Button.Create(self.delete_confirm_menu)
    delete_btn:SetText("Delete")
    delete_btn:SetTextColor(Color.Red)
    delete_btn:SetTextSize(20)
    delete_btn:SetSize( Vector2(self.delete_confirm_menu:GetSize().x, 40) )
    delete_btn:SetMargin(Vector2(0, 10), Vector2(0, 0))
    delete_btn:SetDock( GwenPosition.Bottom )
    delete_btn:Subscribe("Press", self, self.ConfirmDeleteButton)

    self.delete_confirm_menu:Hide()

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
    self:CreateStashesMenu()


    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)
    Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated)

    Events:Subscribe( "Render", self, self.Render )
    Events:Subscribe( "KeyUp", self, self.KeyUp )

    Events:Subscribe("Vehicles/OwnedVehiclesUpdate", self, self.OwnedVehiclesUpdate)
    Events:Subscribe("Vehicles/ResetVehiclesMenu", self, self.ResetVehiclesMenu)

    Events:Subscribe("Stashes/ResetStashesMenu", self, self.ResetStashesMenu)
    Events:Subscribe("Stashes/UpdateStashes", self, self.UpdateStashes)

    Events:Subscribe("SecondTick", self, self.SecondTick)
end

function AssetManagerMenu:ModulesLoad()
    self:UpdateCategoryNames()
end

function AssetManagerMenu:PlayerPerksUpdated()
    -- Delay for server to update values
    Timer.SetTimeout(2000, function()
        self:UpdateCategoryNames()
    end)
end

function AssetManagerMenu:UpdateCategoryNames()

    if LocalPlayer:GetValue("MaxVehicles") ~= nil then
        self.categories["Vehicles"].button:SetText(string.format("Vehicles (%d/%d)", 
            count_table(self.categories["Vehicles"].vehicles), LocalPlayer:GetValue("MaxVehicles")))
    end

    if LocalPlayer:GetValue("MaxStashes") ~= nil then
        self.categories["Stashes"].button:SetText(string.format("Stashes (%d/%d)", 
            count_table(self.categories["Stashes"].stashes), LocalPlayer:GetValue("MaxStashes")))
    end

end


function AssetManagerMenu:SecondTick()
    self:UpdateVehicleSecondTick()
    self:UpdateStashSecondTick()
end

function AssetManagerMenu:UpdateVehicleSecondTick()
    for id, vehicle_data in pairs(self.categories["Vehicles"].vehicles) do
        local pos = vehicle_data.data.position
        if IsValid(vehicle_data.data.vehicle) then
            pos = vehicle_data.data.vehicle:GetPosition()
        end

        -- Also update position in data table
        self.categories["Vehicles"].vehicles[id].data.position = pos

        vehicle_data.item:SetCellText( 2, self:GetFormattedDistanceString(LocalPlayer:GetPosition():Distance(pos)) )
        
        local health = IsValid(vehicle_data.data.vehicle) and vehicle_data.data.vehicle:GetHealth() or vehicle_data.data.health
        vehicle_data.item:SetCellText( 1, string.format("%.0f%%", health * 100) )
    end
end

function AssetManagerMenu:UpdateStashSecondTick()
    for id, stash_data in pairs(self.categories["Stashes"].stashes) do

        local pos = stash_data.data.position
        stash_data.item:SetCellText( 3, self:GetFormattedDistanceString(LocalPlayer:GetPosition():Distance(pos)) )

    end
end

function AssetManagerMenu:ResetStashesMenu()
    self.categories["Stashes"].list:Remove()
    self:CreateStashesMenu()
end

function AssetManagerMenu:ResetVehiclesMenu()
    self.categories["Vehicles"].list:Remove()
    self:CreateVehiclesMenu()
end

function AssetManagerMenu:UpdateStashes(owned_stashes)

    -- Remove non-existent stashes
    for id, data in pairs(self.categories["Stashes"].stashes) do
        if not owned_stashes[id] then
            data.item:Remove()
            self.categories["Stashes"].stashes[id] = nil
        end
    end

    for id, stash_data in pairs(owned_stashes) do
        if self.categories["Stashes"].stashes[id] then
            self:UpdateStash(stash_data)
        else
            self:AddStash(stash_data)
        end
    end

    self:UpdateCategoryNames()
end

function AssetManagerMenu:OwnedVehiclesUpdate(vehicles)

    -- Remove non-existent vehicles
    for id, data in pairs(self.categories["Vehicles"].vehicles) do
        if not vehicles[id] then
            data.item:Remove()
            self.categories["Vehicles"].vehicles[id] = nil
        end
    end

    for id, vehicle_data in pairs(vehicles) do
        if self.categories["Vehicles"].vehicles[id] then
            self:UpdateVehicle(vehicle_data)
        else
            self:AddVehicle(vehicle_data)
        end
    end

    self:UpdateCategoryNames()
end

function AssetManagerMenu:UpdateVehicle(data)
    self.categories["Vehicles"].vehicles[data.vehicle_id].data = data
    local item = self.categories["Vehicles"].vehicles[data.vehicle_id].item

    if data.spawned then
        item:FindChildByName("button_Spawn", true):Hide()
    else
        item:FindChildByName("button_Spawn", true):Show()
    end

    item:SetCellText( 3, tostring(data.guards) )
end

function AssetManagerMenu:UpdateStash(data)
    self.categories["Stashes"].stashes[data.id].data = data
    local item = self.categories["Stashes"].stashes[data.id].item

    item:SetCellText( 0, tostring(data.name) )
    item:SetCellText( 1, string.format("%d/%d", data.num_items, data.capacity) )
    item:SetCellText( 2, tostring(data.access_mode) )
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
	item:SetCellText( 3, tostring(data.guards) )

    for i = 0, 7 do
        item:GetCellContents(i):SetTextSize(20)
        item:GetCellContents(i):SetPadding(Vector2(4,4), Vector2(4,4))

        if i ~= 0 then
            item:GetCellContents(i):SetAlignment(GwenPosition.Center)
        end

    end

    local button_names = 
    {
        [4] = "Spawn",
        [5] = "Waypoint",
        [6] = "Transfer",
        [7] = "Delete"
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
        btn:Hide()

    elseif type == "Waypoint" then

        Waypoint:SetPosition(IsValid(vehicle_data.data.vehicle) and vehicle_data.data.vehicle:GetPosition() or vehicle_data.data.position)

    elseif type == "Transfer" then

        self.transferring_vehicle_id = vehicle_data.data.vehicle_id
        VehiclePlayerTransferMenu:SetActive(true)

    elseif type == "Delete" then

        self.deleting = {type = "vehicle", id = vehicle_data.data.vehicle_id, btn = btn}
        self.delete_confirm_menu:Show()

    end
end

function AssetManagerMenu:ConfirmDeleteButton(btn)
    if self.deleting.type == "vehicle" then

        Events:Fire("Vehicles/DeleteVehicle", {
            vehicle_id = self.deleting.id
        })

    elseif self.deleting.type == "stash" then

        Events:Fire("Stashes/DeleteStash", {
            id = self.deleting.id
        })

    end

    self.deleting.btn:Hide()
    self.delete_confirm_menu:Hide()

end

function AssetManagerMenu:CreateVehiclesMenu()
    
	local list = SortedList.Create( self.categories["Vehicles"].window )
	list:SetDock( GwenPosition.Fill )
	list:AddColumn( "Vehicle Name" )
	list:AddColumn( "Health", 80 )
	list:AddColumn( "Distance", 100 )
	list:AddColumn( "Guards", 80 )
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

function AssetManagerMenu:AddStash(data)
    
    local list = self.categories["Stashes"].list

	local item = list:AddItem( tostring(data.id) )
	item:SetCellText( 0, data.name )
	item:SetCellText( 1, string.format("%d/%d", data.num_items, data.capacity) )
	item:SetCellText( 2, data.access_mode )
    item:SetCellText( 3, self:GetFormattedDistanceString(LocalPlayer:GetPosition():Distance(data.position)) )

    for i = 0, 5 do
        item:GetCellContents(i):SetTextSize(20)
        item:GetCellContents(i):SetPadding(Vector2(4,4), Vector2(4,4))

        if i ~= 0 then
            item:GetCellContents(i):SetAlignment(GwenPosition.Center)
        end

    end

    local button_names = 
    {
        [4] = "Rename",
        [5] = "Waypoint",
        [6] = "Delete"
    }
    
    for index, name in pairs(button_names) do
        local btn = Button.Create(item, "button_" .. name)
        btn:SetText(name)
        btn:SetTextSize(16)
        btn:SetAlignment(GwenPosition.Center)
        btn:SetSize(Vector2(80,24))
        btn:SetDataString("stash_id", tostring(data.id))
        btn:SetDataString("type", name)
        item:SetCellContents(index, btn)
        btn:Subscribe("Press", self, self.PressStashButton)
    end

    self.categories["Stashes"].stashes[tonumber(data.id)] = {item = item, data = data}
    self:UpdateCategoryNames()

end

function AssetManagerMenu:PressStashButton(btn)

    if self.button_timer:GetSeconds() < 0.5 then return end
    self.button_timer:Restart()
    
    local type = btn:GetDataString("type")
    local stash_data = self.categories["Stashes"].stashes[tonumber(btn:GetDataString("stash_id"))]

    if not stash_data then return end

    if type == "Rename" then

        self.stash_rename_menu:Show()
        self.stash_rename_input:MakeCaratVisible()
        self.stash_rename_input:SetCursorPosition(1)
        self.stash_rename_input:Focus()
        self.renaming_stash_id = tonumber(btn:GetDataString("stash_id"))

    elseif type == "Waypoint" then

        Waypoint:SetPosition(stash_data.data.position)

    elseif type == "Delete" then

        self.deleting = {type = "stash", id = tonumber(btn:GetDataString("stash_id")), btn = btn}
        self.delete_confirm_menu:Show()

    end
end

function AssetManagerMenu:CreateStashesMenu()
    
	local list = SortedList.Create( self.categories["Stashes"].window )
	list:SetDock( GwenPosition.Fill )
	list:AddColumn( "Stash Name" )
	list:AddColumn( "Capacity", 80 )
	list:AddColumn( "Access Mode", 100 )
	list:AddColumn( "Distance", 100 )
	list:AddColumn( "Rename", 80 )
	list:AddColumn( "Waypoint", 80 )
	list:AddColumn( "Delete", 80 )
    list:SetButtonsVisible( true )
    list:SetPadding(Vector2(0,0), Vector2(0,0))

    self.categories["Stashes"].list = list
    self.categories["Stashes"].stashes = {}

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
        
    self.stash_rename_menu = Window.Create()
    self.stash_rename_menu:SetTitle("Rename Stash")
    self.stash_rename_menu:SetSize(Vector2(400, 140))
    self.stash_rename_menu:SetPosition(Render.Size / 2 - self.stash_rename_menu:GetSize() / 2)
    self.stash_rename_menu:SetClampMovement(false)
    
    self.stash_rename_input = TextBox.Create(self.stash_rename_menu)
    self.stash_rename_input:SetTextSize(28)
	self.stash_rename_input:SetMargin( Vector2( 4, 4 ), Vector2( 4, 4 ) )
    self.stash_rename_input:SetDock( GwenPosition.Fill )
    self.stash_rename_input:SetAlignment(GwenPosition.Center)

    local rename_btn = Button.Create(self.stash_rename_menu)
    rename_btn:SetText("Rename")
    rename_btn:SetTextSize(20)
    rename_btn:SetSize( Vector2(self.stash_rename_menu:GetSize().x, 40) )
    rename_btn:SetMargin(Vector2(0, 10), Vector2(0, 0))
    rename_btn:SetDock( GwenPosition.Bottom )
    rename_btn:Subscribe("Press", self, self.PressRenameStashButton)

    self.stash_rename_menu:Hide()

end

function AssetManagerMenu:PressRenameStashButton(btn)

    local text = self.stash_rename_input:GetText()

    if text then
        text = text:sub(1, 30):trim()

        Events:Fire("Stashes/RenameStash", {
            id = self.renaming_stash_id,
            name = text
        })
    end

    self.stash_rename_menu:Hide()
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
        self.stash_rename_menu:Hide()
        self.delete_confirm_menu:Hide()

        if self.active then
            self.lpi = Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
        else
            Events:Unsubscribe(self.lpi)
            self.lpi = nil
        end
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