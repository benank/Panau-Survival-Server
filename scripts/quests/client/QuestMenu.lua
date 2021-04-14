class 'QuestMenu'

function QuestMenu:__init()
    self.active = false
    self.current_stage = 1
    
    self.open_key = VirtualKey.F5

    self.window = Window.Create()
    self.window:SetSizeRel( Vector2( 0.5, 0.5 ) )
    self.window:SetPositionRel( Vector2( 0.5, 0.5 ) - self.window:GetSizeRel()/2 )
    self.window:SetVisible( self.active )
    self.window:SetMinimumSize(self.window:GetSize() * 0.85)
    self.window:SetTitle( "Quests" )
    self.window:Subscribe( "WindowClosed", self, self.Close )
    self.window:DisableResizing() 

    self.column_index = 
    {
        Id = 0,
        QuestName = 1,
        QuestReq = 2,
        LevelReq = 3,
        Completed = 4
    }
    
    self:CreateQuestsMenu()
    self:AddAllQuestsToMenu()

    
    Events:Subscribe( "Render", self, self.Render )
    Events:Subscribe( "KeyUp", self, self.KeyUp )
    Events:Subscribe("NetworkObjectValueChange", self, self.NetworkObjectValueChange)
    Events:Subscribe("SecondTick", self, self.SecondTick)
    
end

function QuestMenu:SecondTick()
    self:RefreshRightSideContents() 
end

function QuestMenu:NetworkObjectValueChange(args)
    if args.object.__type ~= "LocalPlayer" then return end
    if args.key == "CompletedQuests" or args.key == "CurrentQuest" then
        self:RefreshRightSideContents()
        -- TODO: refresh left side contents
    end
end

function QuestMenu:AddAllQuestsToMenu()
    -- Add all quests from QuestData to the menu
    for quest_id, quest_data in pairs(QuestData) do
        if quest_data.enabled then
            quest_data.id = quest_id
            self:AddQuest(quest_data)
        end
    end
end

function QuestMenu:AddQuest(data)
    
    local list = self.list
    
	local item = list:AddItem( tostring(data.id) )
	item:SetCellText( self.column_index.Id, "#" .. tostring(data.id) )
	item:SetCellText( self.column_index.QuestName, data.title )
	item:SetCellText( self.column_index.LevelReq, data.level_req and tostring(data.level_req) or "" )
    item:SetCellText( self.column_index.QuestReq, (data.quest_req and data.quest_req > 0) and "#" .. tostring(QuestData[data.quest_req].id) or "" )
    
    for i = 0, 4 do
        item:GetCellContents(i):SetAlignment(GwenPosition.Center)
        item:GetCellContents(i):SetTextPadding(Vector2(6, 6), Vector2(6, 6))
        item:GetCellContents(i):SetTextSize(14)
    end
    
    item:GetCellContents(self.column_index.QuestName):SetAlignment(GwenPosition.Left + GwenPosition.CenterV)
    item:GetCellContents(self.column_index.QuestName):SetWrap(true)
    
    self.quests[data.id] = {item = item, data = data}

end

