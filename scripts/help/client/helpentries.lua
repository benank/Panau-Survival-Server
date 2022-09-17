class 'HelpEntries'

function HelpEntries:__init()
    self.locale = LocalPlayer:GetValue("Locale") or 'en'
    self.entries = self:GetLocalizedEntries()
    
    Network:Subscribe("help/LocalizedHelpEntries", self, self.LocalizedHelpEntries)
	Events:Subscribe("ModuleLoad", self, self.ModulesLoad)
	Events:Subscribe("ModulesLoad", self, self.ModulesLoad)
    Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
    Events:Subscribe("NetworkObjectValueChange", self, self.NetworkObjectValueChange)
end

function HelpEntries:LocalizedHelpEntries(args)
    shHelpEntries[args.locale] = args.entries
    self.entries = self:GetLocalizedEntries()
    self:RefreshHelpEntries()
end

function HelpEntries:NetworkObjectValueChange(args)
    if args.object.__type ~= "Player" and args.object.__type ~= "LocalPlayer" then return end
    if args.object ~= LocalPlayer then return end
    if args.key ~= "Locale" then return end
    
    self.locale = args.value
    self.entries = self:GetLocalizedEntries()
    self:RefreshHelpEntries()
end

function HelpEntries:GetLocalizedEntries()
    return shHelpEntries[self.locale] or shHelpEntries['en']
end

function HelpEntries:ModulesLoad()
    self:RefreshHelpEntries()
end

