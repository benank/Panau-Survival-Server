local ipairs, assert, tonumber = ipairs, assert, tonumber
local format, gmatch = string.format, string.gmatch
local char, byte = string.char, string.byte
local round, floor, log = math.round, math.floor, math.log
local concat, sort = table.concat, table.sort
local open, createdir = io.open, io.createdir
local config = config

createdir('cells')

local function checkNumber(bytes, n)
    assert(n >= 0, 'number must be positive')
    assert(n % 1 == 0, 'number must be an integer')
    assert(n < 2 ^ (bytes * 8), 'integer overflow')
end

local function writeByte(file, n)
	checkNumber(1, n)
    file:write(char(n))
end

local function writeShort(file, n)
	checkNumber(2, n)
    file:write(char(floor(n % 256), floor(n / 256 % 256)))
end

local function writeInt(file, n)
	checkNumber(3, n)
    file:write(char(floor(n % 256), floor(n / 256 % 256), floor(n / 65536 % 256), floor(n / 16777216 % 256)))
end

local function readByte(file)
    return file:read(1):byte()
end

local function readShort(file)
    local a, b = file:read(2):byte(1, 2)
    return a + 256 * b
end

local function readInt(file)
    local a, b, c, d = file:read(4):byte(1, 4)
    return a + 256 * b + 65536 * c + 16777216 * d
end

class 'TerrainMap'

function TerrainMap:__init()
	Network:Subscribe('TeleportToPosition', self, self.OnTeleportToPosition)
	Network:Subscribe('SaveCell', self, self.OnSaveCell)
	Network:Subscribe('LoadCell', self, self.OnLoadCell)
end

function TerrainMap:OnTeleportToPosition(args, sender)
	sender:SetPosition(args.position)
end

function TerrainMap:OnSaveCell(args, sender)

	local nodes = args.nodes

	if next(nodes) then

		local count = args.count
		local cell_x, cell_y = args.cell_x, args.cell_y
		local size, step = config.cell_size, config.xz_step

		local filename = format('cells/%s_%s.cell', cell_x, cell_y)
		local file = assert(open(filename, 'wb'))

		writeByte(file, cell_x)
		writeByte(file, cell_y)
		writeByte(file, log(size, 2))
		writeByte(file, log(step, 2))
		writeShort(file, count)

		print(cell_x, cell_y, size, step, count)

		for x, v in pairs(nodes) do
			for z, v in pairs(v) do
				for y, n in pairs(v) do
					writeByte(file, x)
					writeByte(file, z)
					writeShort(file, y)
					writeByte(file, n)
				end
			end
		end

		file:close()

	end

	self.cells = {}

	Network:Send(sender, 'CellSaved')

end

function TerrainMap:OnLoadCell(args, sender)

	local cell_x, cell_y = args.cell_x, args.cell_y
	local size, step = config.cell_size, config.xz_step

	local file = open(format('cells/%s_%s.cell', cell_x, cell_y), 'rb')
	local nodes

	if file then

		assert(readByte(file) == cell_x, 'Cell X mismatch')
		assert(readByte(file) == cell_y, 'Cell Y mismatch')

		assert(2^readByte(file) == size, 'Cell size mismatch')
		assert(2^readByte(file) == step, 'Node size mismatch')

		nodes = {}
		for i = 1, readShort(file) do
			nodes[i] = {
				readByte(file), -- x
				readByte(file), -- z
				readShort(file), -- y
				readByte(file) -- n
			}
		end

		file:close()

	end

	Network:Send(sender, 'CellLoaded', {
		cell_x = cell_x, cell_y = cell_y,
		nodes = nodes
	})

end

TerrainMap = TerrainMap()