function QuestMenu:CreateQuestsMenu()
    
	local list = SortedList.Create( self.window )
	-- list:SetDock( GwenPosition.Fill )
    list:SetWidthAutoRel(0.5)
    list:SetHeightAutoRel(1)
	list:AddColumn( "#", 60 )
	list:AddColumn( "Quest" )
	list:AddColumn( "Quest Req.", 70 )
	list:AddColumn( "Level Req.", 70 )
	list:AddColumn( "Completed", 80 )
    list:SetButtonsVisible( true )

    self.list = list
    self.quests = {}

	list:SetSort( 
		function( column, a, b )
			if column ~= -1 then
				self.last_column = column
			elseif column == -1 and self.last_column ~= -1 then
				column = self.last_column
			else
				column = 0
			end

			local a_value = a:GetCellText(column):gsub("#", "")
			local b_value = b:GetCellText(column):gsub("#", "")

            if column == self.column_index.Id 
            or column == self.column_index.Cost
            or column == self.column_index.LevelReq
            or column == self.column_index.PerkReq then
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
 
    list:Subscribe("RowSelected", self, self.SelectQuestRow)
    
    local base_pos = Vector2(0.75, 0.03)
    self.selected_quest = {}
    self.selected_quest.title = Label.Create(self.window)
    self.selected_quest.title:SetText("Select a quest on the left to get started!")
    self.selected_quest.title:SetTextSize(32)
    self.selected_quest.title:SetWidthRel(0.3)
    self.selected_quest.title:SetHeightRel(0.1)
    self.selected_quest.title:SetWrap(true)
    self.selected_quest.title:SetAlignment(GwenPosition.Center)
    self.selected_quest.title:SetPositionRel(base_pos - Vector2(self.selected_quest.title:GetWidthRel(), 0) / 2)
    
    
    local start_pos = base_pos + Vector2(0, self.selected_quest.title:GetHeightRel() + 0.02)
    self.selected_quest.description = Label.Create(self.window)
    self.selected_quest.description:SetText("")
    self.selected_quest.description:SetTextSize(16)
    self.selected_quest.description:SetWrap(true)
    self.selected_quest.description:SizeToContents()
    self.selected_quest.description:SetWidthRel(0.3)
    self.selected_quest.description:SetAlignment(GwenPosition.Center)
    self.selected_quest.description:SetPositionRel(start_pos - Vector2(self.selected_quest.description:GetWidthRel(), 0) / 2)
    
    self.selected_quest.bottom_button = Button.Create(self.window)
    self.selected_quest.bottom_button:SetText("Start Quest")
    self.selected_quest.bottom_button:SetTextSize(20)
    self.selected_quest.bottom_button:SetTextNormalColor(Color(0, 230, 0))
	self.selected_quest.bottom_button:SetTextHoveredColor(Color(0, 230, 0))
	self.selected_quest.bottom_button:SetTextPressedColor(Color(0, 230, 0)) 
    self.selected_quest.bottom_button:SetSizeAutoRel(Vector2(0.3, 0.08))
    self.selected_quest.bottom_button:SetAlignment(GwenPosition.Center)
    local bottom_button_size = self.selected_quest.bottom_button:GetSizeRel()
    self.selected_quest.bottom_button:SetPositionRel(Vector2(0.75, 0.95) - Vector2(bottom_button_size.x / 2, bottom_button_size.y))
    self.selected_quest.bottom_button:Hide()
    self.selected_quest.bottom_button:Subscribe("Press", self, self.PressBottomButton)

    self.selected_quest.exit_button = Button.Create(self.window)
    self.selected_quest.exit_button:SetText("Exit Quest")
    self.selected_quest.exit_button:SetTextSize(12)
    self.selected_quest.exit_button:SetTextNormalColor(Color(255, 0, 0))
	self.selected_quest.exit_button:SetTextHoveredColor(Color(255, 0, 0))
	self.selected_quest.exit_button:SetTextPressedColor(Color(255, 0, 0))
    self.selected_quest.exit_button:SetSizeAutoRel(Vector2(0.07, 0.05))
    self.selected_quest.exit_button:SetAlignment(GwenPosition.Center)
    self.selected_quest.exit_button:SetPositionRel(Vector2(0.505, self.selected_quest.bottom_button:GetHeightRel() / 2 + self.selected_quest.bottom_button:GetPositionRel().y - self.selected_quest.exit_button:GetHeightRel() / 2))
    self.selected_quest.exit_button:Hide()
    self.selected_quest.exit_button:Subscribe("Press", self, self.PressExitButton)

    self.selected_quest.back_button = Button.Create(self.window)
    self.selected_quest.back_button:SetText("<")
    self.selected_quest.back_button:SetTextSize(40)
    self.selected_quest.back_button:SetAlignment(GwenPosition.Center)
    self.selected_quest.back_button:SetPositionRel(Vector2(0.505, base_pos.y))
    self.selected_quest.back_button:SetSizeRel(Vector2(0.04, 0.075))
    self.selected_quest.back_button:Hide()
    self.selected_quest.back_button:Subscribe("Press", self, self.PressBackButton)

    self.selected_quest.forward_button = Button.Create(self.window)
    self.selected_quest.forward_button:SetText(">")
    self.selected_quest.forward_button:SetTextSize(40)
    self.selected_quest.forward_button:SetAlignment(GwenPosition.Center)
    self.selected_quest.forward_button:SetSizeRel(Vector2(0.04, 0.075))
    self.selected_quest.forward_button:SetPositionRel(Vector2(1 - 0.01 - self.selected_quest.forward_button:GetWidthRel(), base_pos.y))
    self.selected_quest.forward_button:Hide()
    self.selected_quest.forward_button:Subscribe("Press", self, self.PressForwardButton)
    
    self.selected_quest.reward_title = Label.Create(self.window)
    self.selected_quest.reward_title:SetText("Reward")
    self.selected_quest.reward_title:SetTextSize(20)
    self.selected_quest.reward_title:SetTextColor(Color.Yellow)
    self.selected_quest.reward_title:SizeToContents()
    self.selected_quest.reward_title:SetWidthRel(0.3)
    self.selected_quest.reward_title:SetAlignment(GwenPosition.Center)
    self.selected_quest.reward_title:SetPositionRel(Vector2(0.75, 0.65) - self.selected_quest.reward_title:GetSizeRel() / 2)
    self.selected_quest.reward_title:Hide()
    
    self.selected_quest.reward_contents = Label.Create(self.window)
    self.selected_quest.reward_contents:SetText("5 things\n2 more thing\none last thing")
    self.selected_quest.reward_contents:SetTextSize(16)
    self.selected_quest.reward_contents:SizeToContents()
    self.selected_quest.reward_contents:SetWidthRel(0.3)
    self.selected_quest.reward_contents:SetAlignment(GwenPosition.Center)
    self.selected_quest.reward_contents:SetPositionRel(Vector2(0.75 - self.selected_quest.reward_contents:GetWidthRel() / 2, 0.65 + self.selected_quest.reward_title:GetHeightRel()))
    self.selected_quest.reward_contents:Hide()
    
end

function QuestMenu:PressBackButton()
    
end

function QuestMenu:PressForwardButton()
    
end

function QuestMenu:PressBottomButton()
    if not DoesPlayerHaveAnyActiveQuest(LocalPlayer)
    and CanPlayerStartQuest(LocalPlayer, self.selected_id) then
        Network:Send("Quests/StartQuest", {id = self.selected_id}) 
    end
end

function QuestMenu:PressExitButton()
     
end

function QuestMenu:SelectQuestRow()
    self.selected_id = self.list:GetSelectedRow():GetCellText(self.column_index.Id):gsub("#", ""):trim()
    self.selected_id = tonumber(self.selected_id)
    
    self:RefreshRightSideContents()
end

function QuestMenu:RefreshRightSideContents()
    
    if not self.selected_id then return end
     
    local quest_data = QuestData[self.selected_id]
    self.selected_quest.title:SetText(quest_data.title)
    self.selected_quest.description:SetText(quest_data.description)
    self.selected_quest.description:SizeToContents()
    self.selected_quest.bottom_button:Show()
    self.selected_quest.reward_title:Show()
    self.selected_quest.reward_contents:Show()
    
    self.selected_quest.reward_contents:SetText(quest_data.reward)
    self.selected_quest.reward_contents:SizeToContents()
    self.selected_quest.reward_contents:SetPositionRel(Vector2(0.75 - self.selected_quest.reward_contents:GetWidthRel() / 2, 0.65 + self.selected_quest.reward_title:GetHeightRel()))
    
    if GetPlayerActiveQuest(LocalPlayer) == self.selected_id then
        -- They selected their current quest
        
        self.selected_quest.bottom_button:SetEnabled(true)
        self.selected_quest.exit_button:Show()
        
    else
        -- They selected another quest
        
        self.selected_quest.bottom_button:SetText("Start Quest")
        
        self.selected_quest.back_button:Hide()
        self.selected_quest.forward_button:Hide()
        self.selected_quest.exit_button:Hide()
        
        -- Player cannot start quest
        self.selected_quest.bottom_button:SetEnabled(CanPlayerStartQuest(LocalPlayer, self.selected_id))
        
    end
    
end

function QuestMenu:GetActive()
    return self.active
end

function QuestMenu:Render()
    local is_visible = self.active and (Game:GetState() == GUIState.Game)

    if self.window:GetVisible() ~= is_visible then
        self.window:SetVisible( is_visible )
    end

    if self.active then
        Mouse:SetVisible( true )
    end
end

function QuestMenu:SetActive( active )
    if self.active ~= active then
        self.active = active
        Mouse:SetVisible( self.active )

        if self.active then
            self:RefreshRightSideContents()
            self.lpi = Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
        else
            Events:Unsubscribe(self.lpi)
            self.lpi = nil
        end
    end
end

function QuestMenu:KeyUp( args )
    if args.key == self.open_key then
        self:SetActive( not self:GetActive() )
    elseif args.key == string.byte('E') and cQuesterNPC.near_quester then
        self:SetActive( not self:GetActive() )
    end
end

function QuestMenu:LocalPlayerInput( args )
    if self.active and Game:GetState() == GUIState.Game then
        return false
    end
end

function QuestMenu:Close( args )
    self:SetActive( false )
end



QuestMenu = QuestMenu()