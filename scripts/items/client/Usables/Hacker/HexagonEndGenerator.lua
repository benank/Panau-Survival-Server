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
        
    -- Number of ends that should be used for connecting
    -- Like for middle, only a max of 5 should be used, not 6
    self.num_viable_ends = 
    {
        [1] = 3,
        [2] = 3,
        [3] = 3,
        [4] = 5,
        [5] = 3,
        [6] = 3,
        [7] = 3
    }

	--  2 1
	-- 5 4 3
	--  7 6 

    self.hexagons = {}

    -- Number of connections that each difficulty level can have
    self.difficulty_num_connects = -- Max connections = 12
    {
        [1] = {min = 2, max = 3}, -- Easiest difficulty
        [2] = {min = 4, max = 5},
        [3] = {min = 6, max = 9} -- Hardest difficulty
    }
	
end

function EndGenerator:GetMaxEnds(index)
    return count_table(self.n_connects[index])
end

function EndGenerator:GenerateEnds(difficulty, hexagons)

    self.hexagons = hexagons
    self.num_connects = math.random(self.difficulty_num_connects[difficulty].min, self.difficulty_num_connects[difficulty].max)
    
    local current_hexagon = 4 -- Start with the middle

    local total_num_connects = 0
    while total_num_connects < self.num_connects do

        -- First, find a hexagon with at least one end open
        while self.hexagons[current_hexagon]:GetNumEnds() >= math.random(self.num_viable_ends[current_hexagon]) do
            current_hexagon = math.random(7)
        end

        local side = random_table_key(self.n_connects[current_hexagon])

        -- Now, find the open end on that hexagon
        while EG.hexagons[current_hexagon].ends[side] do
            side = random_table_key(self.n_connects[current_hexagon])
        end

        self.hexagons[current_hexagon].ends[side] = true

        local connected_hexagon = self.n_connects[current_hexagon][side]
        local connected_side = nil

        for side, connected in pairs(self.n_connects[connected_hexagon]) do
            if connected == current_hexagon then
                connected_side = side
                break
            end
        end

        self.hexagons[connected_hexagon].ends[connected_side] = true

        --current_hexagon = connected_hexagon
        current_hexagon = math.random(7)

        total_num_connects = total_num_connects + 1

    end

    for i = 1, 7 do
        self.hexagons[i]:Initialize()
    end

    return self.hexagons

end

function EndGenerator:GetConnections(i)

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