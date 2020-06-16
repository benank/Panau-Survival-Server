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

    self.tab_control = TabControl.Create( self.window )
    self.tab_control:SetDock( GwenPosition.Fill )

    self.categories = {}

    self.category_names = 
    {
        [1] = "Stats",
        [2] = "Perks",
        [3] = "Leaderboard"
    }

    self:CreateConfirmMenu()
    self:LoadCategories()
    self:CreatePerksMenu()
    self:AddAllPerksToMenu()


    Events:Subscribe("ModulesLoad", self, self.ModulesLoad)
    Events:Subscribe("PlayerExpUpdated", self, self.PlayerExpUpdated)
    Events:Subscribe("PlayerPerksUpdated", self, self.PlayerPerksUpdated)

    Events:Subscribe( "Render", self, self.Render )
    Events:Subscribe( "KeyUp", self, self.KeyUp )

    Events:Subscribe("SecondTick", self, self.SecondTick)
end

function cPerkMenu:CreateConfirmMenu()

    self.confirm_menu = Window.Create()
    self.confirm_menu:SetTitle("Confirmation")
    self.confirm_menu:SetSize(Vector2(400, 140))
    self.confirm_menu:SetPosition(Render.Size / 2 - self.confirm_menu:GetSize() / 2)
    self.confirm_menu:SetClampMovement(false)
    
    local confirm_text = Label.Create(self.confirm_menu)
    confirm_text:SetText("Are you sure you want to unlock this perk?\nThis action cannot be undone.")
    confirm_text:SetTextSize(20)
    confirm_text:SetSize( Vector2(self.confirm_menu:GetSize().x, 40) )
    confirm_text:SetMargin(Vector2(0, 10), Vector2(0, 0))
    confirm_text:SetAlignment(GwenPosition.Center)
    confirm_text:SetDock( GwenPosition.Top )

    local confirm_btn = Button.Create(self.confirm_menu)
    confirm_btn:SetText("Unlock Perk")
    confirm_btn:SetTextSize(20)
    confirm_btn:SetSize( Vector2(self.confirm_menu:GetSize().x, 40) )
    confirm_btn:SetMargin(Vector2(0, 10), Vector2(0, 0))
    confirm_btn:SetDock( GwenPosition.Bottom )
    confirm_btn:Subscribe("Press", self, self.ConfirmPerkButton)

    self.confirm_menu:Hide()

end

function cPerkMenu:CreateChoiceMenu(choice_data)

    if self.choice_menu then
        self.choice_menu = self.choice_menu:Remove()
    end

    self.choice_menu = Window.Create()
    self.choice_menu:SetTitle("Perk Choice")
    self.choice_menu:SetSize(Vector2(500, 100 + 50 * count_table(choice_data.choices)))
    self.choice_menu:SetPosition(Render.Size / 2 - self.choice_menu:GetSize() / 2)
    self.choice_menu:SetClampMovement(false)
    
    local confirm_text = Label.Create(self.choice_menu)
    confirm_text:SetText(choice_data.text)
    confirm_text:SetTextSize(20)
    confirm_text:SetSize( Vector2(self.choice_menu:GetSize().x, 40) )
    confirm_text:SetMargin(Vector2(0, 10), Vector2(0, 0))
    confirm_text:SetAlignment(GwenPosition.Center)
    confirm_text:SetDock( GwenPosition.Top )

    for choice_index, choice_text in ipairs(choice_data.choices) do

        local confirm_btn = Button.Create(self.choice_menu)
        confirm_btn:SetText(choice_text)
        confirm_btn:SetTextSize(20)
        confirm_btn:SetHeight( 40 )
        confirm_btn:SetMargin(Vector2(0, 10), Vector2(0, 0))
        confirm_btn:SetDock( GwenPosition.Bottom )
        confirm_btn:SetDataNumber("choice_index", choice_index)
        confirm_btn:Subscribe("Press", self, self.PressChoiceButton)

    end

end

