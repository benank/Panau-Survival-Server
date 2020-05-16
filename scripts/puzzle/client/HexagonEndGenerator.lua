class 'EndGenerator'

function EndGenerator:__init()

	self.n_connects = {
		[1] = {
			[2] = 3,
			[3] = 4,
			[4] = 2
			},
		[2] = {
			[1] = 1,
			[2] = 4,
			[3] = 5
			},
		[3] = {
			[3] = 6,
			[4] = 4,
			[5] = 1
			},
		[4] = {
			[1] = 3,
			[2] = 6,
			[3] = 7,
			[4] = 5,
			[5] = 2,
			[6] = 1
			},
		[5] = {
			[6] = 2,
			[1] = 4,
			[2] = 7
			},
		[6] = {
			[6] = 3,
			[5] = 4,
			[4] = 7
			},
		[7] = {
			[1] = 6,
			[6] = 4,
			[5] = 5
			}
		}

	--  2 1
	-- 5 4 3
	--  7 6 

	self.hexagons = {}
	
end

function EndGenerator:GenerateEnds(difficulty, hexagons)

	self.hexagons = hexagons
	self:lvl_1_3()

end

function EndGenerator:GetRandomEnds1()

	local ends = {
		[1] = true,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false,
		[6] = false
		}
	return ends

end

function EndGenerator:GetRandomEnds2()

	local ends = {
		[1] = true,
		[2] = false,
		[3] = false,
		[4] = false,
		[5] = false,
		[6] = false
		}
	return ends

end

function EndGenerator:lvl_1_1()

	local rand = math.random()
	if rand < 0.33 then
		EG.hexagons[1]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[3]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[5]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[7]:SetEnds(EG:GetRandomEnds1())
	elseif rand < 0.66 then
		EG.hexagons[2]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[3]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[5]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[6]:SetEnds(EG:GetRandomEnds1())
	else
		EG.hexagons[1]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[2]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[6]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[7]:SetEnds(EG:GetRandomEnds1())
	end

end

function EndGenerator:lvl_1_1()

	local rand = math.random()
	if rand < 0.33 then
		EG.hexagons[1]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[3]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[5]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[7]:SetEnds(EG:GetRandomEnds1())
	elseif rand < 0.66 then
		EG.hexagons[2]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[3]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[5]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[6]:SetEnds(EG:GetRandomEnds1())
	else
		EG.hexagons[1]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[2]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[6]:SetEnds(EG:GetRandomEnds1())
		EG.hexagons[7]:SetEnds(EG:GetRandomEnds1())
	end

end

function EndGenerator:lvl_1_3()

	for i = 1, 7 do
		
		EG.hexagons[i]:SetEnds({
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = false,
		[5] = false,
		[6] = false
		})
		
	end
	
	EG.hexagons[4]:SetEnds({
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[6] = true
		})
	
end

-- Does not work properly. 
function EndGenerator:GetConnections(i)

    print(string.format("EndGenerator:GetConnections Hexagon: %d", i))
	local connections = {}
	for index, connected in pairs(EG.hexagons[i].connected) do
		if connected and self.n_connects[i][index] then
			connections[index] = self.n_connects[i][index]
		end
	end

	return connections

end

function EndGenerator:GetNeighbors(i)

	if i == 1 then return {2,3,4}
	elseif i == 2 then return {1,4,5}
	elseif i == 3 then return {1,4,6}
	elseif i == 4 then return {1,2,3,5,6,7}
	elseif i == 5 then return {2,4,7}
	elseif i == 6 then return {3,4,7}
	elseif i == 7 then return {5,4,6} end
	
end

EG = EndGenerator()