class 'sCellLootManager'

function sCellLootManager:__init()
	self.default_tier_values = {25, 20, 10, 4, 1, 0, 0, 0} -- tier1 = 25, tier2 = 20, etc
	
	self.mapping_players = DynamicCellTable(nil, nil)
	
	Network:Subscribe("Inventory/RequestGenerateLootCell", self, self.RequestGenerateLootCell)
end

function sCellLootManager:RequestGenerateLootCell(cells)
	if not cells then return end
	
	for x, y_table in pairs(cells) do
		for y, value in pairs(y_table) do
			
		end
	end
end

function sCellLootManager:GetTargetLootCountForTier(cell_x, cell_y, tier)
	-- TODO - make cell-specific behavior
	return self.default_tier_values[tier]
end

-- designate the sole player to map the cell
function sCellLootManager:SetMappingPlayer(cell_x, cell_y, player)
	self.mapping_players:SetValue(cell_x, cell_y, player)
	--debug("Set Mapping Player for " .. tostring(cell_x) .. " " .. tostring(cell_y))
end

function sCellLootManager:HasMappingPlayer(cell_x, cell_y)
	local player = self.mapping_players:GetValue(cell_x, cell_y)
	
	if player and IsValid(player) then
		return true
	else
		return false
	end
end

function sCellLootManager:GetMappingPlayer(cell_x, cell_y)
	local player = self.mapping_players:GetValue(cell_x, cell_y)
	
	if player and IsValid(player) then
		return player
	else
		return nil
	end
end

sCellLootManager = sCellLootManager()