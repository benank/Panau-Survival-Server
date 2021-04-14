class 'sQuestManager'

function sQuestManager:__init()
    
    SQL:Execute("CREATE TABLE IF NOT EXISTS quests (steamID VARCHAR(20), current_quest INTEGER, current_quest_stage INTEGER, completed_quests BLOB)")

    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
end

function sQuestManager:ClientModuleLoad(args)
    
    local steamID = tostring(args.player:GetSteamId())

	local query = SQL:Query("SELECT * FROM quests WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()
    
    local current_quest = {}

    if #result > 0 then -- if already in DB
        
        args.player:SetNetworkValue("CompletedQuests", self:DeserializeCompletedQuests(result[1].completed_quests))
        
        if result[1].current_quest ~= 0 then
            current_quest.id = result[1].current_quest
            current_quest.stage = result[1].current_quest_stage
        end
    else

		local command = SQL:Command("INSERT INTO quests (steamID, current_quest, current_quest_stage, completed_quests) VALUES (?, ?, ?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, 0)
		command:Bind(3, 0)
		command:Bind(4, "")
        command:Execute()

        args.player:SetNetworkValue("CompletedQuests", {})
        
    end
    
    args.player:SetNetworkValue("CurrentQuest", current_quest)

    Events:Fire("PlayerQuestsUpdated", {player = args.player})

end

function sQuestManager:SavePlayer(player)

    if not IsValid(player) then return end

    local current_quest = player:GetValue("CurrentQuest")
    local completed_quests = player:GetValue("CompletedQuests")

    local update = SQL:Command("UPDATE perks SET current_quest = ?, current_quest_stage = ?, unlocked_perks = ? WHERE steamID = (?)")
	update:Bind(1, current_quest.id)
	update:Bind(2, current_quest.stage)
	update:Bind(3, self:SerializeCompletedQuests(completed_quests))
	update:Bind(4, tostring(player:GetSteamId()))
    update:Execute()

end

function sQuestManager:SerializeCompletedQuests(quests)
    local return_str = ""
    for quest_id, _ in pairs(quests) do
        return_str = return_str .. tostring(quest_id) .. "_"
    end
    return return_str
end

function sQuestManager:DeserializeCompletedQuests(quests)
    local split = quests:split("_")
    local parsed = {}
    for _, quest_id in pairs(split) do
        parsed[tonumber(quest_id)] = true
    end
    return parsed
end

sQuestManager = sQuestManager()