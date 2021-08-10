
-- Must contain: position, angle, tier, contents
function CreateLootbox(args)

    -- Only add to existing nearby box if within a landclaim
    if args.tier == Lootbox.Types.Dropbox then

        local cell = GetCell(args.position, Lootbox.Cell_Size)

        for _, box in pairs(LootCells.Loot[cell.x][cell.y]) do

            -- If there is another dropbox close enough, use that one
            if box.tier == Lootbox.Types.Dropbox and box.position:Distance(args.position) < 1.5 then

                local landclaim = FindFirstActiveLandclaimContainingPosition(args.position)

                if landclaim and count_table(box.contents) + count_table(args.contents) < Inventory.config.max_slots_per_category then
                    for k,v in pairs(args.contents) do
                        box:AddStack(v)
                    end
                    return box
                end
                
            end

        end

    end

    local box = sLootbox(args)

    VerifyCellExists(LootCells.Loot, box.cell)
    LootCells.Loot[box.cell.x][box.cell.y][box.uid] = box

    return box

end

function FindFirstActiveLandclaimContainingPosition(pos)
    local sharedobject = SharedObject.GetByName("Landclaims")
    if not sharedobject then return end
    local landclaims = sharedobject:GetValue("Landclaims")
    if not landclaims then return end

    for steam_id, player_landclaims in pairs(landclaims) do
        for id, landclaim in pairs(player_landclaims) do
            if landclaim.state == 1 and IsInSquare(landclaim.position, landclaim.size, pos) then
                return landclaim
            end
        end
    end
end

function GetNearbyPlayersInCell(cell)

    local nearby_players = {}

    -- Sync to all players in adjacent cells
    for x = cell.x - 1, cell.x + 1 do

        for y = cell.y - 1, cell.y + 1 do

            VerifyCellExists(LootCells.Player, {x = x, y = y})
            for _, player in pairs(LootCells.Player[x][y]) do

                if IsValid(player) then
                    table.insert(nearby_players, player)
                end

            end

        end

    end

    return nearby_players

end


function CreateItem(args)

    if not args.name or not args.amount or args.amount < 1 then
        print("CreateItem failed: missing name or amount")
        return nil
    end

    if not Items_indexed[args.name] then
        print("CreateItem failed: item was not found: " .. args.name)
        return nil
    end

    local data = deepcopy(Items_indexed[args.name])

    if data.durable then

        data.max_durability = data.max_durability and data.max_durability or Items.Config.default_durability
        data.durability = args.max_dura and data.max_durability or randy(
            math.ceil(Items.Config.min_durability_percent * data.max_durability),
            math.ceil(Items.Config.max_durability_percent * data.max_durability),
            math.random() * os.time()
        )

        if data.min_dura_amt and data.max_dura_amt then
            data.durability = ((data.max_dura_amt - data.min_dura_amt) * math.random() + data.min_dura_amt) * data.max_durability
        end

        if args.durability_percent then
            data.durability = data.max_durability * args.durability_percent
        end

    end

    data.equipped = false

    for k,v in pairs(args) do data[k] = v end

    if data.durable then
        -- Revert huge durability bug
        while data.durability and data.durability / data.max_durability > 5 do
            data.durability = data.durability / data.max_durability
        end
    end

    return shItem(data)

end

function table.clone(org)
    return {table.unpack(org)}
end

function GenerateDefaultInventory(inv_config)

    local items = {}

    for k,v in pairs(inv_config) do 
        
        local item = CreateItem(v)
        local contents = {item}

        if item.durable or item.can_equip then
            contents = {}
            for i = 1, v.amount do
                table.insert(contents, CreateItem({
                    name = v.name,
                    amount = 1,
                    max_dura = v.durability == nil,
                    durability_percent = v.durability
                }))
            end
        end

        table.insert(items, shStack({contents = contents}))
        
    end

    return items

end

-- Used only for chat commands
function GetLootName(lootstring)
    local split = splitstr(lootstring, " ")

    local name = split[1] or ""

    for i = 2, #split - 1 do
        name = name .. " " .. split[i]
    end

    return name

end

-- Used only for chat commands
function GetLootAmount(lootstring)
    local split = splitstr(lootstring, " ")
	return tonumber(split[#split])
end

local random = math.random

function randy(_min, _max, _seed)
    --math.randomseed(_seed and _seed or os.time())
    return math.random(_min, _max)
end

function splitstr(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end