
-- Must contain: position, angle, tier, contents
function CreateLootbox(args)

    if args.tier == Lootbox.Types.Dropbox then

        local cell_x, cell_y = GetCell(args.position)

        for _, box in pairs(LootCells.Loot[cell_x][cell_y]) do

            -- If there is another dropbox close enough, use that one
            if box.tier == Lootbox.Types.Dropbox and box.position:Distance(args.position) < 2 then

                for k,v in pairs(args.contents) do
                    box:AddStack(v)
                    return
                end
                
            end

        end

    end

    local box = sLootbox(args)
    table.insert(LootCells.Loot[box.cell_x][box.cell_y], box)

    Network:SendToPlayers(GetNearbyPlayersInCell(box.cell_x, box.cell_y), "Inventory/OneLootboxCellSync", box:GetSyncData())


end

function GetNearbyPlayersInCell(cell_x, cell_y)

    local nearby_players = {}

    -- Sync to all players in adjacent cells
    for x = cell_x - 1, cell_x + 1 do

        for y = cell_y - 1, cell_y + 1 do

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

    --for k,v in pairs(args) do print(k,v) end

    if not args.name or not args.amount or args.amount < 1 then
        print("CreateItem failed: missing name or amount")
        --print(debug.traceback())
        return nil
    end

    if not Items_indexed[args.name] then
        print("CreateItem failed: item was not found: " .. args.name)
        --print(debug.traceback())
        return nil
    end

    local data = Items_indexed[args.name]

    if data.durable then

        data.max_durability = data.max_durability and data.max_durability or Items.Config.default_durability
        data.durability = randy(
            math.ceil(Items.Config.min_durability_percent * data.max_durability),
            math.ceil(Items.Config.max_durability_percent * data.max_durability)
        )

    end

    data.equipped = false

    for k,v in pairs(args) do data[k] = v end

    return shItem(data)

end

function table.clone(org)
    return {table.unpack(org)}
end

function GenerateDefaultInventory()

    local items = {}

    for k,v in pairs(Inventory.config.default_inv) do 
        
        table.insert(items, shStack({contents = {CreateItem(v)}}))
        
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

function ConvertTier(original_tier)
    return random() < Lootbox.GeneratorConfig.tier_conversion[original_tier][1].chance
    and Lootbox.GeneratorConfig.tier_conversion[original_tier][1].tier
    or Lootbox.GeneratorConfig.tier_conversion[original_tier][2].tier

end

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