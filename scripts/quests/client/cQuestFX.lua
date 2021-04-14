class 'QuestFX'

function QuestFX:__init()
end

function QuestFX:StartQuest()
    QuestCompleteRender:Activate({
        text = "QUEST STARTED",
        color = Color(137, 184, 249), 
        time = 2
    })
    
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 19,
        sound_id = 25,
        position = Camera:GetPosition(),
        angle = Angle()
    })

    sound:SetParameter(0,1)
end

function QuestFX:CompleteQuest()
    QuestCompleteRender:Activate({
        text = "QUEST COMPLETE",
        color = Color.White, 
        time = 3
    })
    
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 19,
        sound_id = 26,
        position = Camera:GetPosition(),
        angle = Angle()
    })

    sound:SetParameter(0,1)
end

function QuestFX:QuestProgression()

    QuestCompleteRender:Activate({
        text = "QUEST UPDATED",
        color = Color(141, 148, 179), 
        time = 1.5
    })
    
    local sound = ClientSound.Create(AssetLocation.Game, {
        bank_id = 19,
        sound_id = 28,
        position = Camera:GetPosition(),
        angle = Angle()
    })

    sound:SetParameter(0,1)
end

QuestFX = QuestFX()