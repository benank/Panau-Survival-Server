QuesterConfig = 
{
    position = Vector3(-10334.650391, 203.063522, -2996.068604),
    angle = Angle(-0.774175, 0.000000, 0.000000),
    model_id = 2
}

-- Returns if a player has the necessary prereqs to start a quest
function CanPlayerStartQuest(player, quest_id)
    
    if not IsPlayerInRangeOfQuester(player) then return false end
    
    -- Player completed already or has a quest active already
    if HasPlayerCompletedQuestAlready(player, quest_id)
    or DoesPlayerHaveAnyActiveQuest(player) then return false end
    
    -- Check quest prereq
    local quest_data = QuestData[quest_id]
    if quest_data.quest_req ~= nil and not HasPlayerCompletedQuestAlready(player, quest_data.quest_req) then return false end
    
    -- Check level prereq
    local exp = player:GetValue("Exp")
    if quest_data.level_req ~= nil and exp.level < quest_data.level_req then return false end
    
    return true
end

-- Returns the total number of stages in the quest
function GetNumStagesInQuest(quest_id)
    return count_table(QuestData[quest_id].stages) 
end

-- Returns the quest id the player is currently working on, if any
function GetPlayerActiveQuest(player)
    local current_quest = player:GetValue("CurrentQuest")
    if current_quest then
        return current_quest.id
    end
end

-- Returns if a player currently has an active quest they are working on
function DoesPlayerHaveAnyActiveQuest(player)
    return GetPlayerActiveQuest(player) ~= nil
end

-- Returns if a player has already completed a quest
function HasPlayerCompletedQuestAlready(player, quest_id)
    return player:GetValue("CompletedQuests")[quest_id]
end

-- Returns the player's current quest stage, if they are currently doing a quest
function GetPlayerCurrentQuestStage(player)
    local current_quest = player:GetValue("CurrentQuest")
    if current_quest then
        return current_quest.stage
    end
end

-- Returns if the player is close enough to the quester to get/finish quests
function IsPlayerInRangeOfQuester(player)
    return player:GetPosition():Distance(QuesterConfig.position) < 8 
end