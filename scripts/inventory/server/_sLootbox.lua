class 'sLootbox'

-- tier, position, angle, contents
function sLootbox:__init(args)

    if not args.tier 
    or not args.position 
    or not args.angle 
    or not args.contents then
        error("sLootbox:__init failed: a key argument is missing from the constructor")
    end


    self.uid = GetLootboxUID()
    self.active = true
    self.tier = args.tier
    self.original_tier = args.original_tier
    self.position = args.position
    self.cell_x, self.cell_y = GetCell(self.position)
    self.angle = args.angle
    self.contents = args.contents
    self.model_data = Lootbox.Models[args.tier]
    self.is_dropbox = args.tier == Lootbox.Types.Dropbox
    -- Eventually add support for world specification

    self.players_opened = {}

    -- Dropboxes despawn after a while
    if self.is_dropbox then

        self.despawn_timer = Timer.SetTimeout(Lootbox.Dropbox_Despawn_Time, function()
            self:Remove()
        end)

    end

    self.network_subs = {}

    table.insert(self.network_subs, Network:Subscribe("Inventory/TryOpenBox" .. tostring(self.uid), self, self.TryOpenBox))
    table.insert(self.network_subs, Network:Subscribe("Inventory/TakeLootStack" .. tostring(self.uid), self, self.TakeLootStack))
    table.insert(self.network_subs, Network:Subscribe("Inventory/CloseBox" .. tostring(self.uid), self, self.CloseBox))

    Events:Subscribe("ModuleUnload", function()
    
        self:Remove()
    
    end)


end

function sLootbox:AddStack(_stack)

    if not _stack then
        error("sLootbox:AddStack failed: _stack does not exist")
    end

    if not _stack.contents or not _stack.contents[1] then
        error("sLootbox:AddStack failed: _stack does have valid contents")
    end

    for k, stack in pairs(self.contents) do

        if stack:CanStack(_stack.contents[1]) then
            _stack = stack:AddStack(_stack)
        end

    end

    if _stack and _stack:GetAmount() > 0 then
        table.insert(self.contents, _stack)
    end

    self:UpdateToPlayers()

end

function sLootbox:TakeLootStack(args, player)

    if not self.players_opened[tostring(player:GetSteamId().id)] then return end
    if not args.index or args.index < 1 then return end
    if not self.active then return end

    local stack = self.contents[args.index]

    if not stack then return end

    local inv = InventoryManager.inventories[tostring(player:GetSteamId().id)]

    if not inv then return end

    local return_stack = inv:AddStack({stack = stack})

    if return_stack then

        self.contents[args.index] = return_stack

    else

        table.remove(self.contents, args.index)

    end

    self:UpdateToPlayers()
    -- We can sync the whole thing right now because there's not much
    -- TODO optimize this to only sync changed stacks

    if #self.contents == 0 then

        if self.tier == Lootbox.Types.Dropbox then
            self:Remove()
        elseif self.tier ~= Lootbox.Types.Storage then
            self:HideBox()
        end

    end

end

function sLootbox:TryOpenBox(args, player)

    if not IsValid(player) then return end
    if #self.contents == 0 then return end
    if player:GetPosition():Distance(self.position) > Lootbox.Distances.Can_Open + 1 then return end

    self:Open(player)

end

function sLootbox:Open(player)
    
    self.players_opened[tostring(player:GetSteamId().id)] = player
    Network:Send(player, "Inventory/LootboxOpen", {contents = self:GetContentsData()})

    if not self.despawn_timer then

        self.despawn_timer = Timer.SetTimeout(Lootbox.Loot_Despawn_Time, function()
            self:RefreshBox()
        end)

    end

end

function sLootbox:CloseBox(args, player)

    self.players_opened[tostring(player:GetSteamId().id)] = nil

end

-- Refreshes loot if not all items were taken
function sLootbox:RefreshBox()
    self.despawn_timer = nil
    self:RespawnBox()
end

-- Hides the lootbox until it's ready to respawn
function sLootbox:HideBox()

    if self.despawn_timer then
        Timer.Clear(self.despawn_timer)
        self.despawn_timer = nil
    end

    Network:SendToPlayers(GetNearbyPlayersInCell(self.cell_x, self.cell_y), "Inventory/RemoveLootbox", {cell = {x = self.cell_x, y = self.cell_y}, uid = self.uid})
    self.active = false
    self.players_opened = {}

    Timer.SetTimeout(self:GetRespawnTime(), function()
        self:RespawnBox()
    end)

end

-- Gets a dynamic respawn time based on how many players are nearby
function sLootbox:GetRespawnTime()

    local adjacent = GetAdjacentCells(self.cell_x, self.cell_y);
    local num_nearby_players = 0

    for _, cell in pairs(adjacent) do
        num_nearby_players = num_nearby_players + #LootCells.Player[cell.x][cell.y]
    end

    local base = Lootbox.GeneratorConfig.box[self.tier].respawn * 60 * 1000

    return math.max(math.ceil(base / 2), base - num_nearby_players) -- Maximum half of normal time

end

-- Respawns the lootbox
function sLootbox:RespawnBox()

    local players_opened = {}

    for k,v in pairs(self.players_opened) do
        if IsValid(v) then
            table.insert(players_opened, v)
        end
    end

    Network:SendToPlayers(players_opened, "Inventory/ForceCloseLootbox")

    self.tier = ConvertTier(self.original_tier)
    self.contents = ItemGenerator:GetLoot(self.tier)
    self.players_opened = {}

    Network:SendToPlayers(GetNearbyPlayersInCell(self.cell_x, self.cell_y), "Inventory/OneLootboxCellSync", self:GetSyncData())
    self.active = true

end

-- Removes completely, never to respawn again
function sLootbox:Remove()

    self.active = false
    Network:SendToPlayers(GetNearbyPlayersInCell(self.cell_x, self.cell_y), "Inventory/RemoveLootbox", {cell = {x = self.cell_x, y = self.cell_y}, uid = self.uid})

    if self.despawn_timer then Timer.Clear(self.despawn_timer) end

    for index, box in pairs(LootCells.Loot[self.cell_x][self.cell_y]) do

        if box.uid == self.uid then
            table.remove(LootCells.Loot[self.cell_x][self.cell_y], index)
            return
        end

    end

    self.uid = nil
    self.tier = nil
    self.position = nil
    self.cell_x = nil; self.cell_y = nil;
    self.angle = nil
    self.contents = nil
    self.model_data = nil
    self.is_dropbox = nil
    self.players_opened = nil

    for k,v in pairs(self.network_subs) do
        Network:Unsubscribe(v)
    end

    self.network_subs = nil
    self = nil

end

-- Update contents to anyone who has it open
function sLootbox:UpdateToPlayers()

    Network:SendToPlayers(self.players_opened, "Inventory/LootboxSync", {contents = self:GetContentsData()})

end

function sLootbox:GetContentsData()

    local data = {}

    for k,v in pairs(self.contents) do
        data[k] = v:GetSyncObject()
    end

    return data

end

function sLootbox:GetSyncData()

    return {
        tier = self.tier,
        position = self.position,
        angle = self.angle,
        model_data = self.model_data,
        cell = {x = self.cell_x, y = self.cell_y},
        uid = self.uid
    }

end