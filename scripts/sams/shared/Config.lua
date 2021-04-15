
--	SAMs	--
SAMMissileMiniMapColor		=	Color(255, 0, 0, 255)	--	The Color of Missiles on the Minimap.	Default: Color(255, 0, 0, 255)
SAMMissileMiniMapRadius		=	2	--	The size of the missile dots on the Minimap.				Default: 2
SAMInteger					=	10	--	How quickly, in seconds, the SAMs can ire in succession.	Default: 15

DefaultSAMDistance			=	512	--	The default range at which SAMs will fire if no other distance is set.	Default: 512

--	SAM Display	--
SAMDisplayCountFontSize		=	12		--	The font size of the Nearby SAMs count display. 			Default: 12
SAMDisplayOffsetX			=	0.0675	--	The X Position of the Nearby SAMs count display.			Default: 0.0675
SAMDisplayOffsetY			=	0.001	--	The Y Position of the Nearby SAMs count display.			Default: 0.001
SAMDisplayColor				=	Color(250, 0, 0, 200)	--	The color of the Nearby SAMs count display.	Default: Color(250, 0, 0, 200)
SAMDisplayMiniMapColor		=	Color(255, 0, 0, 150)	--	The color of SAM Sites on the Minimap.		Default: Color(255, 0, 0, 150)

MissileSafetyCheckInteger	=	750	--	Milliseconds, a check to make sure the missiles don't explode at the SAM.	Default: 750

EffectTableExplosionMedium	=	{5, 15, 14, 168}	--	A list of Effects to randomly play when a missile explodes.
SAMMissileVehicles			=	{3, 14, 24, 30, 34, 37, 39, 51, 57, 59, 62, 64, 65, 67, 81, 85}	--	List of vehicle IDs that the SAMs will attack.
VehicleTablePlanes			=	{24, 30, 34, 39, 51, 59, 81, 85}	--	A list of planes, this is used to make identify planes because they operate differently than normal vehicles. Note: Plane IDs must be in both lists.

SAMChanceOfLootbox 			=   0.3

-- if Server and IsTest then
-- 	Events:Subscribe("PlayerChat", function(args)
-- 		local words = args.text:split(" ")
-- 		if words[1] == "/sam" then
-- 			local pos = args.player:GetPosition()
-- 			print(string.format("{pos = Vector3(%.3f, %.3f, %.3f), level = %d},", pos.x, pos.y, pos.z, tonumber(words[2])))
-- 		end
-- 	end)
-- end

