class 'sLootManager'

function sLootManager:__init()


    --self:LoadFromFile()
    --self:GenerateAllLoot()

end

function sLootManager:LoadFromFile()

    math.randomseed(os.clock())
    local random = math.random
    local counter = 0
	local spawn_timer = Timer() -- time loot spawn time
	local file = io.open("lootspawns.txt", "r") -- read from lootspawns.txt
	if file ~= nil then -- file might not exist
		local args = {}
		args.world = DefaultWorld
		for line in file:lines() do
			line = line:trim()
			if string.len(line) > 0 then -- filter out empty lines
				counter = counter + 1
                --if counter % 2 == 0 then
					--Chat:Broadcast(tostring(line), Color(255, 0, 0))
					--Chat:Broadcast("length of line: " .. tostring(string.len(line)), Color(255, 0, 0))
					local tokens = line:split(",")
					local pos = Vector3(tonumber(tokens[2]), tonumber(tokens[3]), tonumber(tokens[4]))
					local ang = Angle(tonumber(tokens[5]), tonumber(tokens[6]), tonumber(tokens[7]))
                    local original_tier = tonumber(tokens[1])
                    local tier = ConvertTier(original_tier)
                    CreateLootbox({
                        position = pos,
                        angle = ang,
                        tier = tier,
						contents = ItemGenerator:GetLoot(tier),
						original_tier = original_tier
                    })

				--end
			end
		end
		file:close()
	else
		print("Fatal Error: Could not load loot from file")
	end

    print("Spawned " .. tostring(counter) .. " boxes.")

end

function sLootManager:GenerateAllLoot()


end

LootManager = sLootManager()