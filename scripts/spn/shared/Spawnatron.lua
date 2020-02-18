class 'Spawnatron'
class 'SpawnatronEntry'

function SpawnatronEntry:__init( model_id, price, entry_type )
    self.model_id = model_id
    self.price = price
    self.entry_type = entry_type
end



function SpawnatronEntry:GetPrice()
    return self.price
end

function SpawnatronEntry:GetModelId()
    return self.model_id
end

function SpawnatronEntry:GetListboxItem()
    return self.listbox_item
end

function SpawnatronEntry:SetListboxItem( item )
    self.listbox_item = item
end

class 'VehicleSpawnatronEntry' (SpawnatronEntry)

function VehicleSpawnatronEntry:__init( model_id, price )
    SpawnatronEntry.__init( self, model_id, price, 1 )
end

function VehicleSpawnatronEntry:GetName()
    return Vehicle.GetNameByModelId( self.model_id )
end

---------------------vik---------------------------------------
class 'StaticObjectSpawnatronEntry' (SpawnatronEntry)

function StaticObjectSpawnatronEntry:__init( model_id, price, model, collision, name )
    SpawnatronEntry.__init( self, model_id, price, 1 )
	self.model 		= model
	self.collision 	= collision
	self.name 		= name
end

function StaticObjectSpawnatronEntry:GetModel()
    return self.model
end

function StaticObjectSpawnatronEntry:GetCollision()
    return self.collision
end

function StaticObjectSpawnatronEntry:GetName()
    return self.name
end

-----------------------------------------------------------------

class 'WeaponSpawnatronEntry' (SpawnatronEntry)

function WeaponSpawnatronEntry:__init( model_id, price, slot, name )
    SpawnatronEntry.__init( self, model_id, price, 2 )
    self.slot = slot
    self.name = name
end

function WeaponSpawnatronEntry:GetSlot()
    return self.slot
end

function WeaponSpawnatronEntry:GetName()
    return self.name
end

class 'ModelSpawnatronEntry' (SpawnatronEntry)

function ModelSpawnatronEntry:__init( model_id, price, name )
    SpawnatronEntry.__init( self, model_id, price, 2 )
    self.name = name
end

function ModelSpawnatronEntry:GetName()
    return self.name
end

