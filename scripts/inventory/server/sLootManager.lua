class 'sLootManager'

function sLootManager:__init()

    self.ready = false
    self.lootspawn_file = "lootspawns/lootspawns.txt"
    self.loot_data = {}

    self.active_lootboxes = {}
    self.inactive_lootboxes = {}

    self.external_loot = {}

    self:LoadFromFile()
    self:GenerateAllLoot()

    Timer.SetInterval(1000 * 60 * 5, function()
        self:UpdateSpawnedLootCountsInSZ()
    end)

    Events:Subscribe("Cells/PlayerCellUpdate" .. tostring(Lootbox.Cell_Size), self, self.PlayerCellUpdate)
    Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
    Events:Subscribe("ClientModuleLoad", self, self.ClientModuleLoad)
    Events:Subscribe("Inventory/CreateDropboxExternal", self, self.CreateDropboxExternal)
    Events:Subscribe("inventory/CreateLootboxExternal", self, self.CreateLootboxExternal)
    Events:Subscribe("airdrops/RemoveAirdrop", self, self.RemoveAirdrop)
    Events:Subscribe("items/LockboxHackComplete", self, self.LockboxHackComplete)
    Events:Subscribe("items/CreateSecretLockbox", self, self.CreateSecretLockbox)
    Events:Subscribe("items/RemoveSecret", self, self.RemoveSecret)
    Events:Subscribe("PlayerOpenLootbox", self, self.PlayerOpenLootbox)

end

function sLootManager:PlayerOpenLootbox(args)
    if args.tier ~= Lootbox.Types.LockboxX and args.tier ~= Lootbox.Types.Lockbox then return end
    
    local lockbox = self.external_loot[args.uid]
    if not lockbox or lockbox.has_been_opened then return end
    
    local original_uid = args.original_uid
    if not original_uid then return end
    
    local original_box = self.active_lootboxes[Lootbox.Types.Level4][original_uid]
    if not original_box then return end
    
    original_box.disable_respawn = false
    original_box:StartRespawnTimer()
    
    -- Remove box after 10 minutes
    Timer.SetTimeout(10 * 60 * 1000, function()
        self:RemoveSecret(args)
    end)

end

function sLootManager:RemoveSecret(args)
    local lockbox = self.external_loot[args.uid]
    if lockbox then
        lockbox:Remove()
        self.external_loot[args.uid] = nil
    end
end

