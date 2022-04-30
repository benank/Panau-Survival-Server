class 'HelpEntries'

function HelpEntries:__init()
	Events:Subscribe("ModuleLoad", self, self.ModulesLoad)
	Events:Subscribe("ModulesLoad", self, self.ModulesLoad)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
end

function HelpEntries:ModulesLoad()
    Events:Fire("HelpAddItem",
        {
            name = "Welcome",
            text = 
            	"Welcome to Panau Survival!\n\n\n"..
                "The goal is simple - compete and survive. You will first join the server with very few items and you must find other items as you go. Anyone can kill you and you'll drop items upon death. Build a base, raid other players' bases, level up and personalise your character by unlocking perks. There are many paths to success but expect to fail along the way.\n\n\n"..
                "Nothing lasts forever. Items will eventually break and you'll need to find more, landclaims have a limited duration, you must eat/drink to stay alive, anything you place in the world can be destroyed, and your stashes can be hacked if found. The most successful players will have a secure base, safely stored items, and will be very careful about trusting other players. Again, there are no rules against stealing or betraying.\n\n\n"..
                "Good luck! You can learn more about how to play in the other sections on the left.\n\n\n"..
                "You can join our Discord to connect with other players: https://discord.gg/DWGfX3b"
        })
    Events:Fire("HelpAddItem",
        {
            name = "Quick Help",
            text = 
            	"Quick Help\n\n\n"..
                "Where is my grapplehook?\n\tThis is a survival server - you need to find your grapplehooks and parachutes just like all other items in the game. If you have one in your inventory, click it to equip it.\n\n\n"..
                "Where do I find loot?\n\tYou\'ll find lootboxes in locations all over the map. If you're under level 5, lootboxes are marked with YELLOW dots to help you find them. To see exactly which settlements include lootboxes, use the map (F1).\n\n\n"..
                "Where do I find better loot?\n\tIn the 4 city districts where players spawn, there is mostly low level loot. The city is designed as a place to get started and give you the basics, and the best loot is found in other locations in Panau (see Loot section).\n\n\n"..
                "I found a grapplehook. Why can't I use it?\n\tYou need to equip it. Open your inventory (G by default) and click on the grapplehook to equip it. You'll see a green dot next to the grapplehook when it's equipped. Note that your grapplehook (like other items) has a limited durability. As you use it, its durability will decrease until it breaks entirely and you need to find another one. Durability can be viewed from the inventory (see Inventory section).\n\n\n"..
                "Can I trade with other players?\n\tOf course, but be aware that there is no trade system in the server - all trades are trust trades and all prices are determined by players. This is a survival server so be wary of other players. There are no rules against being dishonest or stealing during a trade.\n\n\n"..
                "What are lockpicks?\n\tLockpicks are the server's currency. You can use these to trade for items, and they are also used to unlock and steal vehicles (see Vehicles section).\n\n\n"..
                "Can I build a base?\n\tYes, but first you'll need to claim land using a LandClaim item. LandClaims can be found in Tier 4 lootboxes. Once you claim land, you can place build items, such as walls, doors, beds, and lights inside your claim. Press F7 to manage your claim.\n\n\n"..
                "How do I get a vehicle\n\tVehicles can be found all over the map! If you are under level 5, vehicles are marked with PURPLE dots to help you find them. Once you find a vehicle, you can use Lockpicks to unlock it and claim it for yourself. More information in the Vehicles section.\n\n\n"..
                "Can I suggest changes and report bugs?\n\tPlease do! You can contact us and chat to other players on our Discord server: https://discord.gg/DWGfX3b\n\n"
        })
    Events:Fire("HelpAddItem",
    {
        name = "Beginner Tips",
        text = 
            "Beginner Tips\n\n\n"..
            "\t • Climb towers for rare loot in T4 Boxes\n\n\n"..
            "\t • Loot lockpicks in the small green boxes to buy vehicles\n\n\n"..
            "\t • If you get stuck or want to return to the safezone type /respawn\n\n\n"..
            "\t • Flip a vehicle? Use a woet.\n\n\n"..
            "\t • Need a vehicle quick? Go to the airport and find a cheap motorbike.\n\n\n"..
            "\t • If you're a pilot be careful, sam sites can shoot you down until you loot a sam key.\n\n\n"..
            "\t • If you want to freely fly the skies, destroy and loot a sam key from a sam site.\n\n\n"..
            "\t • Running out of space? Find a stash item in the loot and hide one nearby. You can now drop items into it.\n\n\n"..
            "\t • You can find paint colors to change the paint color of your new vehicle.\n\n\n"..
            "\t • For fast traveling, look for a speedboat around the canals. It is worth the cost.\n\n\n"..
            "\t • In order to build a base you must first find a landclaim item and then walls and a door or two. This lets you build wherever you want!\n\n\n"..
            "\t • There are skin changing locations hidden around the map, find them to unlock your new look!\n\n\n"
    })
    Events:Fire("HelpAddItem",
        {
            name = "Controls",
            text = 
            	"--- CONTROLS --- \n\n"..
                "Q - Melee Attack\n\tAttack nearby players.\n\n"..
                "E - Perform Action\n\tOpen lootbox, enter/exit vehicle, open/close doors, etc.\n\n"..
                "T -  Player Chat\n\tSend messages to other players (see Chat Commands)\n\n"..
                "F - Grapplehook\n\tUse the Grapplehook. Grapplehook must be equipped first.\n\n"..
                "G - Inventory\n\tSee Inventory section for details.\n\n"..
                "C - Weapon Zoom\n\tUse SHIFT and CTRL to zoom in/out.\n\n"..
                "V - Grenade\n\tGrenades must be equipped first. Hold to cook grenade.\n\n"..
                "B - Binoculars\n\tUse left click and right click to zoom in/out.\n\n\n"..
                
                " --- MENUS --- \n\n"..
                "F1 - Map\n\tFind and waypoint locations.\n\n"..
                "F2 - Player Perks\n\tUnlock perks to enhance your character.\n\n"..
                "F3 - Chat\n\tChat to other players publicly and privately (see Chat Commands)\n\n"..
                "F4 - Console\n\tOpen the client console.\n\n"..
                "F5 - Help Window\n\tOpens this help window.\n\n"..
                "F6 - Console\n\tSee who\'s online and add/remove friends\n\n"..
                "F7 - Asset Manager\n\tManage your vehicles, stashes, and LandClaims\n\n"
        })
    Events:Fire("HelpAddItem",
        {
            name = "Chat Commands",
            text = 
                "Chat Commands\n\n"..
                "/w PlayerName Message\n\tWhisper to another player.\n\tExample: /w benank Hello there!\n\n"..
                "/r Message\n\tReply to the last player who whispered to you.\n\tExample: /r On my way!\n\n"..
                "/report Message\n\tReport a player for breaking the rules.\n\tExample: /report benank has just been spamming the chat with vulgar comments.\n\n"..
                "/respawn\n\tTeleport to your respawn point (safezone by default)."
        })
    Events:Fire("HelpAddItem",
        {
            name = "Rules",
            text = 
                "Rules\n\n"..
                "The following rules apply everywhere, including the in-game server and our Discord server. If you break them, you may be banned.\n\n"..
                "1. You may not cheat, exploit, glitch, or bug the servers in any way. If you find a problem, please report it directly to staff and do not repeat it.\n\n"..
                "2. No overly rude, vulgar, racist, homophobic, pornographic, or sexist comments (or anything of the like). We get it; you're competitive, but you don't need to engage in personal attacks.\n\n"..
                "3. No spam.\n\n"..
                "4. Use the designated chat channels for their designated purposes, and try to stay on topic.\n\n"..
                "5. No impersonation.\n\n"..
                "6. No advertising unless given permission from staff.\n\n"..
                "7. English only on Discord. The ingame server uses an automatic translator so you can chat in your own language and it will automatically be translated to others' languages.\n\n"..
                "8. No harassment. If you think something is borderline harassment, don't do it.\n\n"
        })
    Events:Fire("HelpAddItem",
    {
        name = "Safezone",
        text = 
            "Safezone\n\n"..
            "All players start in the safezone - indicated by a yellow dome in the middle of the Financial District. You cannot die in the safezone, even from hunger or thirst. This can be a convenient place to trade with other players.\n\n"..
            "The safezone also contains helpful tips for new players to get started, server stats, and links to our Discord, GitHub and Patreon pages.\n\n\n"..
            "Teleport to Safezone\n\n"..
            "Unless you have placed a bed and set it as your respawn point (see the Building section), you can teleport to the safezone at any time by using the /respawn chat command.\n\n\n"..
            "Player Model Changer\n\n"..
            "The ring of fire inside the safezone is a model changer that allows you to change the look of your character when you stand inside it. There are 9 model changers in total, 4 of which are located in the capital city. Each model changer has unique list of characters."
    })
    Events:Fire("HelpAddItem",
    {
        name = "Inventory",
        text = 
            "Inventory\n\n"..
            "Players have a limited size inventory to store their items - hold G to open it. It's split into four sections:\n"..
            "\t • Weapons - different types of guns\n"..
            "\t • Explosives - includes grenades and airstrikes\n"..
            "\t • Supplies - includes grapplehooks, parachutes and ammunition\n"..
            "\t • Survival - includes food/drinks and armour\n\n\n"..
            "Item Health\n\n"..
            "Some items have a limited durability and will eventually be destroyed. For example, grapplehooks will lose health over time as you use them. Similarly, backpacks will lose health if you take damage whilst wearing them. Items with limited durability will have a coloured bar in their inventory slot. This shows you how much health the item has.\n\n\n"..
            "Equip Items\n\n"..
            "Click an item to equip it. You'll see a white dot on the item when it's equipped. Click again to unequip it.\n\n\n"..
            "Drop Items\n\n"..
            "Open your inventory (G), and right click the item you want to drop. You'll see it turns red. Release G to close your inventory and your dropped item will be placed into a box on the ground that anyone can pick up. It will despawn after 10 minutes. You can drop multiple items at once by right clicking them.\n\n\n"..
            "Drop Partial Items\n\n"..
            "To drop just part of a stack of items, right click on the stack until it turns red, then scroll up/down to select how many you'd like to drop. Close the inventory and you'll drop the number of items you selected.\n\n\n"..
            "Move Items\n\n"..
            "You can organise and move items around your inventory. To do this, drag any slot up or down to swap it with the slot above/below it.\n\n\n"..
            "Death Drops\n\n"..
            "When you are killed, you will drop a certain number of items depending on your level (see Experience & Levels). The higher your level, the more items you'll drop upon death. The items you drop are random - it doesn't matter where they are in your inventory.\n\n"..
            "You don't lose any items for using the /suicide command to teleport to your spawn point (safezone by default).\n\n"..
            "Some items give you extra inventory slots to hold more items. For example, if you equip a Combat Backpack, you will get extra slots for weapons and explosives. If you unequip a backpack whilst you're using the extra slots, you will automatically drop random items until your inventory isn't overflowed. \n\nIf you die, and the backpack happens to be one of the items you lose, you will also drop the items it contained. Extra slots are always added to the top of the inventory - these are the slots you will lose if you lose your backpack.\n\n"
    })
    Events:Fire("HelpAddItem",
    {
        name = "Loot",
        text = 
            "Loot\n\n"..
            "All items on the server, including the grapplehook and parachute, can be found in lootboxes throughout the map. View the map with F1 or check it out below - locations marked in green will contain loot. There are four tiers of lootbox - tier 1 are most common and contain the least valuable loot, and tier 4 lootboxes are rarer and contain much better items.\n\n"..
            "To open a lootbox, stand near it, aim at it until you see a green circle, then press E.\n\n\n"..
            "Tier 1 Loot\n\n"..
            "These lootboxes are very common and contain basic items such as food/drink, lockpicks, and grenades.\n\n\n"..
            "Tier 2 Loot\n\n"..
            "These lootboxes can usually be found near tier 1 loot but they aren't as common. They contain some useful items such as grapplehooks, healthpacks, and stashes (see Stashes section).\n\n\n"..
            "Tier 3 Loot\n\n"..
            "Rarer still, the tier 3 lootboxes are usually found in military bases and are fairly difficult to find. Notable items include armour, backpacks, and claymores.\n\n\n"..
            "Tier 4 Loot\n\n"..
            "Finally, tier 4 lootboxes are very rare and contain some of the best loot in the server. This includes Parachutes, Hackers, and LandClaims (see Building section).\n\n\n"..
            "Vending Machines\n\n"..
            "As you play, your food and water levels will drop. If they become low, you will lose the ability to sprint. If either one reaches zero, you will start to lose health. Food and drink items can be found in level 1 lootboxes, but also in vending machines located across Panau, mostly at gas stations.\n\n"..
            "Orange vending machines contain food items, whereas blue vending machines contain drink items. Open them the same way you would open a lootbox or a stash - approach, aim at it until you see a green circle, then press E. If you don't see a green circle, someone else has emptied that vending machine and it hasn't respawned yet."
    })
    -- Events:Fire("HelpAddItem",
    -- {
    --     name = "Weapons & Armor",
    --     text = 
    --         "Weapons & Armor\n\n"
    -- })
    -- Events:Fire("HelpAddItem",
    -- {
    --     name = "Equipment & Food/Drink",
    --     text = 
    --         "Rules\n\n"
    -- })
    Events:Fire("HelpAddItem",
    {
        name = "Experience & Levels",
        text = 
            "Experience & Levels\n\n"..
            "Progression is a key part of this server. You can earn experience from various activities such as looting, combat, exploration, and raiding. This experience allows you to level up, unlocking new perks and abilities along the way. Some perks are optional and players can choose the perks they prefer and customise their character.\n\n\n"..
            "Stats Box\n\n"..
            "You can view your current progress in the stats box in the top right of the screen. Opening your inventory (G) will expand this box to show more detail. You'll see your player level and two bars. The red bar is combat experience and the blue bar is exploration experience. When the bar is full, you'll level up.\n\n"..
            "The stats box also displays your health and food/water levels - see the Loot section for details.\n\n\n"..
            "Perk Menu\n\n"..
            "When you level up, you will be awarded 2 perk points. These points can be used in the Perk Menu (F2) to unlock new perks. Some perks allow you to access areas of the map, some allow you to use new items, and some give you extra abilities. From the perk menu, the tab at the top shows you how many perk points you have.\n\n"..
            "Perks cost different amounts of points to unlock, and some require you to be a certain player level. Some perks also require other perks to be unlocked first, for example you cannot unlock the +100% grapplehook speed boost until you have unlocked the 75% grapplehook speed boost perk."
    })
    Events:Fire("HelpAddItem",
    {
        name = "Friends",
        text = 
            "Friends\n\n"..
            "You can add any player as a friend by using the Player List (F6).\n\n"..
            "Click Add Friend next to a player's name to send them a friend request. Their name will turn orange to show that your request has been sent. If they accept your request, their name will turn green.\n\n"..
            "To remove a friend, find them in the Player List and click Remove Friend next to their name. Similarly, if a player sends you a friend request, you can accept it from the Player List.\n\n\n"..
            "Minimap\n\n"..
            "Friends will show up as a coloured dot on the minimap in the upper left corner. You will be able to see their nametag from a distance. This displays their name, health and player level.\n\n\n"..
            "Explosives\n\n"..
            "Proximity explosives, such as mines and claymores, will not be triggered if your friends go near them. However if they do explode, your friends can still take damage and may be killed. There are no rules against killing your friends.\n\n\n"..
            "Vehicles\n\n"..
            "Friends are able to enter and drive any of your vehicles.\n\n\n"..
            "Stashes\n\n"..
            "By default, friends cannot access any of your locked stashes, but you can change this setting for each of your stashes in the Asset Manager (see Stashes section). This setting resets every time you remove and replace a locked stash. Other stashes (like barrel and box stashes) cannot be locked and are open to everyone.\n\n\n"..
            "LandClaims\n\n"..
            "By default, friends cannot build in any of your claims, but you can change this setting in the Asset Manager (see Building section). They will only be able to remove their own build items - they can't edit yours. As the owner of the LandClaim, you can delete any build item, even if a friend placed it. Also by default, friends won't be able to open any doors on your base. You can change this setting in the Asset Manager."
    })
    Events:Fire("HelpAddItem",
    {
        name = "Vehicles",
        text = 
            "Vehicles\n\n"..
            "Vehicles can be found all over the map, though they don't spawn in every settlement. By default, these vehicles are locked and you must unlock them with a certain amount of lockpicks (this is the main currency in the server). The vehicle's cost depends upon its rarity and power. Civilian vehicles cost less whilst aircraft and military vehicles cost more.\n\n\n"..
            "Asset Manager\n\n"..
            "The higher level you are, the more vehicles you can own (see Experience & Levels). Once you unlock a vehicle, it will show up in the Asset Manager (F7). From here, you can rename them, waypoint them, spawn them, transfer them to another player, control who can enter them, and delete them. Deleting your vehicle will remove your vehicle forever - it doesn't despawn it and it won't return any lockpicks to you.\n\n\n"..
            "Repairing Vehicles\n\n"..
            "Anyone can damage your vehicle, and the Asset Manager will display the percentage health of each of your vehicles. Provided it is not completely destroyed, you can repair it by using a Vehicle Repair item on it. Stand near your vehicle, aim at it, open your inventory and left click on your Vehicle Repair item. The Vehicle Repair will disappear from your inventory and your vehicle will be restored to full health.\n\n"..
            "You can also repair your vehicle at any Panau gas station. Drive into the station and wait - a message will show you the vehicle health as it slowly increases. You must stay in your vehicle for it to be repaired in this way.\n\n\n"..
            "Despawning Vehicles\n\n"..
            "Whilst the Asset Manager allows you to spawn a vehicle, you cannot despawn it from here. To despawn all your vehicles (so that other players can't damage or steal them) you must log out and wait 5 minutes. When you log back in, you will need to manually spawn your vehicles from the Asset Manager.\n\n\n"..
            "Stealing Vehicles\n\n"..
            "If another player owns a vehicle, you can attempt to steal it. The cost to steal an owned vehicle is double the cost to unlock it.\n\n"..
            "You can use a Vehicle Guard item on your vehicles to protect them from being stolen. If you try to steal a vehicle that has a Vehicle Guard applied to it, you will spend your lockpicks but the vehicle will not become yours. Instead, the Vehicle Guard will be removed from the vehicle and you can try to steal the vehicle again. \n\nNote that players can place up to 5 Vehicle Guards on their vehicle, and only the owner can see how many guards they have applied."
    })
    Events:Fire("HelpAddItem",
    {
        name = "Stashes",
        text = 
            "Stashes\n\n"..
            "To store your items long-term, you'll need a stash. There are different types of stashes and these can be placed in the world for you to place your items inside.\n\n"..
            "Placing your stash inside a glitched location will constitute cheating. Your stash will be deleted, you will lose your items and you may also be banned.\n\n\n"..
            "Garbage Stash and Barrel Stash items are more common and can be opened by anyone. Barrel Stashes have 10 item slots and Garbage Stashes have 12 item slots.\n\n\n"..
            "Locked Stash items are rarer but they can be locked and you can control who can open these stashes - everyone, only your friends, or only you. They have 12 item slots.\n\n\n"..
            "Placing Stashes\n\n"..
            "To place a stash, open your inventory and click on the stash. Then look at where you'd like to place the stash, and click to confirm. You can dismount any of your stashes - this will empty its contents onto the ground and allow you to pick it up again.\n\n\n"..
            "Accessing Stashes\n\n"..
            "Open these stashes the same way you would open a lootbox - stand near it, aim at it until you see a green circle, then press E.\n\n"..
            "To put items in your stash, open your stash and then drop items from your inventory (see Inventory section). Any items you drop whilst your stash is open will be transferred to your stash if there's room.\n\n\n"..
            "Asset Manager\n\n"..
            "Depending on your level, you can own a certain amount of stashes (see Experience & Levels). Once you place a stash, it will show up in the Asset Manager (F7). From here, you can rename it, waypoint it, delete it, control who can open it, and transfer ownership to another player. Deleting your stash will also delete its contents.\n\n\n"..
            "Hacking Stashes\n\n"..
            "You can hack into a stash that belongs to someone else. This is done with the rare Hacker item. Use a Hacker on a locked stash and you will be given a puzzle to solve. Correctly solve the puzzle before time runs out and the stash will be unlocked for everyone to open. Hackers are single-use items - whether you solve the puzzle or not, the Hacker will be lost when you use it on a stash.\n\n\n"..
            "Destroying Stashes\n\n"..
            "You can destroy a stash the same way you destroy any build item - use C4 on it. The amount of C4 required depends on the type of stash you're trying to destroy. Locked Stashes are the strongest and require 4 C4 explosives to destroy. Note that if you destroy a stash, its contents will be destroyed too. You don't get any items from doing this."
    })
    Events:Fire("HelpAddItem",
    {
        name = "Building",
        text = 
            "Building\n\n"..
            "You can build your own bases across the map. This can be a useful way to store your vehicles, store your items, and change your respawn point.\n\n"..
            "To get started, you need an item called a LandClaim. LandClaims can be between 20m and 300m, with the largest claims being the rarest. They are single-use items that allow you to claim ownership over a piece of land on the map - you can then build inside this area. Some areas of the map are locked so you cannot use a LandClaim there.\n\n\n"..
            "Asset Manager\n\n"..
            "Once you place your claim, it will be added to your Claims list in the Asset Manager (F7). From here, you can waypoint it, toggle visibility, rename it, delete it, control who is allowed to build inside it, and transfer ownership to another player.\n\n\n"..
            "LandClaim Expiry\n\n"..
            "LandClaims don't last forever. When you first place a claim, it will have a duration of 60 days - you can view its duration on the Asset Manager (F7). You can extend the duration of any claim by using another LandClaim item whilst you are stood inside it. The number of days you can extend it by depends on the size of the claim.\n\n"..
            "If you wish to extend LandClaim A by using LandClaim B on it, then you will extend its duration by 30*B/A. For example...\n"..
            "\t • If you have a 100m claim and you extend it with a 50m claim, it will be extended by 30 days.\n"..
            "\t • If you have a 50m claim and you extend it with a 100m claim, it will be extended by 120 days.\n\n\n"..
            "Friends' LandClaims\n\n"..
            "If you would like your friends to be able to build in your LandClaim, you can set this up from the Asset Manager (F7). For each claim, you can choose between Only Me, Friends, and Everyone to control who is allowed to build in your claim. You can also set door permissions to control who is allowed to open/close doors in your claim.\n\n"..
            "Friends won't be able to edit/remove your build items - only the items that they place. As the owner of the LandClaim, you can edit and remove any build item inside your claim, even if your friend placed it.\n\n\n"..
            "Changing Respawn Point\n\n"..
            "By default, all players will respawn in the safezone either when they are killed or when the /respawn command is used. To change your respawn point, place a bed, right click it, and click Set Spawn. To reset your respawn point to the Safezone, simply pick up and replace your bed. A message will appear in the chatbox to let you know whenever your respawn point has changed.\n\n\n"..
            "Build Items\n\n"..
            "You can place any build item inside your claim. These items include:\n"..
            "\t • Wall\n"..
            "\t • Door\n"..
            "\t • Helipad\n"..
            "\t • Bed\n"..
            "\t • Light\n"..
            "\t • Sign\n"..
            "\t • Cone\n"..
            "\t • Hedgehog\n"..
            "\t • Stop Sign\n"..
            "\t • Jump Pad\n"..
            "\t • Table\n"..
            "\t • Chair\n"..
            "\t • Umbrella\n"..
            "\t • Potted Plant\n"..
            "\t • Glass\n"..
            "\t • And more!\n\n\n"..
            "Destroying Build Items\n\n"..
            "You can destroy any build item by using C4 on it. C4 is an item you can find in tier 4 lootboxes (see Loot section). The amount of C4 required depends on the item you're trying to destroy. Some items (like walls and doors) can be reinforced and will therefore require even more C4 to destroy."
    })
    Events:Fire("HelpAddItem",
    {
        name = "Drones",
        text = 
            "Drones\n\n"..
            "In some areas of the map, such as the Cities or the desert, you may see drones flying overhead. These drones will sometimes attack you, depending on their level.\n\n"..
            "You can shoot drones or use explosives on them to destroy them. Destroying drones will sometimes yield loot, such as ammo, explosives, or Lock-On Modules.\n\n"..
            "Higher level drones are more dangerous and should be avoided unless you are ready to fight them, but will also give more experience when destroyed."
    })
    Events:Fire("HelpAddItem",
    {
        name = "Workbenches",
        text = 
            "Workbenches\n\n"..
            "Workbenches are indicated with a purple or yellow (if being used) icon on the map. There are two that you can use: one in the city, and one at the Panau Falls Casino.\n\n"..
            "Workbenches allow you to combine the durability of multiple items to get a better item with a very high durability.\n\n"..
            "To use a workbench, open it with E and drop your items in, such as Grapplehooks. This works just like how you would drop itmes into a stash. Then hit Combine and wait until it finishes.\n\n"..
            "Once the combine finishes, you'll have a new item with up to 500% durability. Every combine gives a +20% durability bonus too!\n\n\n"..
            "Combining is great to use on items like Grapplehooks and Walls. When you combine walls, you create a stronger wall, so your base will be harder to break into.\n\n"..
            "Beware, though! When you start combining items, everyone will be able to see it on the map since the icon will turn yellow.\n"
    })
    Events:Fire("HelpAddItem",
    {
        name = "Airdrops",
        text = 
            "Airdrops\n\n"..
            "Airdrops are special server events that can happen when there are two or more players on the server.\n\n"..
            "When an airdrop is triggered, an announcement will appear on Discord and in-game notifying players that there will be an airdrop soon. You will see an icon on the map with the approximate location of the airdrop.\n\n"..
            "When the airdrop lands, you will have to find it and explode the outer doors to get to the loot inside. Sometimes, the loot inside will be locked, so you will need to use a Hacker item to unlock them.\n\n"..
            "Be careful, though! Airdrops can spawn drones and other traps, but have the best loot in the game.\n\n\n"..
            "There are three levels of airdrops, and they each take different amounts of C4 to open:\n"..
            "\t • Level 1 Airdrop: Requires 2 C4\n"..
            "\t • Level 2 Airdrop: Requires 4 C4\n"..
            "\t • Level 3 Airdrop: Requires 6 C4\n\n\n"
    })
    
    Events:Fire("HelpAddItem",
    {
        name = "Secrets",
        text = 
            "Secrets\n\n"..
            "Sometimes on the map, you will see Secrets. Secrets are special lootboxes (they look like Tier 4 lootboxes) that have very rare items inside.\n\n"..
            "However, these lootboxes will be locked and you will need to use a Hacker to unlock them.\n\n"..
            "Secrets disappear after a few days if they are not found."
    })
end

function HelpEntries:ModuleUnload()
    -- Events:Fire("HelpRemoveItem",
    --     {
    --         name = "Welcome"
    --     })
end

HelpEntries()