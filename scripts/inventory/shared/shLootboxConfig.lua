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
    VendingMachineDrink = 9
}

Lootbox.GeneratorConfig = 
{
    stack = 
    {
        min = 1,
        max = 7,
        min_percent = 0.05,
        max_percent = 0.25
    },
    box = 
    {
        [Lootbox.Types.Level1] = 
        {
            min_items = 0,
            max_items = 4,
            respawn = 10,
            min_lockpicks = 1,
            max_lockpicks = 2
        },
        [Lootbox.Types.Level2] = 
        {
            min_items = 1,
            max_items = 4,
            respawn = 15,
            min_lockpicks = 2,
            max_lockpicks = 4
        },
        [Lootbox.Types.Level3] = 
        {
            min_items = 1,
            max_items = 4,
            respawn = 25,
            min_lockpicks = 3,
            max_lockpicks = 6
        },
        [Lootbox.Types.Level4] = 
        {
            min_items = 1,
            max_items = 4,
            respawn = 45,
            min_lockpicks = 5,
            max_lockpicks = 10
        },
        [Lootbox.Types.Level5] = 
        {
            min_items = 1,
            max_items = 3,
            respawn = 55,
            min_lockpicks = 20,
            max_lockpicks = 30
        },
        [Lootbox.Types.VendingMachineFood] = 
        {
            min_items = 2,
            max_items = 3,
            respawn = 15,
            min_lockpicks = 0,
            max_lockpicks = 0
        },
        [Lootbox.Types.VendingMachineDrink] = 
        {
            min_items = 2,
            max_items = 3,
            respawn = 15,
            min_lockpicks = 0,
            max_lockpicks = 0
        },
    }
}

Lootbox.Models = 
{
    [Lootbox.Types.Level1] = 
    {
        model = "f1m03airstrippile07.eez/go164_01-a.lod",
        col = "f1m03airstrippile07.eez/go164_01_lod1-a_col.pfx",
        offset = Vector3(0, -0.025, 0)
    },
    [Lootbox.Types.Level2] = 
    {
        model = "f1m03airstrippile07.eez/go164_01-b.lod",
        col = "f1m03airstrippile07.eez/go164_01_lod1-b_col.pfx",
        offset = Vector3(0, -0.025, 0)
    },
    [Lootbox.Types.Level3] =
    {
        model = "mod.heavydrop.beretta.eez/wea00-b.lod",
        col = "mod.heavydrop.beretta.eez/wea00_lod1-b_col.pfx",
        top_model = "mod.heavydrop.beretta.eez/wea00-b1.lod",
        top_col = "mod.heavydrop.beretta.eez/wea00_lod1-b1_col.pfx",
        offset = Vector3(0, 0.3, 0),
        offset2 = Vector3(0, 0, -0.28)
    },
    [Lootbox.Types.Level4] =
    {
        model = "mod.heavydrop.assault.eez/wea00-a.lod",
        col = "mod.heavydrop.assault.eez/wea00_lod1-a_col.pfx",
        top_model = "mod.heavydrop.assault.eez/wea00-a1.lod",
        top_col = "wea00_lod1-a1_col.pfx",
        offset = Vector3(0, 0.25, 0),
        offset2 = Vector3(0, 0, -0.28)
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
        model = "geo.cbb.eez/go152-a.lod",
        col = "km05.hotelbuilding01.flz/key030_01_lod1-n_col.pfx",
        offset = Vector3(0, -0.025, 0)
    },
    [Lootbox.Types.VendingMachineDrink] = 
    {
        model = "geo.cbb.eez/go152-a.lod",
        col = "km05.hotelbuilding01.flz/key030_01_lod1-n_col.pfx",
        offset = Vector3(0, -0.025, 0)
    }
}

Lootbox.LookAtColor = Color(43, 217, 43)

Lootbox.Distances = 
{
    Start_Raycast = 50,
    Can_Open = 2.25
}
Lootbox.Cell_Size = 256
Lootbox.Scan_Interval = 2000 -- How often the client checks for new cells
Lootbox.Dropbox_Despawn_Time = 60 * 60 * 1000
Lootbox.Loot_Despawn_Time = 10 * 60 * 1000 -- How long it takes for an opened lootbox to despawn
Lootbox.uid = 0

function GetLootboxUID()
    Lootbox.uid = Lootbox.uid + 1
    return Lootbox.uid
end