function HelpEntries:RefreshHelpEntries()
    Events:Fire("HelpAddItem",
        {
            internal_name = "Welcome",
            name = self.entries.Welcome.Title,
            text = 
                self.entries.Welcome.Text1 .. "\n\n\n"..
                self.entries.Welcome.Text2 .. "\n\n\n"..
                self.entries.Welcome.Text3 .. "\n\n\n"..
                self.entries.Welcome.Text4 .. "\n\n\n"..
                self.entries.Welcome.Text5 .. ": https://panausurvival.com/discord\n\n\n"..
                self.entries.Welcome.Text6
        })
    Events:Fire("HelpAddItem",
        {
            internal_name = "QuickHelp",
            name = self.entries.QuickHelp.Title,
            text = 
                self.entries.QuickHelp.Text1 .. "\n\n\n"..
                self.entries.QuickHelp.Text2_1 .. "\n\t" .. self.entries.QuickHelp.Text2_2 .. "\n\n\n"..
                self.entries.QuickHelp.Text3_1 .. "\n\t" .. self.entries.QuickHelp.Text3_2 .. "\n\n\n"..
                self.entries.QuickHelp.Text4_1 .. "\n\t" .. self.entries.QuickHelp.Text4_2 .. "\n\n\n"..
                self.entries.QuickHelp.Text5_1 .. "\n\t" .. self.entries.QuickHelp.Text5_2 .. "\n\n\n"..
                self.entries.QuickHelp.Text6_1 .. "\n\t" .. self.entries.QuickHelp.Text6_2 .. "\n\n\n"..
                self.entries.QuickHelp.Text7_1 .. "\n\t" .. self.entries.QuickHelp.Text7_2 .. "\n\n\n"..
                self.entries.QuickHelp.Text8_1 .. "\n\t" .. self.entries.QuickHelp.Text8_2 .. "\n\n\n"..
                self.entries.QuickHelp.Text9_1 .. "\n\t" .. self.entries.QuickHelp.Text9_2 .. ": https://panausurvival.com/discord\n\n"
        })
    Events:Fire("HelpAddItem",
    {
        internal_name = "BeginnerTips",
        name = self.entries.BeginnerTips.Title,
        text = 
            self.entries.BeginnerTips.Text1 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text2 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text3 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text4 .. ": /respawn\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text5 .. "Woet.\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text6 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text7 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text8 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text9 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text10 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text11 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text12 .. "\n\n\n"..
            "\t • " .. self.entries.BeginnerTips.Text13 .."\n\n\n"
    })
    Events:Fire("HelpAddItem",
        {
            internal_name = "Controls",
            name = self.entries.Controls.Title,
            text = 
            	"--- " .. self.entries.Controls.Title .. " --- \n\n"..
                "Q - " .. self.entries.Controls.Text1_1 .. "\n\t" .. self.entries.Controls.Text1_2 .. "\n\n"..
                "E - " .. self.entries.Controls.Text2_1 .. "\n\t" .. self.entries.Controls.Text2_2 .. "\n\n"..
                "T - " .. self.entries.Controls.Text3_1 .. "\n\t" .. self.entries.Controls.Text3_2 .. "\n\n"..
                "F - " .. self.entries.Controls.Text4_1 .. "\n\t" .. self.entries.Controls.Text4_2 .. "\n\n"..
                "G - " .. self.entries.Controls.Text5_1 .. "\n\t" .. self.entries.Controls.Text5_2 .. "\n\n"..
                "C - " .. self.entries.Controls.Text6_1 .. "\n\t" .. self.entries.Controls.Text6_2 .. "\n\n"..
                "V - " .. self.entries.Controls.Text7_1 .. "\n\t" .. self.entries.Controls.Text7_2 .. "\n\n"..
                "B - " .. self.entries.Controls.Text8_1 .. "\n\t" .. self.entries.Controls.Text8_2 .. "\n\n\n"..
                
                " --- " .. self.entries.Controls.Text9 .. " --- \n\n"..
                "F1 - " .. self.entries.Controls.Text10_1 .. "\n\t" .. self.entries.Controls.Text10_2 .. "\n\n"..
                "F2 - " .. self.entries.Controls.Text11_1 .. "\n\t" .. self.entries.Controls.Text11_2 .. "\n\n"..
                "F3 - " .. self.entries.Controls.Text12_1 .. "\n\t" .. self.entries.Controls.Text12_2 .. "\n\n"..
                "F4 - " .. self.entries.Controls.Text13_1 .. "\n\t" .. self.entries.Controls.Text13_2 .. "\n\n"..
                "F5 - " .. self.entries.Controls.Text14_1 .. "\n\t" .. self.entries.Controls.Text14_2 .. "\n\n"..
                "F6 - " .. self.entries.Controls.Text15_1 .. "\n\t" .. self.entries.Controls.Text15_2 .. "\n\n"..
                "F7 - " .. self.entries.Controls.Text16_1 .. "\n\t" .. self.entries.Controls.Text16_2 .. "\n\n"
        })
    Events:Fire("HelpAddItem",
        {
            internal_name = "ChatCommands",
            name = self.entries.ChatCommands.Title,
            text = 
                self.entries.ChatCommands.Title .. "\n\n"..
                "/w PlayerName Message\n\t" .. self.entries.ChatCommands.Text1_1 .. "\n\t" .. self.entries.ChatCommands.Text_Example .. ": /w benank " .. self.entries.ChatCommands.Text1_2 .. "\n\n"..
                "/r Message\n\t" .. self.entries.ChatCommands.Text2_1 .. "\n\t" .. self.entries.ChatCommands.Text_Example .. ": /r " .. self.entries.ChatCommands.Text2_2 .. "\n\n"..
                "/report Message\n\t" .. self.entries.ChatCommands.Text3_1 .. "\n\t" .. self.entries.ChatCommands.Text_Example .. ": /report benank " .. self.entries.ChatCommands.Text3_2 .. "\n\n"..
                "/respawn\n\t" .. self.entries.ChatCommands.Text4_1 .. "\n\n"..
                "/sit\n\t" .. self.entries.ChatCommands.Text5_1 .. "\n\n"..
                "/voice\n\t" .. self.entries.ChatCommands.Text6_1 .. "\n\n"..
                "/language\n\t" .. self.entries.ChatCommands.Text7_1
        })
    Events:Fire("HelpAddItem",
        {
            internal_name = "Rules",
            name = self.entries.Rules.Title,
            text = 
                self.entries.Rules.Title .. "\n\n"..
                self.entries.Rules.Text1 .. "\n\n"..
                "1. " .. self.entries.Rules.Text2 .. "\n\n"..
                "2. " .. self.entries.Rules.Text3 .. "\n\n"..
                "3. " .. self.entries.Rules.Text4 .. "\n\n"..
                "4. " .. self.entries.Rules.Text5 .. "\n\n"..
                "5. " .. self.entries.Rules.Text6 .. "\n\n"..
                "6. " .. self.entries.Rules.Text7 .. "\n\n"..
                "7. " .. self.entries.Rules.Text8 .. "\n\n"..
                "8. " .. self.entries.Rules.Text9 .. "\n\n"
        })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Safezone",
        name = self.entries.Safezone.Title,
        text = 
            self.entries.Safezone.Title .. "\n\n"..
            self.entries.Safezone.Text1 .. "\n\n"..
            self.entries.Safezone.Text2 .. "\n\n\n"..
            self.entries.Safezone.Text3 .. "\n\n"..
            self.entries.Safezone.Text4 .. ": /respawn\n\n\n"..
            self.entries.Safezone.Text5 .. "\n\n"..
            self.entries.Safezone.Text6
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Inventory",
        name = self.entries.Inventory.Title,
        text = 
            self.entries.Inventory.Title .. "\n\n"..
            self.entries.Inventory.Text1 .. ":\n"..
            "\t • Weapons - " .. self.entries.Inventory.Text2 .. "\n"..
            "\t • Explosives - " .. self.entries.Inventory.Text3 .. "\n"..
            "\t • Supplies - " .. self.entries.Inventory.Text4 .. "\n"..
            "\t • Survival - " .. self.entries.Inventory.Text5 .. "\n\n\n"..
            self.entries.Inventory.Text6 .. "\n\n"..
            self.entries.Inventory.Text7 .. "\n\n\n"..
            self.entries.Inventory.Text8 .. "\n\n"..
            self.entries.Inventory.Text9 .. "\n\n\n"..
            self.entries.Inventory.Text10 .. "\n\n"..
            self.entries.Inventory.Text11 .. "\n\n\n"..
            self.entries.Inventory.Text12 .. "\n\n"..
            self.entries.Inventory.Text13 .. "\n\n\n"..
            self.entries.Inventory.Text14 .. "\n\n"..
            self.entries.Inventory.Text15 .. "\n\n\n"..
            self.entries.Inventory.Text16 .. "\n\n"..
            self.entries.Inventory.Text17 .. "\n\n"..
            self.entries.Inventory.Text18 .. ": (/respawn)\n\n"..
            self.entries.Inventory.Text19 .. "\n\n"
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Loot",
        name = self.entries.Loot.Title,
        text = 
            self.entries.Loot.Title .. "\n\n"..
            self.entries.Loot.Text1 .. "\n\n"..
            self.entries.Loot.Text2 .. " E.\n\n\n"..
            self.entries.Loot.Text3 .. " (T1)\n\n"..
            self.entries.Loot.Text4 .. "\n\n\n"..
            self.entries.Loot.Text5 .. " (T2)\n\n"..
            self.entries.Loot.Text6 .. "\n\n\n"..
            self.entries.Loot.Text7 .. " (T3)\n\n"..
            self.entries.Loot.Text8 .. "\n\n\n"..
            self.entries.Loot.Text9 .. " (T4)\n\n"..
            self.entries.Loot.Text10 .. "\n\n\n"..
            self.entries.Loot.Text11 .. "\n\n"..
            self.entries.Loot.Text12 .. "\n\n"..
            self.entries.Loot.Text13
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Exp",
        name = self.entries.Exp.Title,
        text = 
            self.entries.Exp.Title .. "\n\n"..
            self.entries.Exp.Text1 .. "\n\n\n"..
            self.entries.Exp.Text2 .. "\n\n"..
            self.entries.Exp.Text3 .. "\n\n"..
            self.entries.Exp.Text4 .. "\n\n\n"..
            self.entries.Exp.Text5 .. "\n\n"..
            self.entries.Exp.Text6 .. "\n\n"..
            self.entries.Exp.Text7
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Friends",
        name = self.entries.Friends.Title,
        text = 
            self.entries.Friends.Title .. "\n\n"..
            self.entries.Friends.Text1 .. " (F6).\n\n"..
            self.entries.Friends.Text2 .. "\n\n"..
            self.entries.Friends.Text3 .. "\n\n\n"..
            self.entries.Friends.Text4 .. "\n\n"..
            self.entries.Friends.Text5 .. "\n\n\n"..
            self.entries.Friends.Text6 .. "\n\n"..
            self.entries.Friends.Text7 .. "\n\n\n"..
            self.entries.Friends.Text8 .. "\n\n"..
            self.entries.Friends.Text9 .. "\n\n\n"..
            self.entries.Friends.Text10 .. "\n\n"..
            self.entries.Friends.Text11 .. "\n\n\n"..
            self.entries.Friends.Text12 .. "\n\n"..
            self.entries.Friends.Text13 
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Vehicles",
        name = self.entries.Vehicles.Title,
        text = 
            self.entries.Vehicles.Title .. "\n\n"..
            self.entries.Vehicles.Text1 .. "\n\n\n"..
            self.entries.Vehicles.Text2 .. "\n\n"..
            self.entries.Vehicles.Text3 .. "\n\n\n"..
            self.entries.Vehicles.Text4 .. "\n\n"..
            self.entries.Vehicles.Text5 .. "\n\n"..
            self.entries.Vehicles.Text6 .. "\n\n\n"..
            self.entries.Vehicles.Text7 .. "\n\n"..
            self.entries.Vehicles.Text8 .. "\n\n\n"..
            self.entries.Vehicles.Text9 .. "\n\n"..
            self.entries.Vehicles.Text10 .. "\n\n"..
            self.entries.Vehicles.Text11 
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Stashes",
        name = self.entries.Stashes.Title,
        text = 
            self.entries.Stashes.Title .. "\n\n"..
            self.entries.Stashes.Text1 .. "\n\n"..
            self.entries.Stashes.Text2 .. "\n\n\n"..
            self.entries.Stashes.Text3 .. "\n\n\n"..
            self.entries.Stashes.Text4 .. "\n\n\n"..
            self.entries.Stashes.Text5 .. "\n\n"..
            self.entries.Stashes.Text6 .. "\n\n\n"..
            self.entries.Stashes.Text7 .. "\n\n"..
            self.entries.Stashes.Text8 .. "\n\n"..
            self.entries.Stashes.Text9 .. "\n\n\n"..
            self.entries.Stashes.Text10 .. "\n\n"..
            self.entries.Stashes.Text11 .. "\n\n\n"..
            self.entries.Stashes.Text12 .. "\n\n"..
            self.entries.Stashes.Text13 .. "\n\n\n"..
            self.entries.Stashes.Text14 .. "\n\n"..
            self.entries.Stashes.Text15
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Building",
        name = self.entries.Building.Title,
        text = 
            self.entries.Building.Title .. "\n\n"..
            self.entries.Building.Text1 .. "\n\n"..
            self.entries.Building.Text2 .. "\n\n\n"..
            self.entries.Building.Text3 .. "\n\n"..
            self.entries.Building.Text4 .. "\n\n\n"..
            self.entries.Building.Text5 .. "\n\n"..
            self.entries.Building.Text6 .. "\n\n"..
            self.entries.Building.Text7 .. "\n"..
            "\t • " .. self.entries.Building.Text8 .. "\n"..
            "\t • " .. self.entries.Building.Text9 .. "\n\n\n"..
            self.entries.Building.Text10 .. "\n\n"..
            self.entries.Building.Text11 .. "\n\n"..
            self.entries.Building.Text12 .. "\n\n\n"..
            self.entries.Building.Text13 .. "\n\n"..
            self.entries.Building.Text14 .. "\n\n\n"..
            self.entries.Building.Text15 .. "\n\n"..
            self.entries.Building.Text16 .. ":\n"..
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
            "\t • " .. self.entries.Building.Text17 .. "!\n\n\n"..
            self.entries.Building.Text18 .. "\n\n"..
            self.entries.Building.Text19 
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Drones",
        name = self.entries.Drones.Title,
        text = 
            self.entries.Drones.Title .. "\n\n"..
            self.entries.Drones.Text1 .. "\n\n"..
            self.entries.Drones.Text2 .. "\n\n"..
            self.entries.Drones.Text3
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Workbenches",
        name = self.entries.Workbenches.Title,
        text = 
            self.entries.Workbenches.Title .. "\n\n"..
            self.entries.Workbenches.Text1 .. "\n\n"..
            self.entries.Workbenches.Text2 .. "\n\n"..
            self.entries.Workbenches.Text3 .. "\n\n"..
            self.entries.Workbenches.Text4 .. "\n\n\n"..
            self.entries.Workbenches.Text5 .. "\n\n"..
            self.entries.Workbenches.Text6 .. "\n"
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Airdrops",
        name = self.entries.Airdrops.Title,
        text = 
            self.entries.Airdrops.Title .. "\n\n"..
            self.entries.Airdrops.Text1 .. "\n\n"..
            self.entries.Airdrops.Text2 .. "\n\n"..
            self.entries.Airdrops.Text3 .. "\n\n"..
            self.entries.Airdrops.Text4 .. "\n\n\n"..
            self.entries.Airdrops.Text5 .. ":\n"..
            "\t • " .. self.entries.Airdrops.Text6 .. "\n"..
            "\t • " .. self.entries.Airdrops.Text7 .. "\n"..
            "\t • " .. self.entries.Airdrops.Text8 .. "\n\n\n"
    })
    
    Events:Fire("HelpAddItem",
    {
        internal_name = "SamSites",
        name = self.entries.SamSites.Title,
        text = 
            self.entries.SamSites.Title .. "\n\n"..
            self.entries.SamSites.Text1 .. "\n\n"..
            self.entries.SamSites.Text2 .. "\n\n"..
            self.entries.SamSites.Text3 .. ":\n"..
            "\t • " .. self.entries.SamSites.Text4 .. "\n"..
            "\t • " .. self.entries.SamSites.Text5 .. "\n\n\n"..
            "SAM Key\n"..
            self.entries.SamSites.Text6
    })
    Events:Fire("HelpAddItem",
    {
        internal_name = "Secrets",
        name = self.entries.Secrets.Title,
        text = 
            self.entries.Secrets.Title .. "\n\n"..
            self.entries.Secrets.Text1 .. "\n\n"..
            self.entries.Secrets.Text2 .. "\n\n"..
            self.entries.Secrets.Text3
    })
end

function HelpEntries:ModuleUnload()
    -- Events:Fire("HelpRemoveItem",
    --     {
    --         name = "Welcome"
    --     })
end

HelpEntries()