SAMAnchorLocationsTable	=	{	--	Table of SAM Site Locations. By default this contains every game SAM position.
	--	Vector3() Position							Level
	{pos = Vector3(-4659.775, 436.1786, -11329.32),		level =	5},
	{pos = Vector3(-4548.567, 436.1786, -11462.71),		level =	5},
	{pos = Vector3(-5174.825, 406.3774, -11086.65),		level =	5},
	{pos = Vector3(-4383.365, 436.1786, -11572.44),		level =	5},
	{pos = Vector3(-525.1028, 870.2149, -8925.26),		level =	15},
	{pos = Vector3(-380.0317, 869.36, -8841.542),		level =	15},
	{pos = Vector3(83.36707, 1123.695, -9030.066),		level =	15},
	{pos = Vector3(2849.094, 1261.897, -3526.792),		level =	15},
	{pos = Vector3(2653.671, 1252.318, -3732.957),		level =	15},
	{pos = Vector3(3245.78, 1293.563, -3819.635),		level =	15},
	{pos = Vector3(6795.064, 765.0669, 1129.486),		level =	40},
	{pos = Vector3(7050.455, 765.1015, 944.6764),		level =	40},
	{pos = Vector3(13780.78, 277.8369, -2218.11),		level =	30},
	{pos = Vector3(13891.32, 289.7454, -2210.039),		level =	30},
	{pos = Vector3(13906.57, 289.7675, -2184.604),		level =	30},
	{pos = Vector3(-15609.37, 251.9828, 6115.474),		level =	10},
	{pos = Vector3(11477.48, 724.4874, 13254.61),		level =	15},
	{pos = Vector3(4739.614, 495.9766, -6937.865),		level =	15},
	{pos = Vector3(4857.271, 565.1467, -7075),			level =	15},
	{pos = Vector3(5067.218, 473.1975, -6901.771),		level =	15},
	-- {pos = Vector3(10796.79, 217.8569, 9880.224),		level =	DefaultSAMDistance},
	-- {pos = Vector3(10767.24, 217.8521, 9902.171),		level =	DefaultSAMDistance},
	-- {pos = Vector3(10787.12, 217.8521, 9928.937),		level =	DefaultSAMDistance},
	-- {pos = Vector3(10816.67, 217.8569, 9906.989),		level =	DefaultSAMDistance},
	{pos = Vector3(11401.22, 239.4852, -9336.36),		level =	15},
	{pos = Vector3(11590.93, 255.693, -9210.875),		level =	15},
	{pos = Vector3(11578.15, 263.5137, -9407.48),		level =	15},
	{pos = Vector3(11647.78, 265.1676, -9336.182),		level =	15},
	{pos = Vector3(2713.788, 205.3547, 9626.944),		level =	10},
	{pos = Vector3(2765.792, 209.124, 9541.033),		level =	10},
	{pos = Vector3(2701.329, 226.1177, 9358.852),		level =	10},
	{pos = Vector3(-14991.04, 204.4078, -2997.642),		level =	20},
	{pos = Vector3(-14916.84, 204.6508, -3167.888),		level =	25},
	{pos = Vector3(-14858.02, 204.4405, -3046.707),		level =	20},
	{pos = Vector3(-7079.433, 232.0128, -9829.144),		level =	10},
	{pos = Vector3(-7201.121, 210.7677, -9703.563),		level =	10},
	{pos = Vector3(9259.197, 220.4872, 1539.334),		level =	15},
	{pos = Vector3(9056.147, 220.0738, 1663.901),		level =	15},
	{pos = Vector3(9046.688, 213.5589, 1492.612),		level =	15},
	{pos = Vector3(9171.33, 204.5652, 1696.443),		level =	15},
	{pos = Vector3(-2998.62, 262.9386, 12697.54),		level =	15},
	{pos = Vector3(-3081.137, 271.0239, 12830.82),		level =	15},
	{pos = Vector3(-3050.321, 262.6185, 12737.91),		level =	15},
	{pos = Vector3(671.2063, 1221.022, -7105.562),		level =	15},
	{pos = Vector3(503.3108, 1204.668, -7317.253),		level =	15},
	{pos = Vector3(544.4595, 1221.072, -7009.75),		level =	15},
	{pos = Vector3(583.872, 1221.027, -7511.889),		level =	15},
	{pos = Vector3(-10524.57, 390.4442, 11247.7),		level =	30},
	{pos = Vector3(-10687.15, 394.0112, 11042.34),		level =	30},
	{pos = Vector3(-10801.85, 391.556, 11062.1),		level =	30},
	{pos = Vector3(-3485.709, 221.1376, 8958.863),		level =	15},
	{pos = Vector3(-3385.911, 210.4395, 8688.888),		level =	15},
	{pos = Vector3(-3263.935, 225.7167, 8910.087),		level =	15},
	{pos = Vector3(-15257.69, 251.9828, 6923.833),		level =	15},
	{pos = Vector3(-14373.4, 322.0326, 13471.85),		level =	20},
	{pos = Vector3(-14279.5, 322.055, 13566.11),		level =	20},
	{pos = Vector3(-13523.88, 211.8103, 6369.273),		level =	20},
	{pos = Vector3(-12508.98, 610.9288, 3795.679),		level =	20},
	{pos = Vector3(-12422.13, 610.9288, 3683.768),		level =	20},
	{pos = Vector3(-11065.97, 473.7153, 7378.612),		level =	30},
	{pos = Vector3(-10924.99, 473.7153, 7392.505),		level =	30},
	{pos = Vector3(-10855.32, 474.4781, 7422.284),		level =	30},
	{pos = Vector3(-10322.25, 424.6747, 8548.835),		level =	30},
	{pos = Vector3(-10540.1, 442.416, 8438.751),		level =	30},
	{pos = Vector3(-10526.23, 206.0639, 13206.19),		level =	35},
	{pos = Vector3(-10611.59, 212.0501, 13244.7),		level =	35},
	{pos = Vector3(-9562.876, 642.1549, 5626.811),		level =	30},
	{pos = Vector3(-9393.155, 640.0057, 5669.671),		level =	30},
	{pos = Vector3(-9616.441, 648.2173, 5593.273),		level =	30},
	{pos = Vector3(-8940.598, 487.4789, 2859.412),		level =	30},
	{pos = Vector3(-9035.163, 487.4789, 2964.892),		level =	30},
	{pos = Vector3(-8576.044, 241.353, 2262.41),		level =	30},
	{pos = Vector3(-8015.615, 389.8444, 10403.37),		level =	35},
	{pos = Vector3(-8159.589, 397.9672, 10432.82),		level =	35},
	{pos = Vector3(-7518.416, 251.9828, -15052.04),		level =	40},
	{pos = Vector3(-7621.366, 211.6543, -6977.385),		level =	5},
	{pos = Vector3(-7754.925, 212.1949, -7081.612),		level =	5},
	{pos = Vector3(-7443.321, 1132.451, 11579.12),		level =	35},
	{pos = Vector3(-6635.063, 1052.021, 12041.78),		level =	35},
	{pos = Vector3(-7371.581, 1125.235, 11414.1),		level =	35},
	{pos = Vector3(-6352.732, 1004.172, 12090.34),		level =	35},
	{pos = Vector3(-5380.346, 438.9595, -8043.604),		level =	5},
	{pos = Vector3(-5389.7, 438.9595, -8178.009),		level =	5},
	{pos = Vector3(-5366.693, 652.4413, 5768.205),		level =	30},
	{pos = Vector3(-5245.048, 652.4459, 5695.604),		level =	30},
	{pos = Vector3(-4813.61, 251.9828, -15348.95),		level =	20},
	{pos = Vector3(-4923.052, 251.9828, -1385.173),		level =	10},
	{pos = Vector3(-4834.065, 262.1581, 7645.048),		level =	30},
	{pos = Vector3(-4836.283, 262.1581, 7786.694),		level =	30},
	{pos = Vector3(-4722.702, 205.9518, 11705.39),		level =	25},
	{pos = Vector3(-4764.744, 211.963, 11979.17),		level =	25},
	{pos = Vector3(-4440.53, 211.7683, 11857.85),		level =	25},
	{pos = Vector3(-4430.792, 211.582, 11556.03),		level =	25},
	{pos = Vector3(-4070.142, 207.7141, 8769.459),		level =	25},
	{pos = Vector3(-4059.343, 207.7141, 8910.71),		level =	25},
	{pos = Vector3(-3233.716, 694.7837, -9571.863),		level =	15},
	{pos = Vector3(-3291.409, 694.2606, -9615.95),		level =	15},
	{pos = Vector3(-3221.875, 211.9413, -4865.603),		level =	10},
	{pos = Vector3(-3361.258, 213.4595, 2924.797),		level =	25},
	{pos = Vector3(-2696.559, 259.9925, 6364.776),		level =	25},
	{pos = Vector3(-2928.77, 259.9925, 6484.338),		level =	25},
	{pos = Vector3(-2222.569, 293.6588, 11328.13),		level =	25},
	{pos = Vector3(-2205.039, 293.9911, 11477.46),		level =	25},
	{pos = Vector3(-1326.413, 308.9647, 751.7111),		level =	40},
	{pos = Vector3(-1309.09, 220.9647, 1255.172),		level =	40},
	{pos = Vector3(-1221.785, 264.9647, 974.0831),		level =	40},
	{pos = Vector3(-1882.319, 221.0086, 1253.459),		level =	40},
	{pos = Vector3(-1968.641, 265.0086, 972.1267),		level =	40},
	{pos = Vector3(-1862.338, 309.0086, 750.7661),		level =	40},
	{pos = Vector3(-1920.26, 214.0778, 9898.595),		level =	25},
	{pos = Vector3(-547.2666, 206, -3686.618),			level =	10},
	{pos = Vector3(-381.4785, 205.7804, -3643.333),		level =	10},
	{pos = Vector3(-482.6035, 298.1913, 7065.995),		level =	20},
	{pos = Vector3(-129.6191, 298.1913, 7118.363),		level =	20},
	{pos = Vector3(16.28616, 1394.234, -6365.392),		level =	15},
	{pos = Vector3(222.4707, 1394.436, -6284.989),		level =	15},
	{pos = Vector3(883.7686, 315.4718, -4284.287),		level =	10},
	{pos = Vector3(763.791, 290.0749, 11687.93),		level =	25},
	{pos = Vector3(2987.174, 551.2951, -2090.396),		level =	15},
	{pos = Vector3(2654.53, 410.3524, -7307.716),		level =	15},
	{pos = Vector3(2951.847, 416.2963, -7348.376),		level =	15},
	{pos = Vector3(2669.632, 585.6035, -783.9144),		level =	20},
	{pos = Vector3(3118.44, 680.2819, -10073.98),		level =	20},
	{pos = Vector3(3708.143, 1348.311, -5485.354),		level =	15},
	{pos = Vector3(3910.432, 222.4238, 6082.855),		level =	20},
	{pos = Vector3(4285.574, 209.5282, -10752.7),		level =	15},
	{pos = Vector3(4805.512, 209.5282, -10564.31),		level =	15},
	{pos = Vector3(4784.656, 208.9482, -11166.56),		level =	15},
	{pos = Vector3(4209.518, 1242.23, -2880.915),		level =	15},
	{pos = Vector3(4333.325, 388.0483, 4221.154),		level =	15},
	{pos = Vector3(4737.416, 1653.897, -4712.747),		level =	15},
	{pos = Vector3(4760.714, 1653.892, -4741.774),		level =	15},
	{pos = Vector3(4737.914, 1653.892, -4838.944),		level =	15},
	{pos = Vector3(4650.688, 1653.897, -4805.242),		level =	15},
	{pos = Vector3(5813.913, 1217.086, -52.05369),		level =	15},
	{pos = Vector3(5428.965, 1213.945, 854.6379),		level =	15},
	{pos = Vector3(5436.845, 1204.452, 1019.775),		level =	15},
	{pos = Vector3(5361.736, 1210.863, 981.6267),		level =	15},
	{pos = Vector3(5396.211, 252.7453, 7198.714),		level =	25},
	{pos = Vector3(6086.67, 252.8248, 7116.824),		level =	25},
	{pos = Vector3(5688.252, 267.2821, 10329.18),		level =	25},
	{pos = Vector3(5649.596, 267.2821, 10381.35),		level =	25},
	{pos = Vector3(5759.857, 256.3261, 10279.31),		level =	25},
	{pos = Vector3(5804.684, 256.3261, 10201.67),		level =	25},
	{pos = Vector3(6907.859, 1454.761, -3511.132),		level =	15},
	{pos = Vector3(8215.817, 1007.174, -5899.041),		level =	15},
	{pos = Vector3(8355.253, 1007.96, -5902.733),		level =	15},
	{pos = Vector3(7743.768, 255.7462, 8386.69),		level =	25},
	{pos = Vector3(8278.404, 215.4288, 2317.558),		level =	15},
	{pos = Vector3(9093.504, 687.2934, 14793.47),		level =	30},
	{pos = Vector3(9108.792, 671.273, 15119.51),		level =	30},
	{pos = Vector3(9173.348, 674.1359, 14712.12),		level =	30},
	{pos = Vector3(9235.071, 661.7365, 15082.78),		level =	30},
	{pos = Vector3(8941.88, 675.2923, 15078.53),		level =	30},
	{pos = Vector3(9515.722, 237.6926, -13034.5),		level =	20},
	{pos = Vector3(9262.365, 237.9108, -12881.56),		level =	20},
	{pos = Vector3(9592.754, 207.6771, -11642.8),		level =	20},
	{pos = Vector3(9873.597, 207.6771, -11659.15),		level =	20},
	{pos = Vector3(9610.07, 227.4682, -10144.2),		level =	20},
	{pos = Vector3(9974.35, 251.9828, -14178.83),		level =	15},
	{pos = Vector3(9959.269, 214.0042, 14136.02),		level =	30},
	{pos = Vector3(9825.973, 224.2936, 14212),			level =	30},
	{pos = Vector3(11098.6, 261.7818, -7628.397),		level =	15},
	{pos = Vector3(11228.44, 401.9917, 995.4468),		level =	25},
	{pos = Vector3(11125.93, 411.8109, 852.0005),		level =	25},
	{pos = Vector3(11165.81, 313.0789, 13715),			level =	30},
	{pos = Vector3(11316.01, 313.0789, 13606.23),		level =	30},
	{pos = Vector3(11210.1, 312.6027, 13612.64),		level =	30},
	{pos = Vector3(11660.46, 547.9836, 14887.26),		level =	30},
	{pos = Vector3(11835.2, 548.8617, 15116.34),		level =	30},
	{pos = Vector3(12252.05, 520.3231, 15065.21),		level =	30},
	{pos = Vector3(12395.41, 920.1685, 11750.41),		level =	30},
	{pos = Vector3(12542.93, 908.4445, 11704.14),		level =	30},
	{pos = Vector3(12465.3, 899.4872, 11601.55),		level =	30},
	{pos = Vector3(12287.37, 621.7321, 14126.61),		level =	30},
	{pos = Vector3(12156.64, 635.3392, 14048.86),		level =	30},
	{pos = Vector3(13073.33, 251.9828, 4880.216),		level =	20},
	{pos = Vector3(12832.51, 597.3975, 12963.67),		level =	30},
	{pos = Vector3(12776.79, 609.3857, 12929.64),		level =	30},
	{pos = Vector3(12892.42, 597.3975, 12909.06),		level =	30},
	{pos = Vector3(13387.23, 251.9828, -13476.84),		level =	20},
	{pos = Vector3(13443.92, 251.9828, 8377.847),		level =	30},
	{pos = Vector3(13793, 211.3951, 10699.63),			level =	30},
	{pos = Vector3(13763.16, 222.6054, 10666.57),		level =	30},
	{pos = Vector3(13750.66, 221.6121, 10540.38),		level =	30},
	{pos = Vector3(14181.82, 531.9443, 12541.38),		level =	40},
	{pos = Vector3(14281.26, 539.044, 12389.23),		level =	40},
	{pos = Vector3(15011.06, 251.9828, -9062.239),		level =	20},
	{pos = Vector3(15502.23, 251.9828, -4296.45),		level =	30},
	-- Custom locations
	{pos = Vector3(-14065.509, 343.078, -14128.318), 	level = 50},
	{pos = Vector3(-14068.936, 343.074, -14169.393), 	level = 50},
	{pos = Vector3(-14114.133, 343.073, -14165.608), 	level = 50},
	{pos = Vector3(-14114.749, 343.070, -14125.079), 	level = 50},
	{pos = Vector3(-12082.625, 201.985, -14132.744), 	level = 50},
	{pos = Vector3(-12250.917, 201.837, -13466.148), 	level = 50},
	{pos = Vector3(-12360.998, 200.719, -12262.840), 	level = 50},
	{pos = Vector3(-13363.489, 369.301, -12149.785), 	level = 50},
	{pos = Vector3(-14668.455, 200.196, -11514.078), 	level = 50},
	{pos = Vector3(-15291.619, 267.212, -3047.666), 	level = 20},
	{pos = Vector3(-15239.429, 352.777, -2317.317), 	level = 20},
	{pos = Vector3(14130.785, 528.019, 14340.953), 		level = 40},
							}
					