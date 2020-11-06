BlacklistedAreas = 
{
    {pos = Vector3(-10468.322266, 203.262085, -3469.024658), size = 20},
    {pos = Vector3(14134.099609, 332.878632, 14360.429688), size = 1000},
    {pos = Vector3(-13737.822266, 200.717514, 6303.510254), size = 500},
    -- Workbenches
    {pos = Vector3(4755.66, 572.124, 13219.67), size = 200},
    {pos = Vector3(11455.59, 444, -516.274), size = 200},
    {pos = Vector3(3018.479, 206.1557, -11952.077), size = 200},
    {pos = Vector3(-7116.8, 388.98, 2928.25), size = 200},
}

local blacklist = SharedObject.Create("BlacklistedAreas", {blacklist = BlacklistedAreas})

function IsInLocation(position, radius, locations)
    for _, location in pairs(locations) do
        if Distance2D(position, location.pos) < location.size + radius then
            return true
        end
    end
end

BlacklistedLandclaimAreas = 
{
    {pos = Vector3(-10468.322266, 203.262085, -3469.024658), size = 20},
    {pos = Vector3(-6643.242188, 208.981903, -3879.970947), size = 100},
    {pos = Vector3(-6370.579102, 208.933044, -3705.792236), size = 100},
    {pos = Vector3(14134.099609, 332.878632, 14360.429688), size = 1000},
    {pos = Vector3(-14136.325195, 322.804749, -14170.808594), size = 1000},
    {pos = Vector3(-13737.822266, 200.717514, 6303.510254), size = 500},
    {pos = Vector3(15233, 260, -13241), size = 800},
    -- Workbenches
    {pos = Vector3(4755.66, 572.124, 13219.67), size = 500},
    {pos = Vector3(11455.59, 444, -516.274), size = 500},
    {pos = Vector3(3018.479, 206.1557, -11952.077), size = 500},
    {pos = Vector3(-7116.8, 388.98, 2928.25), size = 500},

	{name = "Hantu Island", pos = Vector3(-13574, 322.14614868164, -13647), size = 2500},
	{name = "Pie Island", pos = Vector3(8068.52, 204.97, -15463.15), size = 100},
    {name = "Three Kings Hotel", pos = Vector3(-12638, 212.21321105957, 15134), size = 600},
    
	{name = "Paya Luas", pos = Vector3(12064, 206.14614868164, -10644), size = 1000},
	{name = "Lembah Delima", pos = Vector3(9573, 204.4068145752, 3882), size = 700},
	{name = "Kem Udara Wau Pantas", pos = Vector3(5816, 250.02824401855, 6918), size = 1000},
	{name = "Sungai Cengkih Besar", pos = Vector3(4556, 207.5669708252, -10778), size = 700},
	{name = "Gunung Lapik", pos = Vector3(3938, 221.12460327148, 6225), size = 300},
	{name = "Kampung Tujuh Telaga", pos = Vector3(660, 211.66394042969, 56), size = 500},
	{name = "Tanah Lebar", pos = Vector3(-284, 294.93728637695, 7110), size = 400},
	{name = "Sungai Jernih", pos = Vector3(-4061, 206.32719421387, 8853), size = 500},
	{name = "Banjaran Gundin", pos = Vector3(-4648, 426.14236450195, -11242), size = 600},
	{name = "Panau International Airport", pos = Vector3(-6600, 207.79737854004, -3549), size = 1200},
	{name = "Teluk Permata", pos = Vector3(-6893, 206.10333251953, -10588), size = 400},
	{name = "Kem Jalan Merpati", pos = Vector3(-6914, 1048.9885253906, 11840), size = 800},
	{name = "Pulau Dayang Terlena", pos = Vector3(-11876, 610.11431884766, 4836), size = 1000},
	{name = "Pulau Dongeng", pos = Vector3(5936, 256.53189086914, 10379), size = 500},
    {name = "Kem Sungai Sejuk", pos = Vector3(793, 294.32629394531, -3978), size = 700},
    {name = "Skull Island", pos = Vector3(-1549.777, 208.8105, 939.5184), size = 1200},
    {name = "Mile High Club", pos = Vector3(13200.32, 1082.615, -4948.071), size = 1000},
    {name = "Panau Falls Casino", pos = Vector3(2181.745, 645.841858, 1371.177), size = 800},
    {name = "PAN MILSAT", pos = Vector3(6923.709473, 716.891052, 1037.186035), size = 700},
    {name = "Panau City - Docks District", pos = Vector3(-15315.65, 202.9297, -2818.928), size = 1500},
    {name = "Panau City - Park District", pos = Vector3(-12667.85, 221.4292, -4854.635), size = 2300},
    {name = "Panau City - Residential District", pos = Vector3(-12686.05, 203.1647, -884.1532), size = 1300},
    {name = "Panau City - Financial District", pos = Vector3(-10307.16, 203.1312, -3048.375), size = 4500},
    {name = "southeast", pos = Vector3(7014.197754, 202.400650, 11358.232422), size = 1600},
    {name = "Cape Carnival", pos = Vector3(13788.11, 222.02, -2315.564), size = 1000},
    {name = "Rajang Temple", pos = Vector3(-4325.442383, 522.054871, 6872.331543), size = 700},
    {name = "Rajang Temple 2", pos = Vector3(-5317.500977, 371.916443, 7072.631348), size = 500},
    {name = "Rajang Temple 3", pos = Vector3(-6820.670898, 307.657806, 7017.214355), size = 1100},
    {name = "Rajang Temple 4", pos = Vector3(-5831.668457, 325.149200, 7107.842285), size = 600},
    {name = "Rajang Temple 5", pos = Vector3(-7527.525391, 230.853607, 6758.383789), size = 500},
    {name = "Rajang Temple 6", pos = Vector3(-7789.388672, 249.171066, 6151.741211), size = 300},
    {name = "Bandar Baru Nipah", pos = Vector3(-499.1229, 242.4776, -12096.36), size = 700},
    {name = "Road", pos = Vector3(-6637.08, 228.56, -6060.33), size = 400},
    {name = "Road", pos = Vector3(-6455.04, 222.34, -6560.96), size = 400},
    {name = "Road", pos = Vector3(-6090.95, 232.36, -6667.15), size = 400},
    {name = "Road", pos = Vector3(-5696.52, 251.42, -6606.47), size = 400},
    {name = "Road", pos = Vector3(-5362.77, 268.35, -6409.25), size = 400},
    {name = "Road", pos = Vector3(-4754.46, 289.37, -6376.03), size = 400},
    {name = "Road", pos = Vector3(-4922.83, 270.57, -6121.02), size = 400},
    {name = "Road", pos = Vector3(-4209.82, 320.22, -5999.65), size = 400},
    {name = "Road", pos = Vector3(-3800.22, 330.19, -5772.10), size = 400},
    {name = "Road", pos = Vector3(-3405.79, 329.32, -5681.08), size = 400},
    {name = "Road", pos = Vector3(-3026.53, 291.60, -5499.03), size = 400},
    {name = "Road", pos = Vector3(-2495.57, 253.82, -5256.30), size = 400},
    {name = "Road", pos = Vector3(-2101.14, 255.04, -5119.77), size = 400},
    {name = "Road", pos = Vector3(-1539.84, 237.47, -4831.53), size = 400},
    {name = "Road", pos = Vector3(-1706.71, 207.24, -4300.57), size = 400},
    {name = "Road", pos = Vector3(-1099.90, 218.87, -4179.21), size = 400},
    {name = "Road", pos = Vector3(-659.96, 235.44, -3815.12), size = 400},
    {name = "Road", pos = Vector3(-189.67, 221.59, -3981.99), size = 400},
    {name = "Road", pos = Vector3(-6925.32, 222.06, -6667.15), size = 400},
    {name = "Road", pos = Vector3(-6394.36, 273.77, -6970.56), size = 400},
    {name = "Road", pos = Vector3(-5984.76, 241.25, -6272.72), size = 400},
    {name = "Road", pos = Vector3(-6546.06, 267.29, -7122.26), size = 400},
    {name = "Road", pos = Vector3(-6606.74, 275.36, -7744.25), size = 400},
    {name = "Road", pos = Vector3(-6606.74, 301.00, -8153.85), size = 400},
    {name = "Road", pos = Vector3(-6910.15, 290.61, -8745.49), size = 400},
    {name = "Road", pos = Vector3(-6743.27, 261.85, -9291.62), size = 400},
    {name = "Road", pos = Vector3(-6166.80, 306.41, -9716.39), size = 400},
    {name = "Road", pos = Vector3(-6197.14, 268.04, -10399.06), size = 400},
    {name = "Road", pos = Vector3(-6439.87, 259.48, -10839.00), size = 400},
    {name = "Road", pos = Vector3(-6606.74, 218.55, -11430.65), size = 400},
    {name = "Road", pos = Vector3(-6045.44, 295.15, -11460.99), size = 400},
    {name = "Road", pos = Vector3(-5954.41, 304.48, -10854.17), size = 400},
    {name = "Road", pos = Vector3(-5666.18, 355.98, -11294.11), size = 400},
    {name = "Road", pos = Vector3(-5332.43, 395.00, -11294.11), size = 400},
    {name = "Road", pos = Vector3(-7175.50, 204.34, -6330.17), size = 400},
    {name = "Road", pos = Vector3(-6181.97, 290.75, -10065.31), size = 400}
}