function cPerkMenu:PressChoiceButton(btn)

    if not btn:GetDataNumber("choice_index") then return end

    self.current_unlocking_choice = btn:GetDataNumber("choice_index")

    self.choice_menu = self.choice_menu:Remove()

    self.confirm_menu:Show()

end

function cPerkMenu:ConfirmPerkButton()

    -- Player pressed confirm perk button to unlock a perk

end

function cPerkMenu:ModulesLoad()
    self:UpdateCategoryNames()
end

function cPerkMenu:PlayerPerksUpdated()
    self:UpdateCategoryNames()
    self:UpdatePerks()
end

function cPerkMenu:PlayerExpUpdated()
    self:UpdatePerks()
end

function cPerkMenu:UpdateCategoryNames()

    -- Update perk points title
    if LocalPlayer:GetValue("Perks") then
        self.categories["Perks"].button:SetText(string.format("Perks (%d points)", LocalPlayer:GetValue("Perks").points))
    end

end

-- Updates all perks and buttons with proper colors, text, tooltips, etc
function cPerkMenu:UpdatePerks()

    local exp = LocalPlayer:GetValue("Exp")
    local perks = LocalPlayer:GetValue("Perks")

    if not exp or not perks then return end

    for id, data in pairs(self.categories["Perks"].perks) do
        local perk_data = ExpPerksById[id]

        local locked = (exp.level < perk_data.level_req or perks.points < perk_data.cost) and not perks.unlocked_perks[id]
        
        -- It has a prereq perk
        if perk_data.perk_req > 0 then
            locked = locked or not perks.unlocked_perks[perk_data.perk_req]
        end

        data.item:GetCellContents(1):SetTextColor(exp.level >= perk_data.level_req and Color.White or Color.Red)
        data.item:GetCellContents(4):SetTextColor(perks.points >= perk_data.cost and Color.White or Color.Red)

        local btn = data.item:FindChildByName("button_Unlock", true)

        -- Update button with "Unlock", "Locked", or "Unlocked"
        if locked then
            -- Locked perk
            btn:SetText("Locked")
            btn:SetTextNormalColor(Color.Red)
            btn:SetTextHoveredColor(Color.Red)
            btn:SetTextPressedColor(Color.Red)
            btn:SetTextDisabledColor(Color.Red)
            btn:SetToggleable(false)
            btn:SetDataBool("Unlockable", false)
            btn:SetBackgroundVisible(false)
            
        elseif not perks.unlocked_perks[id] then
            -- Perk that can be unlocked
            btn:SetText("Unlock")
            btn:SetTextNormalColor(Color.White)
            btn:SetTextHoveredColor(Color.White)
            btn:SetTextPressedColor(Color.White)
            btn:SetTextDisabledColor(Color.White)
            btn:SetToggleable(false)
            btn:SetDataBool("Unlockable", true)
            btn:SetBackgroundVisible(true)

        else
            -- Unlocked perk
            btn:SetText("Unlocked")
            btn:SetTextNormalColor(Color(0, 230, 0))
            btn:SetTextHoveredColor(Color(0, 230, 0))
            btn:SetTextPressedColor(Color(0, 230, 0))
            btn:SetTextDisabledColor(Color(0, 230, 0))
            btn:SetToggleable(true)
            btn:SetToggleState(true)
            btn:SetDataBool("Unlockable", false)
            --btn:SetBackgroundVisible(false)

        end
        

    end

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

    self.current_unlocking_choice = nil

    if not btn:GetDataBool("Unlockable") then return end

    local perk_id = btn:GetDataNumber("perk_id")
    if not perk_id then return end

    self.current_unlocking_perk_id = perk_id

    if ExpPerkChoiceText[perk_id] then
        -- This perk has multiple choices, so show the menu
        self:CreateChoiceMenu(ExpPerkChoiceText[perk_id])

    else
        -- This perk only has one option, so show confirmation menu
        self.confirm_menu:Show()

    end

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
        self.confirm_menu:Hide()

        if self.choice_menu then
            self.choice_menu = self.choice_menu:Remove()
        end

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