class 'cPerkMenu'

function cPerkMenu:__init()
    self.active = false

    self.open_key = VirtualKey.F2

    self.window = Window.Create()
    self.window:SetSizeRel( Vector2( 0.5, 0.5 ) )
    self.window:SetPositionRel( Vector2( 0.5, 0.5 ) - self.window:GetSizeRel()/2 )
    self.window:SetVisible( self.active )
    self.window:SetTitle( "Player Stats & Perks" )
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
        [1] = "Stats",
        [2] = "Perks",
        [3] = "Leaderboard"
    }

    self:LoadCategories()
    self:CreatePerksMenu()
    self:AddAllPerksToMenu()


    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)
    Events:Subscribe("PlayerExpUpdated", self, self.PlayerExpUpdated)

    Events:Subscribe( "Render", self, self.Render )
    Events:Subscribe( "KeyUp", self, self.KeyUp )

    Events:Subscribe("SecondTick", self, self.SecondTick)
end

function cPerkMenu:ModulesLoad()
    self:UpdateCategoryNames()
end

function cPerkMenu:PlayerExpUpdated()
    -- Delay for server to update values
    Timer.SetTimeout(2000, function()
        self:UpdateCategoryNames()
    end)
end

function cPerkMenu:UpdateCategoryNames()

    -- Update perk points title


end


function cPerkMenu:SecondTick()

end

function cPerkMenu:AddAllPerksToMenu()

    -- Add all perks from ExpPerks to the menu

    for _, perk_data in pairs(ExpPerks) do
        self:AddPerk(perk_data)
    end

end

function cPerkMenu:AddPerk(data)
    
    local list = self.categories["Perks"].list
    
	local item = list:AddItem( tostring(data.id) )
	item:SetCellText( 0, tostring(data.id) )
	item:SetCellText( 1, tostring(data.level_req) )
	item:SetCellText( 2, data.name )
	item:SetCellText( 3, data.description )
	item:SetCellText( 4, data.cost > 0 and tostring(data.cost) or "Free" )
    item:SetCellText( 5, data.perk_req > 0 and tostring(data.perk_req) or "" )

    for i = 0, 5 do
        if i == 3 then
            item:GetCellContents(i):SetWidth(300)
            item:GetCellContents(i):SetLineSpacing(1.25) 
            item:GetCellContents(i):SetWrap(true)
        end
        item:GetCellContents(i):SetAlignment(GwenPosition.Center)
    end

    local button_names = 
    {
        [6] = "Unlock"
    }
    
    for index, name in pairs(button_names) do
        local btn = Button.Create(item, "button_" .. name)
        btn:SetText(name)
        btn:SetAlignment(GwenPosition.Center)
        btn:SetDock(GwenPosition.Fill)
        btn:SetDataNumber("perk_id", data.id)
        item:SetCellContents(index, btn)
        btn:Subscribe("Press", self, self.PressPerkButton)
    end

    self.categories["Perks"].perks[data.id] = {item = item, data = data}

end

function cPerkMenu:PressPerkButton(btn)

end

function cPerkMenu:ConfirmDeleteButton(btn)
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

function cPerkMenu:CreatePerksMenu()
    
	local list = SortedList.Create( self.categories["Perks"].window )
	list:SetDock( GwenPosition.Fill )
	list:AddColumn( "ID", 60 )
	list:AddColumn( "Level Req.", 80 )
	list:AddColumn( "Perk", 200 )
	list:AddColumn( "Details" )
	list:AddColumn( "Cost", 60 )
	list:AddColumn( "Perk Req.", 80 )
	list:AddColumn( "Unlock", 80 )
    list:SetButtonsVisible( true )
    list:SetPadding(Vector2(0,0), Vector2(0,0))

    self.categories["Perks"].list = list
    self.categories["Perks"].perks = {}

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

function cPerkMenu:CreateCategory( category_name )
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

function cPerkMenu:LoadCategories()
    for category_id, category_name in ipairs(self.category_names) do
        local category_table = self:CreateCategory(category_name)
    end
end

function cPerkMenu:GetActive()
    return self.active
end

function cPerkMenu:SetActive( active )
    if self.active ~= active then
        self.active = active
        Mouse:SetVisible( self.active )
        self.delete_confirm_menu:Hide()

        if self.active then
            self.lpi = Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
        else
            Events:Unsubscribe(self.lpi)
            self.lpi = nil
        end
    end
end

function cPerkMenu:Render()
    local is_visible = self.active and (Game:GetState() == GUIState.Game)

    if self.window:GetVisible() ~= is_visible then
        self.window:SetVisible( is_visible )
    end

    if self.active then
        Mouse:SetVisible( true )
    end
end

function cPerkMenu:KeyUp( args )
    if args.key == self.open_key then
        self:SetActive( not self:GetActive() )
    end
end

function cPerkMenu:LocalPlayerInput( args )
    if self.active and Game:GetState() == GUIState.Game then
        return false
    end
end

function cPerkMenu:Close( args )
    self:SetActive( false )
end


cPerkMenu = cPerkMenu()