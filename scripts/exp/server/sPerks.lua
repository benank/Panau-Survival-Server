class 'sPerks'

function sPerks:__init()

    SQL:Execute("CREATE TABLE IF NOT EXISTS perks (steamID VARCHAR(20), points INTEGER, unlocked_perks BLOB)")

end

function sPerks:ClientModuleLoad(args)
    -- Called by sExp to ensure levels are loaded first
    
    local steamID = tostring(args.player:GetSteamId())

    local exp_data = args.player:GetValue("Exp")
    
	local query = SQL:Query("SELECT * FROM perks WHERE steamID = (?) LIMIT 1")
    query:Bind(1, steamID)
    
    local result = query:Execute()

    local perk_data = {}
    
    if #result > 0 then -- if already in DB
        
        perk_data.points = tonumber(result[1].points)
        perk_data.unlocked_perks = {}

        local split = result[1].unlocked_perks:trim():split(" ")

        -- Parse perks into a table
        for _, perk_id in pairs(split) do
            if perk_id:find("_") then

                -- Choice perk
                local split2 = perk_id:split("_")
                local id = tonumber(split2[1])
                local choice = tonumber(split2[2])
                perk_data.unlocked_perks[id] = choice

            else

                -- Single unlock perk
                local id = tonumber(perk_id)
                perk_data.unlocked_perks[perk_id] = 1

            end
        end

    else

        local perk_points = exp_data.level * PerkPointsPerLevel
        
        -- Retroactively add perk points
		local command = SQL:Command("INSERT INTO perks (steamID, points, unlocked_perks) VALUES (?, ?, ?)")
		command:Bind(1, steamID)
		command:Bind(2, perk_points)
		command:Bind(3, "")
        command:Execute()

        perk_data.points = perk_points
        perk_data.unlocked_perks = {}

    end
    
    
    output_table(perk_data)

    args.player:SetNetworkValue("Perks", perk_data)

end

sPerks = sPerks()