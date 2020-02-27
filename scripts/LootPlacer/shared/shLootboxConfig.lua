Lootbox = {}

Lootbox.Types = 
{
    Level1 = 1,
    Level2 = 2,
    Level3 = 3,
    Level4 = 4,
    Level5 = 5, -- Floating ones
    Dropbox = 7, -- Dropbox
    Storage = 8,
    VendingMachineFood = 9,
    VendingMachineDrink = 10
}

Lootbox.Colors = 
{
    ["mod.heavydrop.grenade.eez/wea00-c.lod"] = Color.Green,
    ["f1m03airstrippile07.eez/go164_01-a.lod"] = Color.Blue,
    ["mod.heavydrop.beretta.eez/wea00-b.lod"] = Color.Purple,
    ["mod.heavydrop.assault.eez/wea00-a.lod"] = Color.Red,
    ["59x36.nl/go158-a1.lod"] = Color.Orange,
    ["59x36.nl/go158-a.lod"] = Color.Aqua
}

Lootbox.Models = 
{
    [Lootbox.Types.Level1] = 
    {
        model = "mod.heavydrop.grenade.eez/wea00-c.lod",
        col = "mod.heavydrop.grenade.eez/wea00_lod1-c_col.pfx",
        top_model = "mod.heavydrop.grenade.eez/wea00-c1.lod",
        top_col = "mod.heavydrop.grenade.eez/wea00_lod1-c1_col.pfx",
        offset = Vector3(0, 0.28, 0),
        offset2 = Vector3(0, 0, 0),
        look_offset = Vector3(0, 0, 0.3)
    },
    [Lootbox.Types.Level2] = 
    {
        model = "f1m03airstrippile07.eez/go164_01-a.lod",
        col = "f1m03airstrippile07.eez/go164_01_lod1-a_col.pfx",
        offset = Vector3(0, -0.025, 0)
    },
    [Lootbox.Types.Level3] =
    {
        model = "mod.heavydrop.beretta.eez/wea00-b.lod",
        col = "mod.heavydrop.beretta.eez/wea00_lod1-b_col.pfx",
        top_model = "mod.heavydrop.beretta.eez/wea00-b1.lod",
        top_col = "mod.heavydrop.beretta.eez/wea00_lod1-b1_col.pfx",
        offset = Vector3(0, 0.35, 0),
        offset2 = Vector3(0, 0, 0),
        look_offset = Vector3(0, 0, 0.3)
    },
    [Lootbox.Types.Level4] =
    {
        model = "mod.heavydrop.assault.eez/wea00-a.lod",
        col = "mod.heavydrop.assault.eez/wea00_lod1-a_col.pfx",
        top_model = "mod.heavydrop.assault.eez/wea00-a1.lod",
        top_col = "mod.heavydrop.assault.eez/wea00_lod1-a1_col.pfx",
        offset = Vector3(0, 0.33, 0),
        offset2 = Vector3(0, -0.04, -0.03),
        look_offset = Vector3(0, 0, 0.25)
    },
    [Lootbox.Types.Level5] = 
    {
        model = "pickup.boost.vehicle.eez/pu02-a.lod",
        col = "37x10.flz/go061_lod1-e_col.pfx",
        model2 = "general.blz/gae03-gae03.lod",
        offset = Vector3(0, -0.05, 0)
    },
    [Lootbox.Types.Dropbox] = 
    {
        model = "geo.cbb.eez/go152-a.lod",
        col = "km05.hotelbuilding01.flz/key030_01_lod1-n_col.pfx",
        offset = Vector3(0, -0.025, 0)
    },
    [Lootbox.Types.VendingMachineFood] = 
    {
        model = "59x36.nl/go158-a1.lod",
        col = "59x36.nl/go158_lod1-a1_col.pfx",
        model_dst = "59x36.nl/go158-a1_dst.lod",
        col_dst = "59x36.nl/go158_lod1-a1_dst_col.pfx",
        offset = Vector3(0, 0, 0)
    },
    [Lootbox.Types.VendingMachineDrink] = 
    {
        model = "59x36.nl/go158-a.lod",
        col = "59x36.nl/go158_lod1-a_col.pfx",
        model_dst = "59x36.nl/go158-a_dst.lod",
        col_dst = "59x36.nl/go158_lod1-a_dst_col.pfx",
        offset = Vector3(0, 0, 0)
    }
}
