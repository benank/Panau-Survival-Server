class 'sLootManager'

function sLootManager:__init()

    self.ready = false
    self.lootspawn_file = "lootspawns/lootspawns.txt"
    self.loot_data = {}

    self.active_lootboxes = {}
    self.inactive_lootboxes = {}

    self:LoadFromFile()
    self:GenerateAllLoot()

    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(Lootbox.Cell_Size), self, self.PlayerCellUpdate)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)

end

function sLootManager:ClientModuleLoad(args)

    --Thread(function()
    --    while not self.ready do
    --        Timer.Sleep(500)
    --    end
    --    if IsValid(args.player) then
            Events:Fire("ForcePlayerUpdateCell", {player = args.player, cell_size = Lootbox.Cell_Size})
    --    end
    --end)
    
end

function sLootManager:PlayerQuit(args)
    -- Remove player from cell if they are in one
    if args.player:GetValue("Cell") and args.player:GetValue("Cell")[Lootbox.Cell_Size] then
        
        local cell = args.player:GetValue("Cell")[Lootbox.Cell_Size]
        if not cell.x or not cell.y then return end
        VerifyCellExists(LootCells.Player, cell)
        LootCells.Player[cell.x][cell.y][tostring(args.player:GetSteamId().id)] = nil

    end
end

-- Updates LootCells.Player
function sLootManager:UpdatePlayerInCell(args)
    local cell = args.cell

    if args.old_cell.x ~= nil and args.old_cell.y ~= nil then
        VerifyCellExists(LootCells.Player, args.old_cell)
        LootCells.Player[args.old_cell.x][args.old_cell.y][tostring(args.player:GetSteamId().id)] = nil
    end

    VerifyCellExists(LootCells.Player, cell)
    LootCells.Player[cell.x][cell.y][tostring(args.player:GetSteamId().id)] = args.player

end

function sLootManager:PlayerCellUpdate(args)

    self:UpdatePlayerInCell(args)
    
    local lootbox_data = {}

    for _, update_cell in pairs(args.updated) do

        -- If these cells don't exist, create them
        VerifyCellExists(LootCells.Loot, update_cell)

        for _, lootbox in pairs(LootCells.Loot[update_cell.x][update_cell.y]) do
            if lootbox.active then -- Only get active boxes
                table.insert(lootbox_data, lootbox:GetSyncData(args.player))
            end
        end
    end
    
	-- send the existing lootboxes in the newly streamed cells
    Network:Send(args.player, "Inventory/LootboxCellsSync", {lootbox_data = lootbox_data})
end

--[[function sLootManager:DespawnBox(box)
    self.active_lootboxes[box.tier][box.uid] = nil
    self.inactive_lootboxes[box.tier][box.uid] = box
end

function sLootManager:RespawnBox(tier)

    -- Select a box from inactive
    if count_table(self.inactive_lootboxes[tier]) == 0 then return end
    
    local box = random_table_value(self.inactive_lootboxes[tier])

    if not box then
        error("Failed to find inactive box for tier " .. tostring(tier))
        return
    end

    self.inactive_lootboxes[tier][box.uid] = nil
    self.active_lootboxes[tier][box.uid] = box

    box:RespawnBox()

end]]

function sLootManager:LoadFromFile()

    math.randomseed(os.clock())
    local random = math.random
    local counter = 0
	local spawn_timer = Timer() -- time loot spawn time
    local file = io.open(self.lootspawn_file, "r") -- read from lootspawns.txt

    local tiers = {}
    
	if file ~= nil then -- file might not exist
		for line in file:lines() do
			line = line:trim()
            if string.len(line) > 0 then -- filter out empty lines
                
				counter = counter + 1
                local tokens = line:split(",")
                local tier = tonumber(tokens[1])

                if not tiers[tier] then
                    tiers[tier] = 1
                else
                    tiers[tier] = tiers[tier] + 1
                end

                -- If this box is a spawnable box
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
    
    print(string.format("Loaded: %d tier 1, %d tier 2, %d tier 3, %d tier 4", 
        tiers[Lootbox.Types.Level1], tiers[Lootbox.Types.Level2], tiers[Lootbox.Types.Level3], tiers[Lootbox.Types.Level4]))

end

function sLootManager:GenerateAllLoot()

    --Thread(function()
        local rand = math.random

        local sz_position = Vector3(-10291, 202.5, -3019)
        local sz_radius = 75

        -- Init active and inactive loot tables to track spawned loot
        for tier, _ in pairs(Lootbox.GeneratorConfig.spawnable) do
            self.active_lootboxes[tier] = {}
            self.inactive_lootboxes[tier] = {}
        end

        local cnt = 0

        for _, lootbox_data in pairs(self.loot_data) do

            local in_sz = lootbox_data.pos:Distance(sz_position) < sz_radius
            local active = rand() <= Lootbox.GeneratorConfig.box[lootbox_data.tier].max_spawned

            local box = CreateLootbox({
                position = lootbox_data.pos,
                angle = lootbox_data.ang,
                tier = lootbox_data.tier,
                active = active or in_sz,
                in_sz = in_sz,
                contents = in_sz and {} or ItemGenerator:GetLoot(lootbox_data.tier)
            })

            -- Separate active & inactive boxes
            if active then
                self.active_lootboxes[box.tier][box.uid] = box
            else
                self.inactive_lootboxes[box.tier][box.uid] = box
            end

            cnt = cnt + 1

            --if cnt % 100 == 0 then
            --    Timer.Sleep(1)
            --end

        end

        print(string.format("Spawned %s/%s lootboxes.",
            tostring(self:GetNumSpawnedBoxes()), tostring(#self.loot_data)))

        self.ready = true
    --end)

end

function sLootManager:GetNumSpawnedBoxes()
    
    local lootbox_total = 0
    for tier, _ in pairs(self.active_lootboxes) do
        lootbox_total = lootbox_total + count_table(self.active_lootboxes[tier])
    end
    return lootbox_total

end

LootManager = sLootManager()