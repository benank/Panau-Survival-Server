QuestData = 
{
    [QuestEnum.GettingStartedPart1] = 
    {
        title = "Getting Started (Part 1)",
        enabled = true,
        description = "Welcome to Panau Survival! This quest line will help you get started here and learn the basics of survival. Click \"Start Quest\" to get started.",
        stages = 
        {
            "On Panau Survival, your goal is to survive. You can find gear and food in lootboxes, build bases, defend your base and raid others, and level up to gain new perks. Let's get started.",
            "First, open up your inventory with G.",
            "Great! Your inventory is where you'll keep all the items and gear you acquire on your person. If you die, you'll drop some of it on the ground.",
            "See those boxes in the top right? Those are your stats, like health, hunger, and thirst. Opening your inventory will expand them so you can see the exact amounts.",
            "Now let's equip a gun. Open your inventory again with G and click the Handgun to equip it. You should see a dot on the item if it's equipped.",
            "Next, equip your Grapplehook.",
            "On Panau Survival, you can only use the grapplehook when you have it equipped. Using your grapplehook will decrease its durability; if its durability reaches 0, the grapplehook will break and you'll have to find another one!",
            "Items, such as gear and food, are found in lootboxes. Lootboxes are hidden all around Panau in hidden locations.",
            "You can find loot at the locations that are marked green on the map. Open up the map by pressing F1.",
            "Now that you know where all the loot is, it's just a matter of finding it! There are over 16,000 lootboxes in Panau.",
            "You might have also noticed the blue circle on the map surrounding the city - that's the neutral zone! If you die here, you won't lose any items or experience.",
            "Let's go find some loot! Exit the safezone to get started.",
            "A nearby lootbox has been marked on your screen for you. Find it and loot it! Look at the lootbox until you see a green dot, then press E to open it.",
            "Nice work - you've found your first lootbox! Return to the Quester to complete this quest and receive your reward."
        },
        reward = "30 exploration exp\n30 combat exp\nLockpick (5)"
    },
    [QuestEnum.GettingStartedPart2] = 
    {
        quest_req = QuestEnum.GettingStartedPart1,
        enabled = true,
        title = "Getting Started (Part 2)",
        description = "Welcome to Panau Survival! This quest line will help you get started here and learn the basics of survival. Click \"Start Quest\" to get started.",
        stages = 
        {
            "Let's learn how to drop items on the ground. Dropping items on the ground is a great way to give items to other players or just drop items that you don't want.",
            "Open your inventory and right click on an item, which will turn it red. This means that the item will be dropped if you close your inventory. Right click on it again to cancel dropping.",
            "You can set the amount of items in the stack to drop by scrolling or clicking on the item when it's red. Try to drop just one item out of a stack. (FYI: a stack is a group of more than one item, like 5 Bandages)",
            "Nice work! Now you can pick it up again if you want, or someone else might!",
            "There's a lot more tips and tricks in our Guide - you can open it by pressing Shift + Tab to open up Steam overlay. Then go to Guides -> Panau Survival Guide.",
            "Now back to the game! Get out there and go loot 5 lootboxes. Try looking in telephone booths, under benches, and in corners!",
            "You're well on your way to becoming a master at finding lootboxes. The better you get at finding them, the faster you'll get awesome gear and items! You also gain exploration (blue) experience from them.",
            "While you were looking for lootboxes, you might have seen drones flying around the city. These drones might attack you sometimes!",
            "Destroying drones is a great way to get combat (red) experience and level up. Killing other players also gives combat experience.",
            "Destroy a drone. You can use your Handgun or HE Grenades to do this. To use grenades, equip them then press V to throw.",
            "Return to the Quester to complete this quest and receive your reward."
        },
        reward = "30 exploration exp\n30 combat exp\nHandgun Ammo (50)"
    },
    [QuestEnum.GettingStartedPart3] = 
    {
        quest_req = QuestEnum.GettingStartedPart2,
        enabled = true,
        title = "Getting Started (Part 3)",
        description = "Welcome to Panau Survival! This quest line will help you get started here and learn the basics of survival. Click \"Start Quest\" to get started.",
        stages = 
        {
            "Now you're starting to get the hang of things! Find lootboxes to get gear and earn exploration exp, and kill players and destroy drones for combat exp!",
            "Reach Level 2.",
            "Awesome, you've just gained a level! Gaining new levels gives you perk points, which you can spend in the perk menu.",
            "Open the perk menu with F2.",
            "Here you're able to unlock tons of different perks to upgrade your skills! You can start unlocking skills at Level 3, so keep the perk menu in mind!",
            "Want to change how your character looks? There are model changing areas all around Panau. They look like fire rings.",
            "Step into the model changing area in the safezone.",
            "Travelling on foot is a bit slow, so let's go find a vehicle! To use a vehicle, you'll first have to find one, then unlock it using Lockpicks (lps).",
            "Find a vehicle and unlock it using Lockpicks.",
            "Great! Now you own this car ... that is, unless it gets destroyed or someone steals it!",
            "View all your owned assets, including vehicles, in the Asset Manager menu. Open the Asset Manager menu with F7.",
            "In this menu, you can view your owned vehicles, spawn them (they despawn 5 minutes after logging out), waypoint them, transfer them to another player, or delete them entirely.",
            "If you want to let other players ride with you in your vehicle, you'll need to add them as a friend (and they'll also have to add you).",
            "Open up the Player Menu with F6.",
            "In this menu, you can view all the players currently online. You can also add other players as friends to share vehicles and not be affected by each other's mines and claymores.",
            "Return to the Quester to complete this quest and receive your reward."
        },
        reward = "30 exploration exp\n30 combat exp\n"
    }
}