function sLootManager:CreateSecretLockbox(args)
    
    local tier = args.x and Lootbox.Types.LockboxX or Lootbox.Types.Lockbox
    
    local function IsCandidate(lootbox)
        if lootbox.in_sz then return false end
        return not lootbox.has_been_opened or not lootbox.active
    end
    
    -- Thread(function()
        local count = 0
        
        local uid_candidates = {}

        for uid, lootbox in pairs(self.active_lootboxes[Lootbox.Types.Level4]) do
            
            if IsCandidate(lootbox) then
                count = count + 1
                uid_candidates[count] = uid
                
                -- if count % 50 == 0 then
                --     Timer.Sleep(1)
                -- end
            end
        end
        
        local uid, lootbox
        
        while not uid or not lootbox or lootbox.position:Distance(Vector3(14145, 332, 14342)) < 100 do
            uid = uid_candidates[math.random(1, #uid_candidates)]
            if uid then
                lootbox = self.active_lootboxes[Lootbox.Types.Level4][uid]
            end
        end
        
        lootbox.disable_respawn = true
        lootbox:HideBox()
        
        local lockbox = self:CreateLootboxExternal({
            tier = tier,
            position = lootbox.position,
            angle = lootbox.angle,
            locked = true
        })
        lockbox.original_uid = lootbox.uid
        
        Events:Fire("Inventory/LockboxSpawned", 
        {
            uid = lockbox.uid,
            tier = tier,
            position = lockbox.position
        })
    -- end)
end

function sLootManager:LockboxHackComplete(args)
    local lootbox = self.external_loot[args.lootbox_id]
    if not lootbox then return end
    
    if not lootbox.locked then return end
    
    lootbox.locked = false
    
    lootbox:ForceClose()
    lootbox:Sync()
    
    -- Now spawn some grenades :)
    if lootbox.tier == Lootbox.Types.Lockbox then
        
        local grenade_types = {"HE Grenade", "Toxic Grenade"}
        local grenade_type = grenade_types[math.random(1, #grenade_types)]
        
        Events:Fire("items/CreateGrenade", {
            position = lootbox.position,
            grenade_type = grenade_type,
            fusetime = 4 + math.random() * 4,
            velocity = Vector3.Up,
            owner_id = "Lockbox"
        })
        
        Events:Fire("items/CreateGrenade", {
            position = lootbox.position,
            grenade_type = "Flares",
            fusetime = 0,
            velocity = Vector3.Up,
            owner_id = "Lockbox"
        })
        
    elseif lootbox.tier == Lootbox.Types.LockboxX then
        
        local grenade_types = {"HE Grenade", "Laser Grenade", "Cluster Grenade"}
        local num_traps = math.random(1, 4)
        
        for i = 1, num_traps do
            local grenade_type = grenade_types[math.random(1, #grenade_types)]
            Events:Fire("items/CreateGrenade", {
                position = lootbox.position,
                grenade_type = grenade_type,
                fusetime = 4 + math.random() * 4,
                velocity = Vector3.Up * 3 * math.random(),
                owner_id = "Lockbox"
            })
        end
        
        Events:Fire("items/CreateGrenade", {
            position = lootbox.position,
            grenade_type = "Toxic Grenade",
            fusetime = 2,
            velocity = Vector3.Up,
            owner_id = "Lockbox"
        })
        
        Events:Fire("items/CreateGrenade", {
            position = lootbox.position,
            grenade_type = "Flares",
            fusetime = 0,
            velocity = Vector3.Up,
            owner_id = "Lockbox"
        })
        
    end
end

function sLootManager:RemoveAirdrop()
    for id, lootbox in pairs(self.external_loot) do
        if lootbox.tier == Lootbox.Types.AirdropLevel1
        or lootbox.tier == Lootbox.Types.AirdropLevel2
        or lootbox.tier == Lootbox.Types.AirdropLevel3 then
            lootbox:Remove()
            self.external_loot[id] = nil
        end
    end
end

function sLootManager:UpdateSpawnedLootCountsInSZ()
    local spawned = self:GetNumSpawnedBoxes()
    local total = #self.loot_data

    Events:Fire("Inventory/UpdateTotalLootSpawns", {spawned = spawned, total = total})
end

function sLootManager:CreateLootboxExternal(args)
    args.active = true
    
    if args.contents then
        for stack_index, stack in pairs(args.contents) do
            for item_index, item in pairs(stack.contents) do
                stack.contents[item_index] = shItem(item)
            end
            args.contents[stack_index] = shStack(stack)
        end
    else
        args.contents = ItemGenerator:GetLoot(args.tier)

        -- If there are airdrop items, set them to this airdrop's tier
        if args.airdrop_tier then
            for _, stack in pairs(args.contents) do
                if stack:GetProperty("name") == "Airdrop" then
                    local next_tier_chance = 0.3
                    
                    if math.random() < next_tier_chance then
                        stack.contents[1].custom_data.level = math.min(3, args.airdrop_tier + 1)
                    else
                        stack.contents[1].custom_data.level = args.airdrop_tier
                    end
                end
            end
        elseif args.sam_level then
            for _, stack in pairs(args.contents) do
                if stack:GetProperty("name") == "SAM Key" then
                    stack.contents[1].custom_data.level = args.sam_level
                end
            end
        end
    end

    local lootbox = CreateLootbox(args)
    lootbox:Sync()
    self.external_loot[lootbox.uid] = lootbox

    if args.remove_time then
        Timer.SetTimeout(args.remove_time, function()
            lootbox:Remove()
        end)
    end
    
    return lootbox
end

function sLootManager:CreateDropboxExternal(args)
    args.tier = Lootbox.Types.Dropbox
    args.active = true
    
    for stack_index, stack in pairs(args.contents) do
        for item_index, item in pairs(stack.contents) do
            stack.contents[item_index] = shItem(item)
        end
        args.contents[stack_index] = shStack(stack)
    end

    local dropbox = CreateLootbox(args)
    dropbox:Sync()
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
        
        print(string.format("Loaded: %d tier 1, %d tier 2, %d tier 3, %d tier 4", 
            tiers[Lootbox.Types.Level1], tiers[Lootbox.Types.Level2], tiers[Lootbox.Types.Level3], tiers[Lootbox.Types.Level4]))
        self.total_spawns = tiers[Lootbox.Types.Level1] + tiers[Lootbox.Types.Level2] + tiers[Lootbox.Types.Level3] + tiers[Lootbox.Types.Level4]
	else
		print("Fatal Error: Could not load loot from file")
    end

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

    self:UpdateSpawnedLootCountsInSZ()


end

function sLootManager:GetNumSpawnedBoxes()
    
    local lootbox_total = 0
    for tier, _ in pairs(self.active_lootboxes) do
        for tieid, box in pairs(self.active_lootboxes[tier]) do
            if box.active then
                lootbox_total = lootbox_total + 1
            end
        end
    end
    return lootbox_total

end

LootManager = sLootManager()