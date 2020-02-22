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
        [ClimateZone.Arctic] = {hunger = 1.5, thirst = 0.5},
        [ClimateZone.City] = {hunger = 1, thirst = 1},
        [ClimateZone.Default] = {hunger = 1, thirst = 1},
        [ClimateZone.Desert] = {hunger = 0.75, thirst = 2.0},
        [ClimateZone.Grass] = {hunger = 1, thirst = 1.1},
        [ClimateZone.Jungle] = {hunger = 1.1, thirst = 1.15},
        [ClimateZone.None] = {hunger = 1, thirst = 1},
        [ClimateZone.Sea] = {hunger = 1, thirst = 1.2}
    },
    items = 
    {
        ["Apple Juice"] = {hunger = 5, thirst = 10},
        ["Can of Beans"] = {hunger = 20, thirst = 5},
        ["Can of Ham"] = {hunger = 25, thirst = 3},
        ["Can of Peaches"] = {hunger = 15, thirst = 10},
        ["Cookies"] = {hunger = 5, thirst = 0},
        ["Chocolate"] = {hunger = 3, thirst = 0},
        ["Chips"] = {hunger = 15, thirst = -15},
        ["Coffee"] = {hunger = 15, thirst = 3, health = 2},
        ["Energy Drink"] = {hunger = 3, thirst = 8, health = 5},
        ["Iced Tea"] = {hunger = 3, thirst = 12},
        ["Peanuts"] = {hunger = 8, thirst = 0},
        ["Pretzel"] = {hunger = 10, thirst = -2},
        ["Water"] = {hunger = 0, thirst = 16},
        ["CamelBak"] = {hunger = 0, thirst = 12, dura_per_use = 10}
    }
}