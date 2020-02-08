config = 
{
    defaults = 
    {
        hunger = 100,
        thirst = 100,
        radiation = 0
    },
    respawn = 
    {
        hunger = 75,
        thirst = 75
    },
    decay = 
    {
        hunger = 0.1,
        thirst = 0.25,
        radiation = 0
    },
    decaymods = 
    {
        [ClimateZone.Arctic] = {hunger = 1.25, thirst = 0.75},
        [ClimateZone.City] = {hunger = 1, thirst = 1},
        [ClimateZone.Default] = {hunger = 1, thirst = 1},
        [ClimateZone.Desert] = {hunger = 1, thirst = 1.5},
        [ClimateZone.Grass] = {hunger = 1, thirst = 1.1},
        [ClimateZone.Jungle] = {hunger = 1.1, thirst = 1.15},
        [ClimateZone.None] = {hunger = 1, thirst = 1},
        [ClimateZone.Sea] = {hunger = 1, thirst = 1.2}
    },
    items = 
    {
        ["Apple"] = {hunger = 15, thirst = 0},
        ["Water Bottle"] = {hunger = 0, thirst = 15},
        ["CamelBak"] = {hunger = 0, thirst = 10, dura_per_use = 10},
        ["Soda"] = {hunger = 0, thirst = 12},
        ["Granola Bar"] = {hunger = 10, thirst = 0},
        ["Trail Mix"] = {hunger = 17, thirst = 0},
        ["Rations"] = {hunger = 20, thirst = 10},
        ["Scrap Metal"] = {hunger = 100, thirst = 100}
    }
}