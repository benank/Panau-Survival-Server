class 'sLootManager'

function sLootManager:__init()

    self.lootspawn_file = "lootspawns/lootspawns.txt"
    self.loot_data = {}

    self:LoadFromFile()
    self:GenerateAllLoot()

end

function sLootManager:LoadFromFile()

    math.randomseed(os.clock())
    local random = math.random
    local counter = 0
	local spawn_timer = Timer() -- time loot spawn time
	local file = io.open(self.lootspawn_file, "r") -- read from lootspawns.txt
	if file ~= nil then -- file might not exist
		local args = {}
		args.world = DefaultWorld
		for line in file:lines() do
			line = line:trim()
			if string.len(line) > 0 then -- filter out empty lines
				counter = counter + 1
                local tokens = line:split(",")
                local tier = tonumber(tokens[1])
                if Lootbox.GeneratorConfig.spawnable[tier] then
                    table.insert(self.loot_data, {
                        pos = Vector3(tonumber(tokens[2]), tonumber(tokens[3]), tonumber(tokens[4])),
                        ang = Angle(tonumber(tokens[5]), tonumber(tokens[6]), tonumber(tokens[7])),
                        tier = tonumber(tokens[1])
                    })
                else
                    print("Found lootbox spawn with invalid tier " .. tostring(tier) .. ". Skipping!")
                end
			end
		end
		file:close()
	else
		print("Fatal Error: Could not load loot from file")
	end

end

function sLootManager:GenerateAllLoot()

    for _, lootbox_data in pairs(self.loot_data) do

        -- TODO: don't spawn all loot at once

        -- TODO: get this info from spawn module
        local sz_position = Vector3(-10291, 202.5, -3019)
        local sz_radius = 75
        local in_sz = lootbox_data.pos:Distance(sz_position) < sz_radius

        CreateLootbox({
            position = lootbox_data.pos,
            angle = lootbox_data.ang,
            tier = lootbox_data.tier,
            contents = in_sz and {} or ItemGenerator:GetLoot(lootbox_data.tier)
        })

    end

    print("Spawned " .. tostring(#self.loot_data) .. " boxes.")

end

LootManager = sLootManager()