function Spawnatron:CreateItems()
    self.types = {
        ["Vehicle"] = 1,
        ["Weapon"] = 2,
        ["Model"] = 3,
		["StaticObject"] = 4
    }

    self.id_types = {}

    for k, v in pairs(self.types) do
        self.id_types[v] = k
    end
	-- populated on start
    self.items = {
        [self.types.Vehicle] = {
            { "Civilian", "Sports", "Bikes", "Offroad", "Trucks/LGV", "Military (Ground)", "Planes", "Helicopters", "Boats" },
            ["Civilian"] = {
				VehicleSpawnatronEntry( 20, 0 ),
                VehicleSpawnatronEntry( 58, 0 ),
                VehicleSpawnatronEntry( 75, 0 ),
                VehicleSpawnatronEntry( 82, 0 ),
				VehicleSpawnatronEntry( 8, 0 ),
				VehicleSpawnatronEntry( 9, 0 ),
				VehicleSpawnatronEntry( 15, 0 ),
                VehicleSpawnatronEntry( 22, 0 ),
				VehicleSpawnatronEntry( 23, 0 ),
				VehicleSpawnatronEntry( 26, 0 ),
				VehicleSpawnatronEntry( 29, 0 ),
				VehicleSpawnatronEntry( 60, 0 ),
				VehicleSpawnatronEntry( 63, 0 ),
				VehicleSpawnatronEntry( 68, 0 ),
				VehicleSpawnatronEntry( 70, 0 ),
				VehicleSpawnatronEntry( 73, 0 )
                -- DLC
            },
			["Sports"] = {
                VehicleSpawnatronEntry( 2, 0 ),
				VehicleSpawnatronEntry( 7, 0 ),
                VehicleSpawnatronEntry( 54, 0 ),
				VehicleSpawnatronEntry( 55, 0 ),
                VehicleSpawnatronEntry( 78, 0 ),
				VehicleSpawnatronEntry( 91, 0 ),
			},
			["Bikes"] = {
                VehicleSpawnatronEntry( 21, 0 ),
				VehicleSpawnatronEntry( 32, 0 ),
                VehicleSpawnatronEntry( 43, 0 ),
				VehicleSpawnatronEntry( 44, 0 ),
				VehicleSpawnatronEntry( 47, 0 ),
				VehicleSpawnatronEntry( 61, 0 ),
				VehicleSpawnatronEntry( 74, 0 ),
				VehicleSpawnatronEntry( 83, 0 ),
                VehicleSpawnatronEntry( 89, 0 ),
				VehicleSpawnatronEntry( 90, 0 ),
			},
			["Offroad"] = {
				VehicleSpawnatronEntry( 1, 0 ),
				VehicleSpawnatronEntry( 10, 0 ),
                VehicleSpawnatronEntry( 11, 0 ),
                VehicleSpawnatronEntry( 13, 0 ),
				VehicleSpawnatronEntry( 33, 0 ),
				VehicleSpawnatronEntry( 36, 0 ),
				VehicleSpawnatronEntry( 52, 0 ),
				VehicleSpawnatronEntry( 84, 0 ),
				VehicleSpawnatronEntry( 86, 0 ),
			},
			["Trucks/LGV"] = {
                VehicleSpawnatronEntry( 4, 0 ),
				VehicleSpawnatronEntry( 12, 0 ),
				VehicleSpawnatronEntry( 40, 0 ),
				VehicleSpawnatronEntry( 41, 0 ),
				VehicleSpawnatronEntry( 42, 0 ),
				VehicleSpawnatronEntry( 49, 0 ),
				VehicleSpawnatronEntry( 66, 0 ),
				VehicleSpawnatronEntry( 71, 0 ),
                VehicleSpawnatronEntry( 76, 0 ),
                VehicleSpawnatronEntry( 79, 0 ),
			},
			["Military (Ground)"] = {
				VehicleSpawnatronEntry( 18, 0 ),
				VehicleSpawnatronEntry( 31, 0 ),
                VehicleSpawnatronEntry( 35, 0 ),
				VehicleSpawnatronEntry( 46, 0 ),
				VehicleSpawnatronEntry( 48, 0 ),
				VehicleSpawnatronEntry( 56, 0 ),
                VehicleSpawnatronEntry( 72, 0 ),
                VehicleSpawnatronEntry( 77, 0 ),
                VehicleSpawnatronEntry( 87, 0 ),
			},
            ["Boats"] = {
                VehicleSpawnatronEntry( 5, 0 ),
				VehicleSpawnatronEntry( 6, 0 ),
                VehicleSpawnatronEntry( 16, 0 ),
				VehicleSpawnatronEntry( 19, 0 ),
                VehicleSpawnatronEntry( 25, 0 ),
                VehicleSpawnatronEntry( 27, 0 ),
                VehicleSpawnatronEntry( 28, 0 ),
				VehicleSpawnatronEntry( 38, 0 ),
				VehicleSpawnatronEntry( 45, 0 ),
				VehicleSpawnatronEntry( 50, 0 ),
                VehicleSpawnatronEntry( 69, 0 ),
                VehicleSpawnatronEntry( 80, 0 ),
                VehicleSpawnatronEntry( 88, 0 ),
                -- DLC
                VehicleSpawnatronEntry( 53, 0 )
            },

            ["Planes"] = {
                VehicleSpawnatronEntry( 30, 0 ),
				VehicleSpawnatronEntry( 34, 0 ),
				VehicleSpawnatronEntry( 39, 0 ),
				VehicleSpawnatronEntry( 51, 0 ),
				VehicleSpawnatronEntry( 57, 0 ),
				VehicleSpawnatronEntry( 59, 0 ),
                VehicleSpawnatronEntry( 81, 0 ),
                VehicleSpawnatronEntry( 85, 0 ),
                -- DLC
                VehicleSpawnatronEntry( 24, 0 )
            },
			["Helicopters"] = {
				VehicleSpawnatronEntry( 3, 0 ),
				VehicleSpawnatronEntry( 14, 0 ),
				VehicleSpawnatronEntry( 37, 0 ),
				VehicleSpawnatronEntry( 62, 0 ),
                VehicleSpawnatronEntry( 64, 0 ),
				VehicleSpawnatronEntry( 65, 0 ),
				VehicleSpawnatronEntry( 67, 0 ),
			}
        },
		[self.types.StaticObject] = {
				{ "Lootboxes", "Buildings", "Dev34 Menu", "Trees", "Plants & Bushes", "Interior Design", "Interior Decorating"},
                ["Lootboxes"] = {
                    StaticObjectSpawnatronEntry( 20, 0, "f1m03airstrippile07.eez/go164_01-a.lod", "f1m03airstrippile07.eez/go164_01_lod1-a_col.pfx", "Lootbox 1" ),
                    StaticObjectSpawnatronEntry( 20, 0, "mod.heavydrop.beretta.eez/wea00-b.lod", "mod.heavydrop.beretta.eez/wea00_lod1-b_col.pfx", "Lootbox 2" ),
                    StaticObjectSpawnatronEntry( 20, 0, "km05_01.seq.blz/go164_01-g.lod", "km05_01.seq.blz/go164_01_lod1-b_col.pfx", "Lootbox 3" ),
                    StaticObjectSpawnatronEntry( 20, 0, "mod.heavydrop.assault.eez/wea00-a.lod", "mod.heavydrop.assault.eez/wea00_lod1-a_col.pfx", "Lootbox 4" ),
                    StaticObjectSpawnatronEntry( 20, 0, "pickup.boost.vehicle.eez/pu02-a.lod", "37x10.flz/go061_lod1-e_col.pfx", "Lootbox 5" ),
                    
                
                },
                ["Buildings"] = {
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb084-a.lod", "gb084_lod1-a_col.pfx", "Wooden 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-a.lod", "gb090_lod1-a_col.pfx", "Hangar 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-b.lod", "gb090_lod1-b_col.pfx", "Hangar 1 Back" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-c.lod", "gb090_lod1-c_col.pfx", "Carpark with roof" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-d.lod", "gb090_lod1-d_col.pfx", "Chimney Large" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-e.lod", "gb090_lod1-e_col.pfx", "Concrete small shed" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-f.lod", "gb090_lod1-f_col.pfx", "Generator" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-g.lod", "gb090_lod1-g_col.pfx", "Container" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-i.lod", "gb090_lod1-i_col.pfx", "Pillar 3" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-j.lod", "gb090_lod1-j_col.pfx", "Pillar 5" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-k.lod", "gb090_lod1-k_col.pfx", "Pillar 4" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-m.lod", "gb090_lod1-m_col.pfx", "Pillar 6" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb102-a.lod", "gb102_lod1-a_col.pfx", "Wooden 2" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb102-b.lod", "gb102_lod1-b_col.pfx", "Wooden 3" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb128-d.lod", "gb128_lod1-d_col.pfx", "Part With Arch" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb181-a.lod", "gb181_lod1-a_col.pfx", "Small Tower Half" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-b.lod", "gb133_lod1-b_col.pfx", "House 2" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-c.lod", "gb133_lod1-c_col.pfx", "Roof Banana 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-d.lod", "gb133_lod1-d_col.pfx", "Roof Banana 2" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-e.lod", "gb133_lod1-e_col.pfx", "Roof Banana 3" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-f.lod", "gb133_lod1-f_col.pfx", "Roof Banana 4" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-g.lod", "gb133_lod1-g_col.pfx", "Roof Banana 5" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-i.lod", "gb133_lod1-i_col.pfx", "Roof Banana small 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-j.lod", "gb133_lod1-j_col.pfx", "Roof Banana small 2" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-k.lod", "gb133_lod1-k_col.pfx", "Roof Banana small 3" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-l.lod", "gb133_lod1-l_col.pfx", "Roof Banana small 4" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-m.lod", "gb133_lod1-m_col.pfx", "Roof Banana small 5" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb133-o.lod", "gb133_lod1-o_col.pfx", "Fence Wooden" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb109-a.lod", "gb109_lod1-a_col.pfx", "House 3" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb185-f.lod", "gb185_lod1-f_col.pfx", "Fence Small 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb185-h.lod", "gb185_lod1-h_col.pfx", "House 4" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb185-i.lod", "gb185_lod1-i_col.pfx", "Platform Wooden small" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb185-j.lod", "gb185_lod1-j_col.pfx", "Stairs Wooden 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb226-k.lod", "gb226_lod1-k_col.pfx", "Platform wooden stage 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb226-k2.lod", "gb226_lod1-k2_col.pfx", "Platform wooden stage 2" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb226-l.lod", "gb226_lod1-l_col.pfx", "Platform wooden stage 3" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb226-m.lod", "gb226_lod1-m_col.pfx", "Platform wooden stage 4" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb226-n.lod", "gb226_lod1-n_col.pfx", "Railing wooden 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-a.lod", "gb202_lod1-a_col.pfx", "Desert House 1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-b.lod", "gb202_lod1-b_col.pfx", "Desert House 2" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-c.lod", "gb202_lod1-c_col.pfx", "Desert House 3" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-d.lod", "gb202_lod1-d_col.pfx", "Desert House 4" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-e.lod", "gb202_lod1-e_col.pfx", "Desert House 5" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-f.lod", "gb202_lod1-f_col.pfx", "Desert House 6" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-g.lod", "gb202_lod1-g_col.pfx", "Desert House 6" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-h.lod", "gb202_lod1-h_col.pfx", "Desert House 7" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-i.lod", "gb202_lod1-i_col.pfx", "Desert Tower Half" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-i2_1.lod", "gb202_lod1-i2_1_col.pfx", "Desert Tower Top" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb202-o.lod", "gb202_lod1-o_col.pfx", "Pillar Wooden 3" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/gb242-a.lod", "gb242_lod1-a_col.pfx", "Hangar 2" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb006-a.lod", "gb006_lod1-a_col.pfx", "Military Octogon" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb006-d.lod", "gb006_lod1-d_col.pfx", "Military Octogon Railing" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb106-n.lod", "gb106_lod1-n_col.pfx", "Wall 2 Small" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb106-o.lod", "gb106_lod1-o_col.pfx", "Wall 2 Corner Small" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb106-p.lod", "gb106_lod1-p_col.pfx", "Wall 2 Gate Small" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb245-d.lod","areaset01.blz/gb245_lod1-d_col.pfx", "Runway Material1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km06.base.flz/key015_01-g.lod","km06.base.flz/key015_01_lod1-g_col.pfx", "Plaza1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb245-d.lod","areaset01.blz/gb245_lod1-d_col.pfx", "Runway Material1" )

            },
			["Dev34 Menu"] = {
                StaticObjectSpawnatronEntry( 20, 0, "go225-a.lod", "go225_lod1-a_col.pfx", "Nothing here yet" ),
                StaticObjectSpawnatronEntry( 20, 0, "mod.heavydrop.assault.eez/wea00-a.lod", "mod.heavydrop.assault.eez/wea00_lod1-a_col.pfx", "Lvl3 Box" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.silotallshort.b.eez/key014_01-z.lod", "km07.silotallshort.b.eez/key014_01_lod1-z_col.pfx", "Hell Cell Structure" ),
				StaticObjectSpawnatronEntry( 20, 0, "f3m04.rocket01.eez/key016_01-p1.lod", "f3m04.rocket01.eez/key016_01_lod1-p1_col.pfx", "Rocket" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-s.lod", "km07.submarine.eez/key014_02_lod1-s_col.pfx", "Test1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb090-d.lod", "areaset01.blz/gb090_lod1-d_col.pfx", "Long Pillar(Hell Cell)" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-u.lod", "km07.submarine.eez/key014_02_lod1-u_col.pfx", "Submarine Door" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/muzzle-muzzle.lod", "general.blz/muzzle_lod1-muzzle_col.pfx", "Little Sun" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb211-g.lod", "areaset05.blz/gb211_lod1-g_col.pfx", "Fancier Prison Cell Strucutre" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-u.lod", "km07.submarine.eez/key014_02_lod1-u_col.pfx", "Submarine Door" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb211-j.lod", "areaset05.blz/gb211_lod1-j_col.pfx", "Skyhold Floor?" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07.spawnablecover.eez/go300-d.lod", "f1m07.spawnablecover.eez/go300_lod1-d_col.pfx", "Gray matter wall" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_res_t3-v3a.lod", "areaset13.blz/cs_res_t4_lod1-v3a_col.pfx", "Large Ground Area w/ Fence" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_hw-pillarwbase.lod", "areaset13.blz/cs_hw_lod1-pillarwbase_col.pfx", "Cement Pillar" ),
				StaticObjectSpawnatronEntry( 20, 0, "19x18.flz/gb097-b.lod", "19x18.flz/gb097_lod1-b_col.pfx", "Half of large strudture" ),
				StaticObjectSpawnatronEntry( 20, 0, "24x22.flz/key042_1-part_d1.lod", "24x22.flz/key042_1_lod1-part_d1_col.pfx", "Transparent Water Sheet" ),
				StaticObjectSpawnatronEntry( 20, 0, "24x22.flz/key042_1-part_a.lod", "24x22.flz/key042_1_lod1-part_a_col.pfx", "Mansion Exterior" ),
				StaticObjectSpawnatronEntry( 20, 0, "24x22.flz/key042_1-part_b.lod", "24x22.flz/key042_1_lod1-part_b_col.pfx", "Mansion Interior" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go043-j_on.lod", "40x11.flz/go043_lod1-j_on_col.pfx", "Red Light" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go122-b.lod", "40x11.flz/go122_lod1-b_col.pfx", "Gov't Seal" ),
				StaticObjectSpawnatronEntry( 20, 0, "cch00.blz/go244-go244_lights.lod", "cch00.blz/go244_lod1-go244_lights_col.pfx", "White Light Circle" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_comt1-v4a.lod", "areaset13.blz/cs_comt1_lod1-v4a_col.pfx", "HeliPad Floor Tile" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_signs-v4.lod", "areaset13.blz/cs_signs_lod1-v4_col.pfx", "Floor Tile/Water collision?" ),
				StaticObjectSpawnatronEntry( 20, 0, "kanttest.flz/kanttest-a.lod", "kanttest.flz/kanttest_lod1-a_col.pfx", "Runway w/ nums" ),
				StaticObjectSpawnatronEntry( 20, 0, "11x50_reapershqdemo.flz/key041_1-key041_1_interior.lod", "11x50_reapershqdemo.flz/key041_1_lod1-key041_1_interior_col.pfx", "Interior Reaper Base" ),
				StaticObjectSpawnatronEntry( 20, 0, "11x50_reapershqdemo.flz/key041_1-key041_1_exterior.lod", "11x50_reapershqdemo.flz/key041_1_lod1-key041_1_exterior_col.pfx", "Exterior Reaper Base" ),
				StaticObjectSpawnatronEntry( 20, 0, "11x50_reapershqdemo.flz/key041_1-key041_1_door.lod", "11x50_reapershqdemo.flz/key041_1_lod1-key041_1_door_col.pfx", "Door Reaper Base" ),
				StaticObjectSpawnatronEntry( 20, 0, "11x50_reapershqdemo.flz/key041_1-key041_1_rockpile.lod", "11x50_reapershqdemo.flz/key041_1_lod1-key041_1_rockpile_col.pfx", "Rockpile Reaperbase" ),
				StaticObjectSpawnatronEntry( 20, 0, "11x50_reapershqdemo.flz/key041_1-key041_1_rock_04.lod", "11x50_reapershqdemo.flz/key041_1_lod1-key041_1_rock_04_col.pfx", "Single Rock Reaper Base" ),
				StaticObjectSpawnatronEntry( 20, 0, "18x35.flz/go070-w.lod", "18x35.flz/go070_lod1-w_col.pfx", "Elevated Wooden Walkway" ),
				StaticObjectSpawnatronEntry( 20, 0, "34x09.flz/gb028-f.lod", "34x09.flz/gb028_lod1-f_col.pfx", "Giant Rectangle Building Bland" ),
				StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/gb206-c.lod", "37x10.flz/gb206_lod1-c_col.pfx", "Straighter Building Material" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go022-l.lod", "40x11.flz/go022_lod1-l_col.pfx", "Granite Wall" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go173-f.lod", "40x11.flz/go173_lod1-f_col.pfx", "Metal Stairway" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb245-d.lod", "areaset01.blz/gb245_lod1-d_col.pfx", "Big Stone Flooring" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset04.blz/go232-b.lod", "areaset04.blz/go232_lod1-b_col.pfx", "Army Netting Hut" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/halo_01-a.lod", "general.blz/halo_01_lod1-a_col.pfx", "Bright Light" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/wea51-a.lod", "general.blz/wea51_lod1-a_col.pfx", "White Missile Medium" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb245-d.lod","areaset01.blz/gb245_lod1-d_col.pfx", "Runway Material1" ),
				StaticObjectSpawnatronEntry( 20, 0, "53x19.flz/key001_03-f.lod","53x19.flz/key001_03_lod1-f_col.pfx", "Turn Doors" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m03emp.flz/go246-e3.lod","40x11.flz/go043_lod1-j_on_col.pfx", "Blue Light" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001-o.lod","f1m07milehigh.flz/key001_lod1-o_col.pfx", "Pink TV" ),
				StaticObjectSpawnatronEntry( 20, 0, "24x22.flz/key042_1-part_d1.lod","53x19.flz/key001_03_lod1-f_col.pfx", "Water Sheet" ),
				StaticObjectSpawnatronEntry( 20, 0, "f2s01.seq.blz/v062cutscene_ular-heli.lod","f2s01.seq.blz/v062cutscene_ular-heli_col.pfx", "Def Heli?" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset01.blz/gb245-a.lod","areaset01.blz/gb245_lod1-a_col.pfx", "Dragrace Side Panelling" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05.hotelbuilding01.flz/key030_01-l.lod","km05.hotelbuilding01.flz/key030_01_lod1-l_col.pfx", "Dragrace Elevator" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05.hotelbuilding01.flz/key030_01-p.lod","km05.hotelbuilding01.flz/key030_01_lod1-p_col.pfx", "Dragrace Bigger Lights" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb211-e.lod", "gb211_lod1-e_col.pfx", "Dragrace Starting Lanes" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb165-k.lod", "gb165_lod1-k_col.pfx", "Dragrace Starting Lanes Railing" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_rest5-d1.lod", "areaset13.blz/cs_rest5_lod1-d1_col.pfx", "Dragrace Long Wall" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_channeltiles-fill.lod", "areaset13.blz/cs_channeltiles_lod1-fill_col.pfx", "Dragrace Vertical Wall" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_rest5-d3.lod", "areaset13.blz/cs_rest5_lod1-d3_col.pfx", "Dragrace Shorter Wall" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_traffic_light-b.lod", "areaset13.blz/cs_traffic_light_lod1-b_col.pfx", "Dragrace Traffic Poles" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m03airstrippile07.eez/go164_01-a.lod", "f1m03airstrippile07.eez/go164_01_lod1-a_col.pfx", "Lootbox Small" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m03.interiors.flz/key_003-s5.lod", "f1m03.interiors.flz/key_003_lod1-s5_col.pfx", "Airport Runway" ),
				StaticObjectSpawnatronEntry( 20, 0, "km02.towercomplex.flz/key013_01-g.lod", "km02.towercomplex.flz/key013_01_lod1-g_col.pfx", "Glass Window" ),
				StaticObjectSpawnatronEntry( 20, 0, "f2m07.researchfacility.flz/key028_01-s.lod", "f2m07.researchfacility.flz/key028_01_lod1-s_col.pfx", "Dragrace Bigger Lights" ),
				StaticObjectSpawnatronEntry( 20, 0, "pickup.boost.vehicle.eez/pu02-a.lod", "37x10.flz/go061_lod1-e_col.pfx", "Survival Dropbox" ),
				StaticObjectSpawnatronEntry( 20, 0, "f2m07.ice.flz/key028_02-i.lod", "f2m07.ice.flz/key028_02_lod1-i_col.pfx", "Ice" ),
				StaticObjectSpawnatronEntry( 20, 0, "22x19.flz/wea34-f.lod", "22x19.flz/wea34_lod1-f_col.pfx", "Turret Cannon For Automation" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07.bomb.eez/gp040-a.lod", "f1m07.bomb.eez/gp040_lod1-a_col.pfx", "Hellfire1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_roof_propps-v3a.lod", "areaset13.blz/cs_roof_propps_lod1-v3a_col.pfx", "Solar Panels" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-gold.lod", "km07.submarine.eez/key014_02_lod1-gold_col.pfx", "Pile of Wealth" ),
				StaticObjectSpawnatronEntry( 20, 0, "f2m05.stffront.flz/gb002-e.lod", "f2m05.stffront.flz/gb002_lod1-e_col.pfx", "cCrafting Table1" ),
				StaticObjectSpawnatronEntry( 20, 0, "city.district.a1.houses.flz/go166_01-d.lod", "city.district.a1.houses.flz/go166_01_lod1-d_col.pfx", "Crafting Table/Storage" ),
				StaticObjectSpawnatronEntry( 20, 0, "km06.base.flz/key015_01-i.lod", "km06.base.flz/key015_01_lod1-i_col.pfx", "Faction War Base Wall w/ Door" ),
				StaticObjectSpawnatronEntry( 20, 0, "km06.base.flz/key015_01-g.lod", "km06.base.flz/key015_01_lod1-g_col.pfx", "Faction War Base Prop1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km06.base.flz/key015_01-d.lod", "km06.base.flz/key015_01_lod1-d_col.pfx", "Faction War Base Floor1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km06.base.flz/key015_01-j.lod", "km06.base.flz/key015_01_lod1-j_col.pfx", "Faction War Base Wall Door" ),
				StaticObjectSpawnatronEntry( 20, 0, "km06.base.flz/key015_01-y1.lod", "km06.base.flz/key015_01_lod1-y1_col.pfx", "Faction War Base Prop2" ),
				StaticObjectSpawnatronEntry( 20, 0, "city.harbor.a1.flz/gb500-a.lod", "city.harbor.a1.flz/gb500_lod1-a_col.pfx", "Ship Part1" ),
				StaticObjectSpawnatronEntry( 20, 0, "city.harbor.a1.flz/gb500-b.lod", "city.harbor.a1.flz/gb500_lod1-b_col.pfx", "Ship Part2" ),
				StaticObjectSpawnatronEntry( 20, 0, "city.harbor.a1.flz/gb500-c.lod", "city.harbor.a1.flz/gb500_lod1-c_col.pfx", "Ship Part3" ),
				StaticObjectSpawnatronEntry( 20, 0, "city.harbor.a1.flz/gb087-f_dst3.lod", "city.harbor.a1.flz/gb087_lod1-f_dst3_col.pfx", "Long Chimney w/ lights" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1s02.base.flz/gb004-g.lod", "f1s02.base.flz/gb004_lod1-g_col.pfx", "Player House Exterior1" ),
				StaticObjectSpawnatronEntry( 20, 0, "key001-a.lod", "key001_lod1-a_col.pfx", "Mile High Big Part" ),
				StaticObjectSpawnatronEntry( 20, 0, "04x40.flz/gb221-b.lod", "04x40.flz/gb221_lod1-b_col.pfx", "Windmill Blades" ),
				StaticObjectSpawnatronEntry( 20, 0, "11x57.flz/wea34-d.lod", "11x57.flz/wea34_lod1-d_col.pfx", "Turret Gun" ),
				StaticObjectSpawnatronEntry( 20, 0, "Cool Parachute", "general.blz/gae03-gae03.lod", "general.blz/gae03_lod1-gae03_col.pfx" ),
				StaticObjectSpawnatronEntry( 20, 0, "vegetation_3.blz/City_b07_BasePlanter2X28-Whole.lod", "vegetation_3.blz/City_b07_BasePlanter2X28_lod1-Whole_col.pfx", "PlantGrass" ),
				StaticObjectSpawnatronEntry( 20, 0, "vegetation_3.blz/City_b01_streethedgeL-Whole.lod", "vegetation_3.blz/City_b01_streethedgeL-Whole_COL.pfx", "PlantGrass2" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_gt-culdesac_d.lod", "areaset13.blz/cs_gt_lod1-culdesac_d_col.pfx", "PlantGrass3" ),
				StaticObjectSpawnatronEntry( 20, 0, "bwc.flz/v320-body.lod", "bwc.flz/v320_lod1-body_col.pfx", "pz_Whale" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/turret-barrel.lod", "general.blz/turret_lod1-barrel_col.pfx", "pz_DecentCannon" ),
				StaticObjectSpawnatronEntry( 20, 0, "lave.v012_military_tank_small.eez/v012-weaponmg.lod", "lave.v012_military_tank_small.eez/v012_lod1-weaponmg_col.pfx", "pz_Cannon Smaller" ),
				StaticObjectSpawnatronEntry( 20, 0, "lave.v012_military_tank_small.eez/v012-weapon.lod", "lave.v012_military_tank_small.eez/v012_lod1-weapon_col.pfx", "pz_Cannon Bigger" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/wea16-wea16_02.lod", "general.blz/wea16_lod1-wea16_02_col.pfx", "__launcherprojectile" ),
				StaticObjectSpawnatronEntry( 20, 0, "seve.v082_motorboat_standard_small.eez/v082-body_m.lod", "seve.v082_motorboat_standard_small.eez/v082-body_m_col.pfx", "_djonk2" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/rotor1-rotorblurred4.lod", "general.blz/rotor1_lod1-rotorblurred4_col.pfx", "Heli_rotorsblurred" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/rotor1-rotorstill4.lod", "general.blz/rotor1_lod1-rotorstill4_col.pfx", "Heli_Rotors" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/rotor1-rotoraxel.lod", "general.blz/rotor1_lod1-rotoraxel_col.pfx", "Heli_AxleBigger" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/rotor1-axelsmall.lod", "general.blz/rotor1_lod1-axelsmall_col.pfx", "Heli_Axle" ),
				StaticObjectSpawnatronEntry( 20, 0, "f3s01.seq.blz/v062cutscene_reap-heli.lod", "f3s01.seq.blz/v062cutscene_reap_lod1-heli_col.pfx", "Heli_reaper" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				
			
			},

			["Trees"] = {
              StaticObjectSpawnatronEntry( 20, 0, "vegetation_0.blz/Jungle_B01_BananaM-Stump.lod", "Jungle_B01_BananaM-Stump_COL.pfx", "Banana 1 Stump" ),
				StaticObjectSpawnatronEntry( 65192, 0, "vegetation_0.blz/Jungle_B01_BananaM-Whole.lod", "Jungle_B01_BananaM-Whole_COL.pfx", "Banana 1" ),
				StaticObjectSpawnatronEntry( 65193, 0, "vegetation_0.blz/Jungle_B02_BananaM-Stump.lod", "Jungle_B02_BananaM-Stump_COL.pfx", "Banana 2 Stump" ),
				StaticObjectSpawnatronEntry( 65194, 0, "vegetation_0.blz/Jungle_B02_BananaM-Whole.lod", "Jungle_B02_BananaM-Whole_COL.pfx", "Banana 2" ),
				StaticObjectSpawnatronEntry( 65195, 0, "vegetation_3.blz/City_T14_SideWalkM-Stump.lod", "City_T14_SideWalkM-Stump_COL.pfx", "Generic 11 Stump" ),
				StaticObjectSpawnatronEntry( 65196, 0, "vegetation_3.blz/City_T14_SideWalkM-Trunk.lod", "City_T14_SideWalkM-Trunk_COL.pfx", "Generic 11 Trunk" ),
				StaticObjectSpawnatronEntry( 65197, 0, "vegetation_3.blz/City_T14_SideWalkM-Whole.lod", "City_T14_SideWalkM-Whole_COL.pfx", "Generic 11" ),
				StaticObjectSpawnatronEntry( 65198, 0, "vegetation_3.blz/City_T15_SideWalkM-Stump.lod", "City_T15_SideWalkM-Stump_col.pfx", "Generic 10 Stump" ),
				StaticObjectSpawnatronEntry( 65199, 0, "vegetation_3.blz/City_T15_SideWalkM-Trunk.lod", "City_T15_SideWalkM-Trunk_COL.pfx", "Generic 10 Trunk" ),
				StaticObjectSpawnatronEntry( 65200, 0, "vegetation_3.blz/City_T15_SideWalkM-Whole.lod", "City_T15_SideWalkM-Whole_COL.pfx", "Generic 10" ),
				StaticObjectSpawnatronEntry( 65201, 0, "vegetation_0.blz/Jungle_B11_understoryM-Stump.lod", "Jungle_B11_understoryM-Stump_COL.pfx", "Generic 8 Stump" ),
				StaticObjectSpawnatronEntry( 65202, 0, "vegetation_0.blz/Jungle_B11_understoryM-TrunkA.lod", "Jungle_B11_understoryM-TrunkA_COL.pfx", "Generic 9 Trunka" ),
				StaticObjectSpawnatronEntry( 65203, 0, "vegetation_0.blz/Jungle_B11_understoryM-TrunkB.lod", "Jungle_B11_understoryM-TrunkB_COL.pfx", "Generic 9 Trunkb" ),
				StaticObjectSpawnatronEntry( 65204, 0, "vegetation_0.blz/Jungle_B11_understoryM-Whole.lod", "Jungle_B11_understoryM-Whole_COL.pfx", "Generic 9" ),
				StaticObjectSpawnatronEntry( 65205, 0, "vegetation_0.blz/Jungle_B12_understoryL-Stump.lod", "Jungle_B12_understoryL-Stump_COL.pfx", "Generic 8 Stump" ),
				StaticObjectSpawnatronEntry( 65206, 0, "vegetation_0.blz/Jungle_B12_understoryL-TrunkA.lod", "Jungle_B12_understoryL-TrunkA_COL.pfx", "Generic 8 Trunka" ),
				StaticObjectSpawnatronEntry( 65207, 0, "vegetation_0.blz/Jungle_B12_understoryL-TrunkB.lod", "Jungle_B12_understoryL-TrunkB_COL.pfx", "Generic 8 Trunkb" ),
				StaticObjectSpawnatronEntry( 65208, 0, "vegetation_0.blz/Jungle_B12_understoryL-TrunkC.lod", "Jungle_B12_understoryL-TrunkC_COL.pfx", "Generic 8 Trunkc" ),
				StaticObjectSpawnatronEntry( 65209, 0, "vegetation_0.blz/Jungle_B12_understoryL-Whole.lod", "Jungle_B12_understoryL-Whole_COL.pfx", "Generic 8" ),
				StaticObjectSpawnatronEntry( 65210, 0, "vegetation_0.blz/Jungle_B13_understoryS-Whole.lod", "Jungle_B13_understoryS-Whole_COL.pfx", "Generic 7" ),
				StaticObjectSpawnatronEntry( 65211, 0, "vegetation_0.blz/Jungle_B14_understoryXS-whole.lod", "Jungle_B14_understoryXS-whole_COL.pfx", "Generic 6" ),
				StaticObjectSpawnatronEntry( 65212, 0, "vegetation_0.blz/Jungle_G21_DeadTreeM-Whole.lod", "Jungle_G21_DeadTreeM-Whole_COL.pfx", "Dead 1" ),
				StaticObjectSpawnatronEntry( 65213, 0, "vegetation_0.blz/Jungle_G22_DeadTreeM-Whole.lod", "Jungle_G22_DeadTreeM-Whole_COL.pfx", "Dead 2" ),
				StaticObjectSpawnatronEntry( 65214, 0, "vegetation_0.blz/Jungle_G26_StumpM-Whole.lod", "Jungle_G26_StumpM-Whole_COL.pfx", "Stump Large 1" ),
				StaticObjectSpawnatronEntry( 65215, 0, "vegetation_0.blz/Jungle_G27_StumpM-Whole.lod", "Jungle_G27_StumpM-Whole_COL.pfx", "Stump Large 2" ),
				StaticObjectSpawnatronEntry( 65216, 0, "vegetation_0.blz/Jungle_G28_StumpL-Whole.lod", "Jungle_G28_StumpL-Whole_COL.pfx", "Stump Large 3" ),
				StaticObjectSpawnatronEntry( 65217, 0, "vegetation_0.blz/Jungle_T01_CanopyM-Whole.lod", "Jungle_T01_CanopyM-Whole_COL.pfx", "Canopy 1" ),
				StaticObjectSpawnatronEntry( 65218, 0, "vegetation_0.blz/Jungle_T02_CanopyM-Whole.lod", "Jungle_T02_CanopyM-Whole_COL.pfx", "Canopy 2" ),
				StaticObjectSpawnatronEntry( 65219, 0, "vegetation_0.blz/Jungle_T03_CanopyL-Whole.lod", "Jungle_T03_CanopyL-Whole_COL.pfx", "Canopy 3" ),
				StaticObjectSpawnatronEntry( 65220, 0, "vegetation_0.blz/Jungle_T04_EmergentM-Whole.lod", "Jungle_T04_EmergentM-Whole_COL.pfx", "Generic No Leaves" ),
				StaticObjectSpawnatronEntry( 65221, 0, "vegetation_0.blz/jungle_T06_understoryM-Stump.lod", "jungle_T06_understoryM-Stump_COL.pfx", "Generic 5 Stump" ),
				StaticObjectSpawnatronEntry( 65222, 0, "vegetation_0.blz/jungle_T06_understoryM-TrunkA.lod", "jungle_T06_understoryM-TrunkA_COL.pfx", "Generic 5 Trunk" ),
				StaticObjectSpawnatronEntry( 65223, 0, "vegetation_0.blz/jungle_T06_understoryM-whole.lod", "jungle_T06_understoryM-whole_COL.pfx", "Generic 5" ),
				StaticObjectSpawnatronEntry( 65224, 0, "vegetation_0.blz/jungle_T07_understoryL-Stump.lod", "jungle_T07_understoryL-Stump_COL.pfx", "Generic 4 Stump" ),
				StaticObjectSpawnatronEntry( 65225, 0, "vegetation_0.blz/jungle_T07_understoryL-TrunkA.lod", "jungle_T07_understoryL-TrunkA_COL.pfx", "Generic 4 Trunk" ),
				StaticObjectSpawnatronEntry( 65226, 0, "vegetation_0.blz/jungle_T07_understoryL-whole.lod", "jungle_T07_understoryL-whole_COL.pfx", "Generic 4" ),
				StaticObjectSpawnatronEntry( 65227, 0, "vegetation_0.blz/jungle_T08_understoryL-Stump.lod", "jungle_T08_understoryL-Stump_COL.pfx", "Generic 3 Stump" ),
				StaticObjectSpawnatronEntry( 65228, 0, "vegetation_0.blz/jungle_T08_understoryL-TrunkA.lod", "jungle_T08_understoryL-TrunkA_COL.pfx", "Generic 3 Trunk" ),
				StaticObjectSpawnatronEntry( 65229, 0, "vegetation_0.blz/jungle_T08_understoryL-TrunkB.lod", "jungle_T08_understoryL-TrunkB_COL.pfx", "Generic 3 Trunk" ),
				StaticObjectSpawnatronEntry( 65230, 0, "vegetation_0.blz/jungle_T08_understoryL-TrunkC.lod", "jungle_T08_understoryL-TrunkC_COL.pfx", "Generic 3 Trunk" ),
				StaticObjectSpawnatronEntry( 65231, 0, "vegetation_0.blz/jungle_T08_understoryL-Whole.lod", "jungle_T08_understoryL-Whole_COL.pfx", "Generic 3" ),
				StaticObjectSpawnatronEntry( 65232, 0, "vegetation_0.blz/jungle_T09_understoryXL-Whole.lod", "jungle_T09_understoryXL-Whole_COL.pfx", "Generic 2" ),
				StaticObjectSpawnatronEntry( 65233, 0, "vegetation_0.blz/jungle_T10_understoryS-Stump.lod", "jungle_T10_understoryS-Stump_COL.pfx", "Generic 1 Stump" ),
				StaticObjectSpawnatronEntry( 65234, 0, "vegetation_0.blz/jungle_T10_understoryS-TrunkA.lod", "jungle_T10_understoryS-TrunkA_COL.pfx", "Generic 1 Trunk" ),
				StaticObjectSpawnatronEntry( 65235, 0, "vegetation_0.blz/jungle_T10_understoryS-TrunkB.lod", "jungle_T10_understoryS-TrunkB_COL.pfx", "Generic 1 Trunk" ),
				StaticObjectSpawnatronEntry( 65236, 0, "vegetation_0.blz/jungle_T10_understoryS-TrunkC.lod", "jungle_T10_understoryS-TrunkC_COL.pfx", "Generic 1 Trunk" ),
				StaticObjectSpawnatronEntry( 65237, 0, "vegetation_0.blz/jungle_T10_understoryS-Whole.lod", "jungle_T10_understoryS-Whole_COL.pfx", "Generic 1" ),
				StaticObjectSpawnatronEntry( 65238, 0, "vegetation_0.blz/jungle_T11_palmS-Stump.lod", "jungle_T11_palmS-Stump_COL.pfx", "Palm 10 Stump" ),
				StaticObjectSpawnatronEntry( 65239, 0, "vegetation_0.blz/jungle_T11_palmS-TrunkA.lod", "jungle_T11_palmS-TrunkA_COL.pfx", "Palm 10 Trunk" ),
				StaticObjectSpawnatronEntry( 65240, 0, "vegetation_0.blz/jungle_T11_palmS-Whole.lod", "jungle_T11_palmS-Whole_COL.pfx", "Palm 10" ),
				StaticObjectSpawnatronEntry( 65241, 0, "vegetation_0.blz/jungle_T12_palmM-Stump.lod", "jungle_T12_palmM-Stump_COL.pfx", "Palm 9 Stump" ),
				StaticObjectSpawnatronEntry( 65242, 0, "vegetation_0.blz/jungle_T12_palmM-TrunkA.lod", "jungle_T12_palmM-TrunkA_COL.pfx", "Palm 9 Trunk" ),
				StaticObjectSpawnatronEntry( 65243, 0, "vegetation_0.blz/jungle_T12_palmM-Whole.lod", "jungle_T12_palmM-Whole_COL.pfx", "Palm 9" ),
				StaticObjectSpawnatronEntry( 65244, 0, "vegetation_0.blz/jungle_T13_palmL-Stump.lod", "jungle_T13_palmL-Stump_COL.pfx", "Palm 8 Stump" ),
				StaticObjectSpawnatronEntry( 65245, 0, "vegetation_0.blz/jungle_T13_palmL-TrunkA.lod", "jungle_T13_palmL-TrunkA_COL.pfx", "Palm 8 Trunk" ),
				StaticObjectSpawnatronEntry( 65246, 0, "vegetation_0.blz/jungle_T13_palmL-Whole.lod", "jungle_T13_palmL-Whole_COL.pfx", "Palm 8" ),
				StaticObjectSpawnatronEntry( 65247, 0, "vegetation_0.blz/jungle_T14_palmCLS-Stump.lod", "jungle_T14_palmCLS-Stump_COL.pfx", "Palm 7 Stump" ),
				StaticObjectSpawnatronEntry( 65248, 0, "vegetation_0.blz/jungle_T14_palmCLS-TrunkA.lod", "jungle_T14_palmCLS-TrunkA_COL.pfx", "Palm 7 Trunka" ),
				StaticObjectSpawnatronEntry( 65249, 0, "vegetation_0.blz/jungle_T14_palmCLS-TrunkB.lod", "jungle_T14_palmCLS-TrunkB_COL.pfx", "Palm 7 Trunkb" ),
				StaticObjectSpawnatronEntry( 65250, 0, "vegetation_0.blz/jungle_T14_palmCLS-Whole.lod", "jungle_T14_palmCLS-Whole_COL.pfx", "Palm 7" ),
				StaticObjectSpawnatronEntry( 65251, 0, "vegetation_0.blz/jungle_T15_palmCLM-Stump.lod", "jungle_T15_palmCLM-Stump_COL.pfx", "Palm 6 Stump" ),
				StaticObjectSpawnatronEntry( 65252, 0, "vegetation_0.blz/jungle_T15_palmCLM-TrunkA.lod", "jungle_T15_palmCLM-TrunkA_COL.pfx", "Palm 6 Trunka" ),
				StaticObjectSpawnatronEntry( 65253, 0, "vegetation_0.blz/jungle_T15_palmCLM-TrunkB.lod", "jungle_T15_palmCLM-TrunkB_COL.pfx", "Palm 6 Trunkb" ),
				StaticObjectSpawnatronEntry( 65254, 0, "vegetation_0.blz/jungle_T15_palmCLM-TrunkC.lod", "jungle_T15_palmCLM-TrunkC_COL.pfx", "Palm 6 Trunkc" ),
				StaticObjectSpawnatronEntry( 65255, 0, "vegetation_0.blz/jungle_T15_palmCLM-Whole.lod", "jungle_T15_palmCLM-Whole_COL.pfx", "Palm 6" ),
				StaticObjectSpawnatronEntry( 65256, 0, "vegetation_0.blz/jungle_T16_palmCLL-Stump.lod", "jungle_T16_palmCLL-Stump_COL.pfx", "Palm 5 Stump" ),
				StaticObjectSpawnatronEntry( 65257, 0, "vegetation_0.blz/jungle_T16_palmCLL-TrunkA.lod", "jungle_T16_palmCLL-TrunkA_COL.pfx", "Palm 5 Trunka" ),
				StaticObjectSpawnatronEntry( 65258, 0, "vegetation_0.blz/jungle_T16_palmCLL-TrunkB.lod", "jungle_T16_palmCLL-TrunkB_COL.pfx", "Palm 5 Trunkb" ),
				StaticObjectSpawnatronEntry( 65259, 0, "vegetation_0.blz/jungle_T16_palmCLL-TrunkC.lod", "jungle_T16_palmCLL-TrunkC_COL.pfx", "Palm 5 Trunkc" ),
				StaticObjectSpawnatronEntry( 65260, 0, "vegetation_0.blz/jungle_T16_palmCLL-Whole.lod", "jungle_T16_palmCLL-Whole_COL.pfx", "Palm 5" ),
				StaticObjectSpawnatronEntry( 65261, 0, "vegetation_0.blz/jungle_T17_ThaiPalmM-Stump.lod", "jungle_T17_ThaiPalmM-Stump_COL.pfx", "Palm 4 Stump" ),
				StaticObjectSpawnatronEntry( 65262, 0, "vegetation_0.blz/jungle_T17_ThaiPalmM-TrunkA.lod", "jungle_T17_ThaiPalmM-TrunkA_COL.pfx", "Palm 4 Trunk" ),
				StaticObjectSpawnatronEntry( 65263, 0, "vegetation_0.blz/jungle_T17_ThaiPalmM-Whole.lod", "jungle_T17_ThaiPalmM-Whole_COL.pfx", "Palm 4" ),
				StaticObjectSpawnatronEntry( 65264, 0, "vegetation_0.blz/jungle_T18_ThaiPalmS-Stump.lod", "jungle_T18_ThaiPalmS-Stump_COL.pfx", "Palm 3 Stump" ),
				StaticObjectSpawnatronEntry( 65265, 0, "vegetation_0.blz/jungle_T18_ThaiPalmS-TrunkA.lod", "jungle_T18_ThaiPalmS-TrunkA_COL.pfx", "Palm 3 Trunk" ),
				StaticObjectSpawnatronEntry( 65266, 0, "vegetation_0.blz/jungle_T18_ThaiPalmS-Whole.lod", "jungle_T18_ThaiPalmS-Whole_COL.pfx", "Palm 3" ),
				StaticObjectSpawnatronEntry( 65267, 0, "vegetation_0.blz/jungle_T19_ThaiPalmL-Stump.lod", "jungle_T19_ThaiPalmL-Stump_COL.pfx", "Palm 2 Stump" ),
				StaticObjectSpawnatronEntry( 65268, 0, "vegetation_0.blz/jungle_T19_ThaiPalmL-TrunkA.lod", "jungle_T19_ThaiPalmL-TrunkA_COL.pfx", "Palm 2 Trunk" ),
				StaticObjectSpawnatronEntry( 65269, 0, "vegetation_0.blz/jungle_T19_ThaiPalmL-Whole.lod", "jungle_T19_ThaiPalmL-Whole_COL.pfx", "Palm 2" ),
				StaticObjectSpawnatronEntry( 65270, 0, "vegetation_0.blz/jungle_T20_ThaiPalmXL-Stump.lod", "jungle_T20_ThaiPalmXL-Stump_COL.pfx", "Palm 1 Stump" ),
				StaticObjectSpawnatronEntry( 65271, 0, "vegetation_0.blz/jungle_T20_ThaiPalmXL-TrunkA.lod", "jungle_T20_ThaiPalmXL-TrunkA_COL.pfx", "Palm 1 Trunk" ),
				StaticObjectSpawnatronEntry( 65272, 0, "vegetation_0.blz/jungle_T20_ThaiPalmXL-Whole.lod", "jungle_T20_ThaiPalmXL-Whole_COL.pfx", "Palm 1" ),
				StaticObjectSpawnatronEntry( 65273, 0, "vegetation_1.blz/Arctic_G10_logL-TrunkA.lod", "Arctic_G10_logL-TrunkA_COL.pfx", "Dry Fallen Trunk" ),
				StaticObjectSpawnatronEntry( 65274, 0, "vegetation_1.blz/Arctic_G10_logL-Whole.lod", "Arctic_G10_logL-Whole_COL.pfx", "Dry Fallen" ),
				StaticObjectSpawnatronEntry( 65275, 0, "vegetation_1.blz/Arctic_T20_PineS-Stump.lod", "Arctic_T20_PineS-Stump_COL.pfx", "Pine 3 Stump" ),
				StaticObjectSpawnatronEntry( 65276, 0, "vegetation_1.blz/Arctic_T20_PineS-TrunkA.lod", "Arctic_T20_PineS-TrunkA_COL.pfx", "Pine 3 Trunk" ),
				StaticObjectSpawnatronEntry( 65277, 0, "vegetation_1.blz/Arctic_T20_PineS-Whole.lod", "Arctic_T20_PineS-Whole_COL.pfx", "Pine 3" ),
				StaticObjectSpawnatronEntry( 65278, 0, "vegetation_1.blz/Arctic_T21_PineM-Stump.lod", "Arctic_T21_PineM-Stump_COL.pfx", "Pine 2 Stump" ),
				StaticObjectSpawnatronEntry( 65279, 0, "vegetation_1.blz/Arctic_T21_PineM-TrunkA.lod", "Arctic_T21_PineM-TrunkA_COL.pfx", "Pine 2 Trunk" ),
				StaticObjectSpawnatronEntry( 65280, 0, "vegetation_1.blz/Arctic_T21_PineM-Whole.lod", "Arctic_T21_PineM-Whole_COL.pfx", "Pine 2" ),
				StaticObjectSpawnatronEntry( 65281, 0, "vegetation_1.blz/Arctic_T22_PineL-Stump.lod", "Arctic_T22_PineL-Stump_COL.pfx", "Pine 1 Stump" ),
				StaticObjectSpawnatronEntry( 65282, 0, "vegetation_1.blz/Arctic_T22_PineL-TrunkA.lod", "Arctic_T22_PineL-TrunkA_COL.pfx", "Pine 1 Trunk" ),
				StaticObjectSpawnatronEntry( 65283, 0, "vegetation_1.blz/Arctic_T22_PineL-Whole.lod", "Arctic_T22_PineL-Whole_COL.pfx", "Pine 1" ),
				StaticObjectSpawnatronEntry( 65284, 0, "vegetation_1.blz/Arctic_T26_bushtreeM-Stump.lod", "Arctic_T26_bushtreeM-Stump_COL.pfx", "Bushtree 3 Stump" ),
				StaticObjectSpawnatronEntry( 65285, 0, "vegetation_1.blz/Arctic_T26_bushtreeM-TrunkA.lod", "Arctic_T26_bushtreeM-TrunkA_COL.pfx", "Bushtree 3 Trunka" ),
				StaticObjectSpawnatronEntry( 65286, 0, "vegetation_1.blz/Arctic_T26_bushtreeM-TrunkB.lod", "Arctic_T26_bushtreeM-TrunkB_COL.pfx", "Bushtree 3 Trunka" ),
				StaticObjectSpawnatronEntry( 65287, 0, "vegetation_1.blz/Arctic_T26_bushtreeM-Whole.lod", "Arctic_T26_bushtreeM-Whole_COL.pfx", "Bushtree 3" ),
				StaticObjectSpawnatronEntry( 65288, 0, "vegetation_1.blz/Arctic_T27_bushtreeS-Stump.lod", "Arctic_T27_bushtreeS-Stump_COL.pfx", "Bushtree 2 Stump" ),
				StaticObjectSpawnatronEntry( 65289, 0, "vegetation_1.blz/Arctic_T27_bushtreeS-TrunkA.lod", "Arctic_T27_bushtreeS-TrunkA_COL.pfx", "Bushtree 2 Trunka" ),
				StaticObjectSpawnatronEntry( 65290, 0, "vegetation_1.blz/Arctic_T27_bushtreeS-TrunkB.lod", "Arctic_T27_bushtreeS-TrunkB_COL.pfx", "Bushtree 2 Trunkb" ),
				StaticObjectSpawnatronEntry( 65291, 0, "vegetation_1.blz/Arctic_T27_bushtreeS-Whole.lod", "Arctic_T27_bushtreeS-Whole_COL.pfx", "Bushtree 2" ),
				StaticObjectSpawnatronEntry( 65292, 0, "vegetation_1.blz/Arctic_T28_bushtreeL-Stump.lod", "Arctic_T28_bushtreeL-Stump_COL.pfx", "Bushtree 1 Stump" ),
				StaticObjectSpawnatronEntry( 65293, 0, "vegetation_1.blz/Arctic_T28_bushtreeL-TrunkA.lod", "Arctic_T28_bushtreeL-TrunkA_COL.pfx", "Bushtree 1 Trunka" ),
				StaticObjectSpawnatronEntry( 65294, 0, "vegetation_1.blz/Arctic_T28_bushtreeL-TrunkB.lod", "Arctic_T28_bushtreeL-TrunkB_COL.pfx", "Bushtree 1 Trunkb" ),
				StaticObjectSpawnatronEntry( 65295, 0, "vegetation_1.blz/Arctic_T28_bushtreeL-TrunkC.lod", "Arctic_T28_bushtreeL-TrunkC_COL.pfx", "Bushtee 1 Trunkc" ),
				StaticObjectSpawnatronEntry( 65296, 0, "vegetation_1.blz/Arctic_T28_bushtreeL-Whole.lod", "Arctic_T28_bushtreeL-Whole_COL.pfx", "Bushtree 1" ),
				StaticObjectSpawnatronEntry( 65297, 0, "vegetation_2.blz/City_T01_SakuraL-Stump.lod", "City_T01_SakuraL-Stump_COL.pfx", "Sakura 4 Stump" ),
				StaticObjectSpawnatronEntry( 65298, 0, "vegetation_2.blz/City_T01_SakuraL-TrunkA.lod", "City_T01_SakuraL-TrunkA_COL.pfx", "Sakura 4 Trunk" ),
				StaticObjectSpawnatronEntry( 65299, 0, "vegetation_2.blz/City_T01_SakuraL-Whole.lod", "City_T01_SakuraL-Whole_COL.pfx", "Sakura 4" ),
				StaticObjectSpawnatronEntry( 65300, 0, "vegetation_2.blz/City_T02_SakuraM-Stump.lod", "City_T02_SakuraM-Stump_COL.pfx", "Sakura 3 Stump" ),
				StaticObjectSpawnatronEntry( 65301, 0, "vegetation_2.blz/City_T02_SakuraM-TrunkA.lod", "City_T02_SakuraM-TrunkA_COL.pfx", "Sakura 3 Trunk" ),
				StaticObjectSpawnatronEntry( 65302, 0, "vegetation_2.blz/City_T02_SakuraM-Whole.lod", "City_T02_SakuraM-Whole_COL.pfx", "Sakura 3" ),
				StaticObjectSpawnatronEntry( 65303, 0, "vegetation_2.blz/City_T03_SakuraS-Stump.lod", "City_T03_SakuraS-Stump_COL.pfx", "Sakura 2 Stump" ),
				StaticObjectSpawnatronEntry( 65304, 0, "vegetation_2.blz/City_T03_SakuraS-TrunkA.lod", "City_T03_SakuraS-TrunkA_COL.pfx", "Sakura 2 Trunk" ),
				StaticObjectSpawnatronEntry( 65305, 0, "vegetation_2.blz/City_T03_SakuraS-Whole.lod", "City_T03_SakuraS-Whole_COL.pfx", "Sakura 2" ),
				StaticObjectSpawnatronEntry( 65306, 0, "vegetation_2.blz/City_T04_SakuraL-Stump.lod", "City_T04_SakuraL-Stump_COL.pfx", "Sakura 1 Stump" ),
				StaticObjectSpawnatronEntry( 65307, 0, "vegetation_2.blz/City_T04_SakuraL-TrunkA.lod", "City_T04_SakuraL-TrunkA_COL.pfx", "Sakura 1 Trunk" ),
				StaticObjectSpawnatronEntry( 65308, 0, "vegetation_2.blz/City_T04_SakuraL-Whole.lod", "City_T04_SakuraL-Whole_COL.pfx", "Sakura 1" ),
			},

			["Plants & Bushes"] = {
               	StaticObjectSpawnatronEntry( 65309, 0, "seve.v089_raceboat.eez/v089-body_m.lod", "seve.v089_raceboat.eez/v089-body_m_COL.pfx", "Boat1" ),
               	StaticObjectSpawnatronEntry( 65309, 0, "City_B10_roofbush-Whole.lod", "City_B10_roofbush-Whole_COL.pfx", "RoofBush 1" ),
				StaticObjectSpawnatronEntry( 65310, 0, "City_B11_roofbush-Whole.lod", "City_B11_roofbush-Whole_COL.pfx", "RoofBush 2" ),
				StaticObjectSpawnatronEntry( 65311, 0, "Jungle_B03_SnakeplantM-Whole.lod", "Jungle_B03_SnakeplantM-Whole_COL.pfx", "Plant Snakeplant 1" ),
				StaticObjectSpawnatronEntry( 65312, 0, "Jungle_B04_SnakeplantS-Whole.lod", "Jungle_B04_SnakeplantS-Whole_COL.pfx", "Plant Snakeplant 2" ),
				StaticObjectSpawnatronEntry( 65313, 0, "Jungle_B21_PoppyM-Whole.lod", "Jungle_B21_PoppyM-Whole_COL.pfx", "Plant PoppySeed Medium" ),
				StaticObjectSpawnatronEntry( 65314, 0, "Jungle_B22_PoppyS-Whole.lod", "Jungle_B22_PoppyS-Whole_COL.pfx", "Plant PoppySeed Small" ),
				StaticObjectSpawnatronEntry( 65315, 0, "Jungle_B23_PoppyL-Whole.lod", "Jungle_B23_PoppyL-Whole_COL.pfx", "Plant PoppySeed Large" ),
				StaticObjectSpawnatronEntry( 65316, 0, "Jungle_B31_KelpM-Whole.lod", "Jungle_B31_KelpM-Whole_COL.pfx", "Plant Underwater Kelp Medium 2" ),
				StaticObjectSpawnatronEntry( 65317, 0, "Jungle_B32_KelpL-Whole.lod", "Jungle_B32_KelpL-Whole_COL.pfx", "Plant Underwater Kelp Large" ),
				StaticObjectSpawnatronEntry( 65318, 0, "Jungle_B33_KelpM-Whole.lod", "Jungle_B33_KelpM-Whole_COL.pfx", "Plant Underwater Kelp Medium" ),
				StaticObjectSpawnatronEntry( 65319, 0, "Jungle_B34_KelpS-Whole.lod", "Jungle_B34_KelpS-Whole_COL.pfx", "Plant Underwater Kelp Small" ),
				StaticObjectSpawnatronEntry( 65320, 0, "vegetation_1.blz/Arctic_B11_bushtreeL-Whole.lod", "Arctic_B11_bushtreeL-Whole_COL.pfx", "Bush Small 3" ),
				StaticObjectSpawnatronEntry( 65321, 0, "vegetation_1.blz/Arctic_B12_bushtreeM-Whole.lod", "Arctic_B12_bushtreeM-Whole_COL.pfx", "Bush Small 2" ),
				StaticObjectSpawnatronEntry( 65322, 0, "vegetation_1.blz/Arctic_B13_bushtreeS-Whole.lod", "Arctic_B13_bushtreeS-Whole_COL.pfx", "Bush Small 1" ),
				StaticObjectSpawnatronEntry( 65323, 0, "vegetation_2.blz/Desert_T01_NeedleBushM-whole.lod", "Desert_T01_NeedleBushM-whole_COL.pfx", "NeedleBush 6" ),
				StaticObjectSpawnatronEntry( 65324, 0, "vegetation_2.blz/Desert_T02_NeedleBushM-whole.lod", "Desert_T02_NeedleBushM-whole_COL.pfx", "NeedleBush 5" ),
				StaticObjectSpawnatronEntry( 65325, 0, "vegetation_2.blz/Desert_T03_NeedleBushS-Whole.lod", "Desert_T03_NeedleBushS-Whole_COL.pfx", "NeedleBush 4" ),
				StaticObjectSpawnatronEntry( 65326, 0, "vegetation_2.blz/Desert_T04_NeedleBushXS-Whole.lod", "Desert_T04_NeedleBushXS-Whole_COL.pfx", "NeedleBush 3" ),
				StaticObjectSpawnatronEntry( 65327, 0, "vegetation_2.blz/Desert_T05_NeedleBushClM-Whole.lod", "Desert_T05_NeedleBushClM-Whole_COL.pfx", "NeedleBush 2" ),
				StaticObjectSpawnatronEntry( 65328, 0, "vegetation_2.blz/Desert_T06_NeedleBushClS-Whole.lod", "Desert_T06_NeedleBushClS-Whole_COL.pfx", "NeedleBush 1" ),
			},



			["Interior Design"] = {
				--StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/gb189-b.lod", "areaset02.blz/gb189_lod1-b_col.pfx", "Interior1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb226-c.lod", "areaset03.blz/gb226_lod1-c_col.pfx", "Triangle Roof1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/gb226-d.lod", "areaset03.blz/gb226_lod1-d_col.pfx", "Triangle Roof2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb106-p.lod", "areaset05.blz/gb106_lod1-p_col.pfx", "Doorway1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb110-a.lod", "areaset05.blz/gb110_lod1-a_col.pfx", "Floor Layout1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb165-g.lod", "areaset05.blz/gb165_lod1-g_col.pfx", "Floor Tile Large Sandy" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb165-m.lod", "areaset05.blz/gb165_lod1-m_col.pfx", "Floor Layout + Walls + Doorway" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb165-n.lod", "areaset05.blz/gb165_lod1-n_col.pfx", "Door1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb165-o.lod", "areaset05.blz/gb165_lod1-o_col.pfx", "Staircase Metal1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb210-a.lod", "areaset05.blz/gb210_lod1-a_col.pfx", "Floor Layout + Walls Military Style" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb211-b.lod", "areaset05.blz/gb211_lod1-b_col.pfx", "Walkway Pentagonal1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb211-d.lod", "areaset05.blz/gb211_lod1-d_col.pfx", "Walkway Pentagonal2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb211-e.lod", "areaset05.blz/gb211_lod1-e_col.pfx", "Walkway Straight Small1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb211-j.lod", "areaset05.blz/gb211_lod1-j_col.pfx", "Floor Layout Pentagonal1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset05.blz/gb211-k.lod", "areaset05.blz/gb211_lod1-k_col.pfx", "Walls Large Metal + Door1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-h.lod", "areaset06.blz/gb184_lod1-h_col.pfx", "Floor Tile Large Angled1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-i.lod", "areaset06.blz/gb184_lod1-i_col.pfx", "Floor Tile Large Angled2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-g.lod", "areaset06.blz/gb184_lod1-g_col.pfx", "Floor Tile or Wall Large Flat1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-f.lod", "areaset06.blz/gb184_lod1-f_col.pfx", "Floor Tile or Wall Large Flat2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-e.lod", "areaset06.blz/gb184_lod1-e_col.pfx", "Floor Tile Large Angled3" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-l.lod", "areaset06.blz/gb184_lod1-l_col.pfx", "Floor Piece Wooden1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-m.lod", "areaset06.blz/gb184_lod1-m_col.pfx", "Floor Piece Wooden2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-n.lod", "areaset06.blz/gb184_lod1-n_col.pfx", "Floor Piece + Roofing Elevated Wooden1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset06.blz/gb184-p.lod", "areaset06.blz/gb184_lod1-p_col.pfx", "Walkway Elevated or Elevater Wooden" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset07.blz/gb095-e.lod", "areaset07.blz/gb095_lod1-e_col.pfx", "Walkway Straight Metal1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset07.blz/gb095-f.lod", "areaset07.blz/gb095_lod1-f_col.pfx", "Stairs Metal1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset07.blz/gb095-j.lod", "areaset07.blz/gb095_lod1-j_col.pfx", "Floor Layout Pentagonal2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset07.blz/gb095-k.lod", "areaset07.blz/gb095_lod1-k_col.pfx", "Wall Stone Large1(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset08.blz/gb036_01-pipes.lod", "areaset08.blz/gb036_01_lod1-pipes_col.pfx", "Pipes1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset08.blz/gb036_02-rail_16m.lod", "areaset08.blz/gb036_02_lod1-rail_16m_col.pfx", "Railing 16m" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset08.blz/gb036_02-rail_2m.lod", "areaset08.blz/gb036_02_lod1-rail_2m_col.pfx", "Railing 2m" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset08.blz/gb036_02-rail_4m.lod", "areaset08.blz/gb036_02_lod1-rail_4m_col.pfx", "Railing 4m" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset08.blz/gb036_02-rail_8m.lod", "areaset08.blz/gb036_02_lod1-rail_8m_col.pfx", "Railing 8m" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset08.blz/gb036_02-stairs_left.lod", "areaset08.blz/gb036_02_lod1-stairs_left_col.pfx", "Stairs Metal Left Prejudice1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset08.blz/gb036_02-stairs_right.lod", "areaset08.blz/gb036_02_lod1-stairs_right_col.pfx", "Stairs Metal Right Prejudice1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset09.blz/gb250-g.lod", "areaset09.blz/gb250_lod1-g_col.pfx", "Ladder/Railing Yellow1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_channeltiles-stair.lod", "areaset13.blz/cs_channeltiles_lod1-stair_col.pfx", "Stairs Layered Stone1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_channeltiles-walkway.lod", "areaset13.blz/cs_channeltiles_lod1-walkway_col.pfx", "Walkway Straight Small2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_combase-v5b.lod", "areaset13.blz/cs_combase_lod1-v5b_col.pfx", "Wall HUGE1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_combase-v6a.lod", "areaset13.blz/cs_combase_lod1-v6a_col.pfx", "Stairs Stone Small Wide1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_combase-v7a.lod", "areaset13.blz/cs_combase_lod1-v7a_col.pfx", "Floor Layout2(almost no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/cs_roof_propps-v3a.lod", "areaset13.blz/cs_roof_propps_lod1-v3a_col.pfx", "Solar Panel Angled1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "areaset13.blz/pierparts-piera3.lod", "areaset13.blz/pierparts_lod1-piera3_col.pfx", "Wall HUGE2(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "general.blz/go170-arrowg_03.lod", "general.blz/go170_lod1-arrowg_03_col.pfx", "Arrow Green" ),
				--StaticObjectSpawnatronEntry( 20, 0, "general.blz/gd_metal01-a.lod", "general.blz/gd_metal01_lod1-a_col.pfx", "Floor Tile Metal Rugged1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "general.blz/gd_concrete01-s.lod", "general.blz/gd_concrete01_lod1-s_col.pfx", "Concrete Block Tiny1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f1m03.interiors.flz/go047-b.lod", "f1m03.interiors.flz/go047_lod1-b_col.pfx", "Wall Military Stone Large1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m01.basen01.flz/go070-k.lod", "f2m01.basen01.flz/go070_lod1-k_col.pfx", "Floor Tile Square Large Plain" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m01.basen03.flz/go070-j.lod", "f2m01.basen03.flz/go070_lod1-j_col.pfx", "Floor Layout Flat Medium(bland)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m05.stffront.flz/key026_01-m.lod", "f2m05.stffront.flz/key026_01_lod1-m_col.pfx", "Block Wooden Rectangular Small" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m05.stffront.flz/gb248-a4_02_dst.lod", "f2m05.stffront.flz/gb248_lod1-a4_02_dst_col.pfx", "Block Stone Rectangular Small" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m06.bridges.flz/key005_01-o2.lod", "f2m06.bridges.flz/key005_01_lod1-o2_col.pfx", "Lost Bridge Part(Floor)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m06harbor.flz/go070-i.lod", "f2m06harbor.flz/go070_lod1-i_col.pfx", "Floor Tile Angled Harbor" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m07.researchfacility.flz/key028_02-c.lod", "f2m07.researchfacility.flz/key028_02_lod1-c_col.pfx", "Interior Complete1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m07.researchfacility.flz/key028_02-d.lod", "f2m07.researchfacility.flz/key028_02_lod1-d_col.pfx", "Floor Layout Circular" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2m08.base.flz/key021_01-k.lod", "f2m08.base.flz/key021_01_lod1-k_col.pfx", "Floor Layout Military Style1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m02.radarstation.flz/key011-j.lod", "f3m02.radarstation.flz/key011_lod1-j_col.pfx", "Walkway Leading to Door w/ Stairs" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m02.radarstation.flz/key011-m.lod", "f3m02.radarstation.flz/key011_lod1-m_col.pfx", "Door3" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m04.fryme.flz/key016_01-z9_.lod", "f3m04.fryme.flz/key016_01_lod1-z9__col.pfx", "Wall Metal Long1(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m04.fryme.flz/key016_01-z7_.lod", "f3m04.fryme.flz/key016_01_lod1-z7__col.pfx", "Floor Tile Beautiful Rectangular(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m04.fryme.flz/key016_01-w1.lod", "f3m04.fryme.flz/key016_01_lod1-w1_col.pfx", "Box Metal Rectangular4" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m04.hatch.flz/key016_01-r4.lod", "f3m04.hatch.flz/key016_01_lod1-r4_col.pfx", "Floor Tile Metal Triangular Large1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m04.hatch.flz/key016_01-r5.lod", "f3m04.hatch.flz/key016_01_lod1-r5_col.pfx", "Floor Tile Metal Triangular Large2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m04.pads.flz/key016_01-a.lod", "f3m04.pads.flz/key016_01_lod1-a_col.pfx", "Exterior possible interior1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m05.skyscraper.flz/key019_01-b4.lod", "f3m05.skyscraper.flz/key019_01_lod1-b4_col.pfx", "Wall Curved with rectangular holes" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m06.afterski.flz/key020_01-o.lod", "f3m06.afterski.flz/key020_01_lod1-o_col.pfx", "Wall Stone Slightly Curved1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m06.forthslope.flz/go242-a2.lod", "f3m06.forthslope.flz/go242_lod1-a2_col.pfx", "Pole Metal Long Skinny" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m06.forthslope.flz/key020_03-pillar_base.lod", "f3m06.forthslope.flz/key020_03_lod1-pillar_base_col.pfx", "Stone Stairstep1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m06.forthslope.flz/key020_03-pillar.lod", "f3m06.forthslope.flz/key020_03_lod1-pillar_col.pfx", "Pillar Stone1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3m06.lift01.flz/key020_03-concrete_plates_04.lod", "f3m06.lift01.flz/key020_03_lod1-concrete_plates_04_col.pfx", "Flooring Concrete Square Medium" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f1t10.covers.flz/go222-b.lod", "f1t10.covers.flz/go222_lod1-b_col.pfx", "Block Stone Rectangular Small1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f3t12.oilplatform.flz/gb002-l.lod", "f3t12.oilplatform.flz/gb002_lod1-l_col.pfx", "Pipes Long Parallel1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "km01.base.flz/key036-h.lod", "km01.base.flz/key036_lod1-h_col.pfx", "Wall Piece w/ Holes not see-through" ),
				--StaticObjectSpawnatronEntry( 20, 0, "km01.base.flz/key004_01-e.lod", "km01.base.flz/key004_01_lod1-e_col.pfx", "Wall Tile Large2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "km01.base.flz/key036-f.lod", "km01.base.flz/key036_lod1-f_col.pfx", "Wall Piece Square Medium Nice" ),
				--StaticObjectSpawnatronEntry( 20, 0, "km02.towercomplex.flz/key013_01-g.lod", "km02.towercomplex.flz/key013_01_lod1-g_col.pfx", "Glass Rectangular Large1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "km03.gamblinghouse.flz/key032_01-walkway.lod", "km03.gamblinghouse.flz/key032_01_lod1-walkway_col.pfx", "Tile Wooden Rectangular Small1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "km04.destructables.flz/key004_08-door.lod", "km04.destructables.flz/key004_08_lod1-door_col.pfx", "Metal Lite Wall/Floor Tile1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "km06.base.flz/key015_01-o2.lod", "km06.base.flz/key015_01_lod1-o2_col.pfx", "Floor Tile Triangular Fancy" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2s04.base.flz/key009_01-j.lod", "f2s04.base.flz/key009_01_lod1-j_col.pfx", "Floor Tile Tiled Stone Nice1(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "f2s04.base.flz/key009_01-j2.lod", "f2s04.base.flz/key009_01_lod1-j2_col.pfx", "Floor Tile Tiled Stone w/ Walkway" ),
				--StaticObjectSpawnatronEntry( 20, 0, "11x50_reapershqdemo.flz/key041_1-key041_1_interior.lod", "11x50_reapershqdemo.flz/key041_1_lod1-key041_1_interior_col.pfx", "Interior REAPER HQ" ),
				--StaticObjectSpawnatronEntry( 20, 0, "11x50_reapershqdemo.flz/key041_1-key041_1_door.lod", "11x50_reapershqdemo.flz/key041_1_lod1-key041_1_door_col.pfx", "Door REAPER HQ" ),
				--StaticObjectSpawnatronEntry( 20, 0, "05x21.flz/gb225-a.lod", "05x21.flz/gb225_lod1-a_col.pfx", "Floor Square Bland1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "24x22.flz/key042_1-part_b.lod", "24x22.flz/key042_1_lod1-part_b_col.pfx", "Interior Complete3" ),
				--StaticObjectSpawnatronEntry( 20, 0, "24x22.flz/key042_1-part_d.lod", "24x22.flz/key042_1_lod1-part_d_col.pfx", "Swimming Pool1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "25x50.flz/gb145-a.lod", "25x50.flz/gb145_lod1-a_col.pfx", "Interior no Roof" ),
				--StaticObjectSpawnatronEntry( 20, 0, "27x57.flz/go070-t.lod", "27x57.flz/go070_lod1-t_col.pfx", "Walkway Square2" ),
				--StaticObjectSpawnatronEntry( 20, 0, "31x08.flz/gb030-d.lod", "31x08.flz/gb030_lod1-d_col.pfx", "Heli Pad" ),
				--StaticObjectSpawnatronEntry( 20, 0, "33x08.flz/gb241-l2.lod", "33x08.flz/gb241_lod1-l2_col.pfx", "Stairs Wooden3" ),
				--StaticObjectSpawnatronEntry( 20, 0, "33x10.flz/go171-b.lod", "33x10.flz/go171_lod1-b_col.pfx", "Railing Skinny Sleek Parallel" ),
				--StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/go142-a.lod", "37x10.flz/go142_lod1-a_col.pfx", "Pipe Hollow1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/go142-b.lod", "37x10.flz/go142_lod1-b_col.pfx", "Hollow Pipes Stack" ),
				--StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/gb206-c.lod", "37x10.flz/gb206_lod1-c_col.pfx", "Wall Tile Medium2(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/gb206-h.lod", "37x10.flz/gb206_lod1-h_col.pfx", "Pole Small Tall Square1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "38x12.flz/go045-a.lod", "38x12.flz/go045_lod1-a_col.pfx", "Sandbags Pile Rectangular1" ),
				--StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go500-a.lod", "40x11.flz/go500_lod1-a_col.pfx", "Wall Rectangular Military2(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "53x19.flz/key001_03-g.lod", "53x19.flz/key001_03_lod1-g_col.pfx", "Pole Rectangular Medium" ),
				--StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/gp074-h.lod", "40x11.flz/gp074_lod1-h_col.pfx", "Wall Tile Square Medium2(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/gp074-g.lod", "40x11.flz/gp074_lod1-g_col.pfx", "Wall Tile Square Small1(no collision)" ),
				--StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/gb093-c.lod", "40x11.flz/gb093_lod1-c_col.pfx", "Floor Tile Elevated3" ),
				--StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go022-k.lod", "40x11.flz/go022_lod1-k_col.pfx", "Wall Piece Rectangular Medium" ),
				--StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go022-l.lod", "40x11.flz/go022_lod1-l_col.pfx", "Wall Piece Rectangular Very Long" ),
				--StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go022-m.lod", "40x11.flz/go022_lod1-m_col.pfx", "Wall Cornerpiece" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go173-m.lod", "40x11.flz/go173_lod1-m_col.pfx", "Top of Stairs Piece" ),
				StaticObjectSpawnatronEntry( 20, 0, "seve.v104_attack_boat.eez/v104-body_m.lod", "seve.v104_attack_boat.eez/v104-body_m_col.pfx", "__boat" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "f2m07.ice.flz/key028_02_lod1-i_col.pfx", "Collision - Square HUGE(500m radius - not recommended)" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "areaset05.blz/gb165_lod1-g_col.pfx", "Collision - 16m squared(Rico x 5 = 1 Side Length)" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "areaset05.blz/gb165_lod1-n_col.pfx", "Collision - Small Door" ),
				StaticObjectSpawnatronEntry( 20, 0, "arve.v061_attackheli.eez/v061-body_m.lod", "arve.v061_attackheli.eez/v061_lod1-body_m_col.pfx", "HavocBody" ),
				StaticObjectSpawnatronEntry( 20, 0, "arve.v061_attackheli.eez/v061-cockpit_cu1.lod", "arve.v061_attackheli.eez/v061_lod1-cockpit_cu1_col.pfx", "HavocCockpitOutside" ),
				StaticObjectSpawnatronEntry( 20, 0, "arve.v061_attackheli.eez/v061-rotor1-rotoraxel.lod", "arve.v061_attackheli.eez/v061_lod1-rotor1_lod1-rotoraxel_col.pfx", "HavocAxle" ),
				StaticObjectSpawnatronEntry( 20, 0, "arve.v061_attackheli.eez/v061-rotor1-rotorstill4.lod", "arve.v061_attackheli.eez/v061_lod1-rotor1_lod1-rotorstill4_col.pfx", "HavocRotor" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/wea55-b.lod", "", "MG Attachment" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "name" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "name" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "name" ),
				
				
			},

			["Interior Decorating"] = {
                StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/go150-b.lod", "areaset02.blz/go150_lod1-b_col.pfx", "Speakers1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset02.blz/go150-c.lod", "areaset02.blz/go150_lod1-c_col.pfx", "Chair Small1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/go161-a2_dst.lod", "areaset03.blz/go161_lod1-a2_dst_col.pfx", "Light Tile Small" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/go161-a1_dst.lod", "areaset03.blz/go161_lod1-a1_dst_col.pfx", "Cushion1" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset07.blz/go235-b.lod", "areaset07.blz/go235_lod1-b_col.pfx", "Umbrella Beach Wooden" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset07.blz/go235-a.lod", "areaset07.blz/go235_lod1-a_col.pfx", "Mattress Beach1" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/seats01-seat01.lod", "general.blz/seats01_lod1-seat01_col.pfx", "Seat Car1" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/wea14-a.lod", "general.blz/wea14_lod1-a_col.pfx", "Sniper" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/wea17-grenadelauncher1.lod", "general.blz/wea17_lod1-grenadelauncher1_col.pfx", "Grenade Launcher" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/wea16-wea16_01.lod", "general.blz/wea16_lod1-wea16_01_col.pfx", "Panau Rocket Launcher" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/wea33-wea33.lod", "general.blz/wea33_lod1-wea33_col.pfx", "Grenade" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/gd_sandbag-a.lod", "general.blz/gd_sandbag_lod1-a_col.pfx", "Sandbag1" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/gd_metal01-e.lod", "general.blz/gd_metal01_lod1-e_col.pfx", "Pole Metal Small1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03_00b.seq.blz/walkie-walkie.lod", "km03_00b.seq.blz/walkie_lod1-walkie_col.pfx", "Walkie-Talkie Tiny1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03_00b.seq.blz/fance-a.lod", "km03_00b.seq.blz/fance_lod1-a_col.pfx", "Floor + Railing Wooden Classy1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03_01b.seq.blz/gp005-a.lod", "km03_01b.seq.blz/gp005_lod1-a_col.pfx", "BBQ1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03_03b.seq.blz/torturechair-a.lod", "km03_03b.seq.blz/torturechair_lod1-a_col.pfx", "Torture Chair" ),
				StaticObjectSpawnatronEntry( 20, 0, "km04_08.seq.blz/gp009-a.lod", "km04_08.seq.blz/gp009_lod1-a_col.pfx", "Firepit1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05_01.seq.blz/go164_01-g.lod", "km05_01.seq.blz/go164_01_lod1-g_col.pfx", "Container1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05_02d.seq.blz/key030_02_satelite-a.lod", "km05_02d.seq.blz/key030_02_satelite_lod1-a_col.pfx", "Satellite Object1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05_02e.seq.blz/key030_01-x.lod", "km05_02e.seq.blz/key030_01_lod1-x_col.pfx", "Ceiling Light" ),
				StaticObjectSpawnatronEntry( 20, 0, "km06_01.seq.blz/key004_07-a.lod", "km06_01.seq.blz/key004_07_lod1-a_col.pfx", "Mattress Beach2" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07_02.seq.blz/key014_02-ladder.lod", "km07_02.seq.blz/key014_02_lod1-ladder_col.pfx", "Ladder2" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07_02.seq.blz/key014_02-n.lod", "km07_02.seq.blz/key014_02_lod1-n_col.pfx", "Poles Black" ),
				StaticObjectSpawnatronEntry( 20, 0, "cch06emp.flz/go234-a.lod", "cch06emp.flz/go234_lod1-a_col.pfx", "Table Low1" ),
				StaticObjectSpawnatronEntry( 20, 0, "cch06emp.flz/go224-l.lod", "cch06emp.flz/go224_lod1-l_col.pfx", "Bowl Food Full" ),
				StaticObjectSpawnatronEntry( 20, 0, "cch06emp.flz/go224-f.lod", "cch06emp.flz/go224_lod1-f_col.pfx", "Bowl Food Empty" ),
				StaticObjectSpawnatronEntry( 20, 0, "cch30emp.flz/go061-i.lod", "cch30emp.flz/go061_lod1-i_col.pfx", "Boards Wooden Small" ),
				StaticObjectSpawnatronEntry( 20, 0, "f2s04emp.flz/key040_1-part_b.lod", "f2s04emp.flz/key040_1_lod1-part_b_col.pfx", "Pole Ornate1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f2t04emp.flz/go221-b.lod", "f2t04emp.flz/go221_lod1-b_col.pfx", "Wooden Table3" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m03.interiors.flz/go173-i.lod", "f1m03.interiors.flz/go173_lod1-i_col.pfx", "Floor Metal Grated See-Through1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m03.interiors.flz/go158-a.lod", "f1m03.interiors.flz/go158_lod1-a_col.pfx", "Food Machine" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m03.interiors.flz/go158-a1.lod", "f1m03.interiors.flz/go158_lod1-a1_col.pfx", "Beverage Machine" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m03.interiors.flz/gb192-b1_dst.lod", "f1m03.interiors.flz/gb192_lod1-b1_dst_col.pfx", "Console Rusty1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001-a2a.lod", "f1m07milehigh.flz/key001_lod1-a2a_col.pfx", "Pedestal1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001-a2b.lod", "f1m07milehigh.flz/key001_lod1-a2b_col.pfx", "Pole Glass Small1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001-a_hangar.lod", "f1m07milehigh.flz/key001_lod1-a_hangar_col.pfx", "Interior Layout w/ Walls1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001-c.lod", "f1m07milehigh.flz/key001_lod1-c_col.pfx", "MHC Engine1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001-c1.lod", "f1m07milehigh.flz/key001_lod1-c1_col.pfx", "MHC Engine Blades1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001-m.lod", "f1m07milehigh.flz/key001_lod1-m_col.pfx", "Plant Pot1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001-n.lod", "f1m07milehigh.flz/key001_lod1-n_col.pfx", "Overhead Light2" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m07milehigh.flz/key001_03-h.lod", "f1m07milehigh.flz/key001_03_lod1-h_col.pfx", "Stairs On/Off Metal" ),
				StaticObjectSpawnatronEntry( 20, 0, "f2m06airstrip.flz/go020-c.lod", "f2m06airstrip.flz/go020_lod1-c_col.pfx", "Ladder4" ),
				StaticObjectSpawnatronEntry( 20, 0, "f2m07.researchfacility.flz/key028_02-o.lod", "f2m07.researchfacility.flz/key028_02_lod1-o_col.pfx", "Pedastel Fancy1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f3m06.afterski.flz/key020_01-z.lod", "f3m06.afterski.flz/key020_01_lod1-z_col.pfx", "Picnic Table" ),
				StaticObjectSpawnatronEntry( 20, 0, "f3m06.lift01.flz/key020_01-x.lod", "f3m06.lift01.flz/key020_01_lod1-x_col.pfx", "Random Decoration1" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1t10.covers.flz/go400-c.lod", "f1t10.covers.flz/go400_lod1-c_col.pfx", "Rectangular Rainbow Decoration" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03.gamblinghouse.flz/key032_01-f.lod", "km03.gamblinghouse.flz/key032_01_lod1-f_col.pfx", "Barrel Wooden1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03.gamblinghouse.flz/key032_01-k.lod", "km03.gamblinghouse.flz/key032_01_lod1-k_col.pfx", "Railing Fancy2" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03.gamblinghouse.flz/key032_01-l.lod", "km03.gamblinghouse.flz/key032_01_lod1-l_col.pfx", "Bench Wooden1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03.shipwreck.flz/go061-h.lod", "km03.shipwreck.flz/go061_lod1-h_col.pfx", "Chair Wooden Small1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05.hotelbuilding01.flz/key030_01-i7.lod", "km05.hotelbuilding01.flz/key030_01_lod1-i7_col.pfx", "Chair Fancy1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05.hotelbuilding01.flz/key030_01-m1.lod", "km05.hotelbuilding01.flz/key030_01_lod1-m1_col.pfx", "Chair Fancy2" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05.hotelbuilding01.flz/key030_01-n.lod", "km05.hotelbuilding01.flz/key030_01_lod1-n_col.pfx", "Table Square3" ),
				StaticObjectSpawnatronEntry( 20, 0, "km06.base.flz/key015_01-z1_01.lod", "km06.base.flz/key015_01_lod1-z1_01_col.pfx", "Gong Asian" ),
				StaticObjectSpawnatronEntry( 20, 0, "22x19.flz/go222-g.lod", "22x19.flz/go222_lod1-g_col.pfx", "Box CardBoard2" ),
				StaticObjectSpawnatronEntry( 20, 0, "05x41.flz/go222-j.lod", "05x41.flz/go222_lod1-j_col.pfx", "Box CardBoard1" ),
				StaticObjectSpawnatronEntry( 20, 0, "24x22.flz/key042_1-part_d1.lod", "24x22.flz/key042_1_lod1-part_d1_col.pfx", "Water Sheet1" ),
				StaticObjectSpawnatronEntry( 20, 0, "33x08.flz/go113-a.lod", "33x08.flz/go113_lod1-a_col.pfx", "Crafting Table?" ),
				StaticObjectSpawnatronEntry( 20, 0, "33x11.flz/go061-d.lod", "33x11.flz/go061_lod1-d_col.pfx", "Chair Small Blue" ),
				StaticObjectSpawnatronEntry( 20, 0, "34x09.flz/go003-a.lod", "34x09.flz/go003_lod1-a_col.pfx", "Crate Wooden1" ),
				StaticObjectSpawnatronEntry( 20, 0, "34x09.flz/go001-a.lod", "34x09.flz/go001_lod1-a_col.pfx", "Red Barrel1" ),
				StaticObjectSpawnatronEntry( 20, 0, "34x30.flz/key040_1-part_g.lod", "34x30.flz/key040_1_lod1-part_g_col.pfx", "Wall Torch Unlit" ),
				StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/go231-b.lod", "37x10.flz/go231_lod1-b_col.pfx", "Blue Barrel2" ),
				StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/go223-a.lod", "37x10.flz/go223_lod1-a_col.pfx", "Fruit Basket3" ),
				StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/go125-a.lod", "37x10.flz/go125_lod1-a_col.pfx", "Wooden Crate Large1" ),
				StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/go128-b.lod", "37x10.flz/go128_lod1-b_col.pfx", "Green Barrel" ),
				StaticObjectSpawnatronEntry( 20, 0, "38x11.flz/go231-a.lod", "38x11.flz/go231_lod1-a_col.pfx", "Blue Barrel3" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/gp003-a.lod", "40x11.flz/gp003_lod1-a_col.pfx", "Console2" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go164_01-e.lod", "40x11.flz/go164_01_lod1-e_col.pfx", "Green Military Shit1" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/gp074-f.lod", "40x11.flz/gp074_lod1-f_col.pfx", "Ventilation Shaft Entrance" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/gp071-a.lod", "40x11.flz/gp071_lod1-a_col.pfx", "Cables for Walls1" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/gp071-b.lod", "40x11.flz/gp071_lod1-b_col.pfx", "Cables for Walls2" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go043-e.lod", "40x11.flz/go043_lod1-e_col.pfx", "Doorhandle Vault" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go043-d.lod", "40x11.flz/go043_lod1-d_col.pfx", "Wall Decoration Random1" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go043-h.lod", "40x11.flz/go043_lod1-h_col.pfx", "Generator Military" ),
				StaticObjectSpawnatronEntry( 20, 0, "40x11.flz/go173-n.lod", "40x11.flz/go173_lod1-n_col.pfx", "Wall Decoration Random2" ),
				StaticObjectSpawnatronEntry( 20, 0, "geo.cbb.eez/go152-a.lod", "km05.hotelbuilding01.flz/key030_01_lod1-n_col.pfx", "LootBoxTier3" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1t05bomb01.eez/go059-a.lod", "f1t05bomb01.eez/go059_lod1-a_col.pfx", "xLoot2" ),
				StaticObjectSpawnatronEntry( 20, 0, "ballonfighter.eez/gb400-d.lod", "ballonfighter.eez/gb400_lod1-d_col.pfx", "LootBoxDropBox" ),
				StaticObjectSpawnatronEntry( 20, 0, "geo.cdd.eez/go151-a.lod", "geo.cdd.eez/go151_lod1-a_col.pfx", "xLoot4Briefcase" ),
				StaticObjectSpawnatronEntry( 20, 0, "pickup.boost.vehicle.eez/pu02-a.lod", "37x10.flz/go061_lod1-e_col.pfx", "xLoot5" ),
				StaticObjectSpawnatronEntry( 20, 0, "f1m03airstrippile07.eez/go164_01-a.lod", "f1m03airstrippile07.eez/go164_01_lod1-a_col.pfx", "xLoot6" ),
				StaticObjectSpawnatronEntry( 20, 0, "pickup.boost.armor.eez/pu03-a.lod", "37x10.flz/go061_lod1-e_col.pfx", "xLoot7" ),
				StaticObjectSpawnatronEntry( 20, 0, "pickup.boost.cash.eez/pu05-a.lod", "37x10.flz/go061_lod1-e_col.pfx", "LootBoxCredits" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-treasure_01.lod", "km07.submarine.eez/key014_02_lod1-treasure_01_col.pfx", "xLootW1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-treasure_02.lod", "km07.submarine.eez/key014_02_lod1-treasure_02_col.pfx", "xLootW2" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-treasure_03.lod", "km07.submarine.eez/key014_02_lod1-treasure_03_col.pfx", "xLootW3" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-treasure_04.lod", "km07.submarine.eez/key014_02_lod1-treasure_04_col.pfx", "xLootW4" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-treasure_05.lod", "km07.submarine.eez/key014_02_lod1-treasure_05_col.pfx", "xLootW5" ),
				StaticObjectSpawnatronEntry( 20, 0, "km07.submarine.eez/key014_02-treasure_06.lod", "km07.submarine.eez/key014_02_lod1-treasure_06_col.pfx", "xLootW6" ),
				StaticObjectSpawnatronEntry( 20, 0, "km01_00.seq.blz/v062cutscene-box.lod", "km01_00.seq.blz/v062cutscene_lod1-box_col.pfx", "xLoot9" ),
				StaticObjectSpawnatronEntry( 20, 0, "km01_01.seq.blz/v062cutscene_agency-box.lod", "km01_01.seq.blz/v062cutscene_agency_lod1-box_col.pfx", "xLoot10" ),
				StaticObjectSpawnatronEntry( 20, 0, "km02_02a.seq.blz/gp700_01-granade_base.lod", "km02_02a.seq.blz/gp700_01_lod1-granade_base_col.pfx", "Grenade69" ),
				StaticObjectSpawnatronEntry( 20, 0, "km05_01.seq.blz/go164_01-g.lod", "km05_01.seq.blz/go164_01_lod1-g_col.pfx", "xLoot11" ),
				StaticObjectSpawnatronEntry( 20, 0, "mod.heavydrop.assault.eez/wea00-a.lod", "mod.heavydrop.assault.eez/wea00_lod1-a_col.pfx", "xLoot11FlipOver" ),
				StaticObjectSpawnatronEntry( 20, 0, "mod.heavydrop.beretta.eez/wea00-b.lod", "mod.heavydrop.beretta.eez/wea00_lod1-b_col.pfx", "xLoot12FlipOver" ),
				StaticObjectSpawnatronEntry( 20, 0, "general.blz/go155-a.lod", "general.blz/go155_lod1-a_col.pfx", "LootBoxTier1" ),
				StaticObjectSpawnatronEntry( 20, 0, "km03.gamblinghouse.flz/key032_01-f.lod", "km03.gamblinghouse.flz/key032_01_lod1-f_col.pfx", "LootBoxTier2" ),
				StaticObjectSpawnatronEntry( 20, 0, "37x10.flz/go231-b.lod", "37x10.flz/go231_lod1-b_col.pfx", "xLoot14" ),
				StaticObjectSpawnatronEntry( 20, 0, "38x11.flz/go231-a.lod", "38x11.flz/go231_lod1-a_col.pfx", "xLoot15" ),
				StaticObjectSpawnatronEntry( 20, 0, "22x19.flz/go222-g.lod", "22x19.flz/go222_lod1-g_col.pfx", "xLoot16" ),
				StaticObjectSpawnatronEntry( 20, 0, "34x09.flz/go003-a.lod", "34x09.flz/go003_lod1-a_col.pfx", "xLoot17" ),
				StaticObjectSpawnatronEntry( 20, 0, "areaset03.blz/go161-a1_dst.lod", "areaset03.blz/go161_lod1-a1_dst_col.pfx", "xLoot18" ),
				StaticObjectSpawnatronEntry( 20, 0, "34x09.flz/go001-a.lod", "34x09.flz/go001_lod1-a_col.pfx", "xLoot19" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "", "", "" ),
				StaticObjectSpawnatronEntry( 20, 0, "32x34.flz/key040_1-part_a.lod", "32x34.flz/key040_1_lod1-part_a_col.pfx", "SEA_ancientstronghold" ),
				
			}
            },

        [self.types.Weapon] = {
            { "Right Hand", "Left Hand", "Two-handed", "vikfuck" },
            ["Right Hand"] = {
                WeaponSpawnatronEntry( Weapon.Handgun, 0, 1, "Pistol" ),
                WeaponSpawnatronEntry( Weapon.Revolver, 0, 1, "Revolver" ),
                WeaponSpawnatronEntry( Weapon.SMG, 0, 1, "SMG" ),
                WeaponSpawnatronEntry( Weapon.SawnOffShotgun, 0, 1, "Sawn-off Shotgun" ),
				WeaponSpawnatronEntry( Weapon.GrenadeLauncher, 0, 1, "Grenade Launcher" ),
				WeaponSpawnatronEntry( Weapon.BubbleGun, 0, 1, "Bubble Gun" ),
				WeaponSpawnatronEntry( Weapon.AlphaDLCWeapon, 0, 2, "Bullseye Rifle" ),
				WeaponSpawnatronEntry( Weapon.SignatureGun, 0, 2, "Rico's Gun" )


            },
			["Left Hand"] = {
                WeaponSpawnatronEntry( Weapon.Handgun, 0, 0, "Pistol" ),
                WeaponSpawnatronEntry( Weapon.Revolver, 0, 0, "Revolver" ),
                WeaponSpawnatronEntry( Weapon.SMG, 0, 0, "SMG" ),
                WeaponSpawnatronEntry( Weapon.SawnOffShotgun, 0, 0, "Sawn-off Shotgun" ),
				WeaponSpawnatronEntry( Weapon.GrenadeLauncher, 0, 0, "Grenade Launcher" ),
				WeaponSpawnatronEntry( Weapon.BubbleGun, 0, 0, "Bubble Gun" )
            },
            ["Two-handed"] = {
                WeaponSpawnatronEntry( Weapon.Assault, 0, 2, "Assault Rifle" ),
                WeaponSpawnatronEntry( Weapon.Shotgun, 0, 2, "Shotgun" ),
                WeaponSpawnatronEntry( Weapon.MachineGun, 0, 2, "Machine Gun" ),
                WeaponSpawnatronEntry( Weapon.Sniper, 0, 2, "Sniper Rifle" ),
                WeaponSpawnatronEntry( Weapon.RocketLauncher, 0, 2, "Rocket Launcher" ),
				WeaponSpawnatronEntry( Weapon.Airzooka, 0, 2, "Air Cannon" ),
				WeaponSpawnatronEntry( Weapon.QuadRocketLauncher, 0, 2, "Quad Rocket Launcher" ),
				WeaponSpawnatronEntry( Weapon.MultiTargetRocketLauncher, 0, 2, "Multi-Target Launcher" ),
				WeaponSpawnatronEntry( Weapon.ClusterBombLauncher, 0, 2, "Cluster Bomb Launcher" )
            },
			 ["vikfuck"] = {
                WeaponSpawnatronEntry( Weapon.Assault, 0, 2, "i do whatever" ),
                WeaponSpawnatronEntry( Weapon.Shotgun, 0, 2, "blowme" ),
                WeaponSpawnatronEntry( Weapon.MachineGun, 0, 2, "Machine Gun" ),
                WeaponSpawnatronEntry( Weapon.Sniper, 0, 2, "Sniper Rifle" ),
                WeaponSpawnatronEntry( Weapon.RocketLauncher, 0, 2, "Rocket Launcher" ),
				WeaponSpawnatronEntry( Weapon.Airzooka, 0, 2, "Air Cannon" ),
				WeaponSpawnatronEntry( Weapon.QuadRocketLauncher, 0, 2, "Quad Rocket Launcher" ),
				WeaponSpawnatronEntry( Weapon.MultiTargetRocketLauncher, 0, 2, "Multi-Target Launcher" ),
				WeaponSpawnatronEntry( Weapon.ClusterBombLauncher, 0, 2, "Cluster Bomb Launcher" )
            }
        },

        [self.types.Model] = {
            { "Roaches", "Ular Boys", "Reapers", "Government", "Agency", "Misc" },

            ["Roaches"] = {
                ModelSpawnatronEntry( 2, 0, "Razak Razman" ),
                ModelSpawnatronEntry( 5, 0, "Elite" ),
                ModelSpawnatronEntry( 32, 0, "Technician" ),
                ModelSpawnatronEntry( 85, 0, "Soldier 1" ),
                ModelSpawnatronEntry( 59, 0, "Soldier 2" )
            },

            ["Ular Boys"] = {
                ModelSpawnatronEntry( 38, 0, "Sri Irawan" ),
                ModelSpawnatronEntry( 87, 0, "Elite" ),
                ModelSpawnatronEntry( 22, 0, "Technician" ),
                ModelSpawnatronEntry( 27, 0, "Soldier 1" ),
                ModelSpawnatronEntry( 103, 0, "Soldier 2" )
            },

            ["Reapers"] = {
                ModelSpawnatronEntry( 90, 0, "Bolo Santosi" ),
                ModelSpawnatronEntry( 63, 0, "Elite" ),
                ModelSpawnatronEntry( 8, 0, "Technician" ),
                ModelSpawnatronEntry( 12, 0, "Soldier 1" ),
                ModelSpawnatronEntry( 58, 0, "Soldier 2" ),
            },

            ["Government"] = {
                ModelSpawnatronEntry( 74, 0, "Baby Panay" ),
                ModelSpawnatronEntry( 67, 0, "Burned Baby Panay" ),
                ModelSpawnatronEntry( 101, 0, "Colonel" ),
                ModelSpawnatronEntry( 3, 0, "Demo Expert" ),
                ModelSpawnatronEntry( 98, 0, "Pilot" ),
                ModelSpawnatronEntry( 42, 0, "Black Hand" ),
                ModelSpawnatronEntry( 44, 0, "Ninja" ),
                ModelSpawnatronEntry( 23, 0, "Scientist" ),
                ModelSpawnatronEntry( 52, 0, "Soldier 1" ),
                ModelSpawnatronEntry( 66, 0, "Soldier 2" )
            },

            ["Agency"] = {
                ModelSpawnatronEntry( 9, 0, "Karl Blaine" ),
                ModelSpawnatronEntry( 65, 0, "Jade Tan" ),
                ModelSpawnatronEntry( 25, 0, "Maria Kane" ),
                ModelSpawnatronEntry( 30, 0, "Marshall" ),
                ModelSpawnatronEntry( 34, 0, "Tom Sheldon" ),
                ModelSpawnatronEntry( 100, 0, "Black Market Dealer" ),
                ModelSpawnatronEntry( 83, 0, "White Tiger" ),
                ModelSpawnatronEntry( 51, 0, "Rico Rodriguez" )
            },

            ["Misc"] = {
                ModelSpawnatronEntry( 70, 0, "General Masayo" ),
                ModelSpawnatronEntry( 11, 0, "Zhang Sun" ),
                ModelSpawnatronEntry( 84, 0, "Alexander Mirikov" ),
                ModelSpawnatronEntry( 19, 0, "Chinese Businessman" ),
                ModelSpawnatronEntry( 36, 0, "Politician" ),
                ModelSpawnatronEntry( 78, 0, "Thug Boss" ),
                ModelSpawnatronEntry( 71, 0, "Saul Sukarno" ),
                ModelSpawnatronEntry( 79, 0, "Japanese Veteran" ),
                ModelSpawnatronEntry( 96, 0, "Bodyguard" ),
                ModelSpawnatronEntry( 80, 0, "Suited Guest 1" ),
                ModelSpawnatronEntry( 95, 0, "Suited Guest 2" ),
                ModelSpawnatronEntry( 60, 0, "Race Challenge Girl" ),
                ModelSpawnatronEntry( 15, 0, "Male Stripper 1" ),
                ModelSpawnatronEntry( 17, 0, "Male Stripper 2" ),
                ModelSpawnatronEntry( 86, 0, "Female Stripper" ),
                ModelSpawnatronEntry( 16, 0, "Panau Police" ),
                ModelSpawnatronEntry( 18, 0, "Hacker" ),
                ModelSpawnatronEntry( 64, 0, "Bom Bom Bohilano" ),
                ModelSpawnatronEntry( 40, 0, "Factory Boss" ),
                ModelSpawnatronEntry( 1, 0, "Thug 1" ),
                ModelSpawnatronEntry( 39, 0, "Thug 2" ),
                ModelSpawnatronEntry( 61, 0, "Soldier" ),
                ModelSpawnatronEntry( 26, 0, "Boat Captain" ),
                ModelSpawnatronEntry( 21, 0, "Paparazzi" ),
            }
        }
    }
end

Events:Subscribe("PlayerChat", function(args)
	if args.text == "/up" then
		if Server then
			args.player:SetPosition(args.player:GetPosition() + Vector3(0, 100, 0))
		end
	end
	
	if args.text == "/tome" then
		if Server then
			for p in Server:GetPlayers() do
				p:SetPosition(args.player:GetPosition())
			end
		end
	end
	
	if args.text == "/night" then
		if Server then
			DefaultWorld:SetTime(0)
		end
	end
end)
